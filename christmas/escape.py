#!/usr/bin/env python3

import sys

with open(sys.argv[1]) as f:
    while True:
        x = f.readline()
        x = x.replace("\\", "\\\\")
        x = x.replace("\"", "\\\"")
        if not x:
            break
        print(".ascii \"" + x.rstrip("\n\r") + "\\n\\r\"")

