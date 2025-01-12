# Introduction
This is a simple script to check whether there are any unsed headers in C code file.

# Demonstrate
![Linux driver code](https://vhs.charm.sh/vhs-2dICsKypiMC7hq5DtIdcDr.gif)
![Test project](https://vhs.charm.sh/vhs-3rtDMySKMFhZ5EtbQQPKNM.gif)

# Install
``` bash
git clone https://github.com/Kingxukai/check_unused_headers.git
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

2. Seconf method
``` bash
python3 cuh file.c
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
