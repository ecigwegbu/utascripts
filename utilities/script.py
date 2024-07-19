#!/usr/bin/env python3

import sys

# This script inspects the Python version and issues a notice
# according to its findings.

expected_version = "3.8"

# Get the current Python version
python_version = f"{sys.version_info.major}.{sys.version_info.minor}.{sys.version_info.micro}"

if python_version.startswith(expected_version):
    print(f"This script was correctly run on Python {expected_version}")
else:
    print("This script was not run on the correct version of Python")
    print(f"Expected version of Python is {expected_version}")
    print(f"Current version of Python is Python {python_version}")

