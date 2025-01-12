# Introduction
This is a simple script to check whether there are any unsed headers in C code file.

# Demonstrate
![Linux driver code](https://vhs.charm.sh/vhs-2dICsKypiMC7hq5DtIdcDr.gif)
![Test project](https://vhs.charm.sh/vhs-3rtDMySKMFhZ5EtbQQPKNM.gif)

# Install
``` bash
git clone https://github.com/Kingxukai/check-unused-headers.git
```

# Usage
``` bash
$ cuh --help
```
1. First method
``` bash
$ which python3
/path/to/python3
```
> use this path in the script first line
> and then
``` bash
$ ./cuh file.c
or
$ mkdir -p /usr/local/script
$ cp cuh /usr/local/script/
$ export PATH=/usr/local/script/:$PATH
$ cuh file.c
```

2. Second method
``` bash
python3 ./cuh file.c
```

# Current Problem
This tool cannot detect structures defined like this:
``` c
/* headers.h */
struct values {
	int a;
	int b;
};
```

Instead, it incorrectly detects the following:
``` python
{'struct values;', 'int a;', 'int b;' }
```

If you encounter any other issues, feel free to open an issue!

# Compare to include-what-you-use
This tool is simpler but less stable<br>
[include-what-you-use](https://github.com/include-what-you-use/include-what-you-use)<br>
![include-what-you-use](https://vhs.charm.sh/vhs-3T3xLg3HnhjvlV2xw7Kyzb.gif)

