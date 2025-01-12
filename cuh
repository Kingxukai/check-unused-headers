#!/usr/bin/env python3
import subprocess
import re
import sys
import os

debug = False
prefix = ""

def read_valid_content(f):
    content = f.read()
    # 去除多行注释 (/* ... */)
    content = re.sub(r'/\*.*?\*/', '', content, flags=re.DOTALL)
    # 去除单行注释 (// ...)
    content = re.sub(r'//.*$', '', content, flags=re.MULTILINE)
    return content

def extract_includes(c_file):
    try:
        with open(c_file, 'r') as f:
            content = read_valid_content(f)

            if debug:
                print("source file content:")
                print(content)
                print("-" * 50)

            includes = set()
            # 使用正则表达式匹配所有的 #include 语句

            include_pattern = r'#include\s+([\"<])(.*?)([\">])'
            for match in re.finditer(include_pattern, content):
                delimiter_start = match.group(1)  # 获取开头符号（双引号或尖括号）
                include_path = match.group(2)    # 获取文件路径
                delimiter_end = match.group(3)   # 获取结尾符号（双引号或尖括号）
                if delimiter_start == '<' and delimiter_end == '>' and prefix:
                    # 如果是 <header> 格式，添加前缀
                    include_path = f"{prefix}/{include_path}"
                includes.add(include_path)

            if debug:
                print("header file path:")
                print(includes)
                print("-" * 50)
            return includes
    except FileNotFoundError:
        print(f"Error: Source file {c_file} not found.")
        return set()

def extract_function_call(pattern):
    # 匹配类似 void hello(); 或 int test(a, b); 的模式，提取函数名
    match = re.match(r'\b(?:extern\s+)?(?:void|int|char|float|double|struct\s+\w+|[\w:]+\s+\w+)\s+(\w+)\s*\([^)]*\)\s*;', pattern)
    if match:
        return match.group(1)  # 返回函数名
    return None

def read_content(header_file):
    functions = set()
    macros = set()
    variables = set()

    try:
        with open(header_file, 'r') as f:
            content = read_valid_content(f)
            if debug:
                print(f"header file {header_file} content:")
                print("~ -" * 25)
                print(content)
                print("~ -" * 25)
                print("-" * 50)

            func_pattern = re.compile(r'\b(?:void|int|char|float|double|struct\s+\w+|[\w:]+\s+\w+)\s+\w+\s*\([^)]*\)\s*;')
            functions.update((func_pattern.findall(content)))

            if debug:
                print("collection:")
                print("-" * 50)

            if debug and functions:
                print("functions:")
                print(functions)
                print("-" * 50)

            macro_pattern = re.compile(r'#define\s+([a-zA-Z_][a-zA-Z0-9_]*)\s*(?:\((.*?)\))?\s*(.*)')
            for match in macro_pattern.findall(content):
                macro_name = match[0]
                macros.add(macro_name)

            if debug and macros:
                print("macros:")
                print(macros)
                print("-" * 50)

            var_pattern = re.compile(r'\b(?:int|float|double|char|long|short)\s+[\w*]+(?:\s*,\s*[\w*]+)*\s*;')
            variables.update(var_pattern.findall(content))
            struct_pattern = r'\bstruct\s+\w+\s*\{[^\}]*\};'
            matches = re.findall(struct_pattern, content, re.DOTALL)
            for match in matches:
                struct_declaration = re.sub(r'\s*\{[^\}]*\}\s*', '', match).strip()
                variables.add(struct_declaration)

            if debug and variables:
                print("variables:")
                print(variables)
                print("-" * 50)

            return functions, macros, variables
                
    except FileNotFoundError:
        print(f"Error: Header file {header_file} not found.")
        return set(), set(), set()

def extract_variables(declaration):
    pattern = r'\s([a-zA-Z_][a-zA-Z0-9_]*)\s*;'
    return re.findall(pattern, declaration)

def compare_content(functions, macros, variables, source_content):
    order = 0
    for func in functions:
        func_name = extract_function_call(func)
        if func_name:
            pattern = r'\b' + re.escape(func_name) + r'\s*\([^)]*\)\s*;'
        else:
            pattern = r''

        if debug and func_name:
            print(f"function pattern{order}:")
            print(pattern)
            order += 1

        if re.search(pattern, source_content):
            if debug:
                print(f"function: {pattern} was found")
                print("-" * 50)
            return True

    order = 0
    for macro in macros:
        if macro:
            pattern_no_params = r'\b' + re.escape(macro) + r'\s*(?:[^\w]*\w*)*\s*;\s*'
            pattern_with_params = r'\b' + re.escape(macro) + r'\s*\([^)]*\)\s*;?'
                                                                        
        else:
            pattern_no_params = r''
            pattern_with_params = r''

        if debug and macro:
            print(f"macro pattern{order}:")
            print(pattern_no_params)
            print(pattern_with_params)
            order += 1

        if re.search(pattern_no_params, source_content) or re.search(pattern_with_params, source_content):
            if debug:
                print(f"macro: {pattern_no_params} was found or {pattern_with_params} was found")
                print("-" * 50)

            return True

    order = 0
    for var in variables:
        var_names = extract_variables(var)

        if debug:
            print(f"variable pattern{order}:")

        for var_name in var_names:
                pattern = r'\b' + re.escape(var_name) + r'\b'
                if debug:
                    print(pattern)
                    order += 1

        if re.search(pattern, source_content):
            if debug:
                print(f"variable: {pattern} was found")
                print("-" * 50)
            return True
                                
    return False


def find_unused_headers(c_file, includes):
    """查找哪些头文件没有在 C 文件中使用"""
    unused_headers = set(includes)  # 初始时，所有头文件都是未使用的
    try:
        with open(c_file, 'r') as f:
            source_content = read_valid_content(f)
            for header in includes:
                functions, macros, variables = read_content(header)

                flag = compare_content(functions, macros, variables, source_content)
                if flag:
                    unused_headers.discard(header)
    except FileNotFoundError:
        print(f"File {c_file} not found.")
        return set()
    return unused_headers

def main(c_file):
    if not os.path.isfile(c_file):
        print(f"Error: The file {c_file} does not exist.")
        return

    print(f"Checking unused headers in {c_file}...")

    includes = extract_includes(c_file)
    unused_headers = find_unused_headers(c_file, includes)
    
    if unused_headers:
        print("Unused headers:")
        for header in unused_headers:
            print(f"  {header}")
    else:
        print("No unused headers found.")

if __name__ == "__main__":
    # 获取命令行参数
    if len(sys.argv) < 2:
        print("Usage: cuh <C file> [--debug] [-I<include path>] [--help | -h]")
        sys.exit(1)

    for arg in sys.argv[1:]:
        if "--debug" in arg:
            debug = True
        elif arg.startswith("-I"):
            # 解析 -I 后面的路径部分
            prefix = arg[2:]  # 提取 -I 后面的路径部分
        elif ("--help" in arg) or ("-h" in arg):
            print("Usage: cuh <C file> [--debug] [-I<include path>] [--help | -h]")
            print("\nFeel free to contact with author if there is any problem!")
            print("Author: Xukai Wang<kingxukai@zohomail.com>")
            sys.exit(0)

    if debug:
        print("-" * 50)
        print("Debug mode enable")
    if prefix:
        print("-" * 50)
        print(f"prefix: {prefix}")
        print("-" * 50)

    # 获取文件路径
    c_file = sys.argv[1]
    
    # 调用主函数
    main(c_file)

