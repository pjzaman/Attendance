"""PyInstaller entry point.

Importing the bridge package as a normal package keeps the relative
imports inside `bridge.main` working, both when running from source
(`python run.py`) and from a frozen exe.
"""

import sys

from bridge.main import main

if __name__ == "__main__":
    sys.exit(main())
