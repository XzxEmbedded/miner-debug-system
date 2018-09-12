#!/usr/bin/env python

from distutils.core import setup
import py2exe

includes = ["encodings", "encodings.*"]

options = {
    "py2exe":
    {
        "compressed": 1,
        "optimize": 2,
        "includes": includes,
        "bundle_files": 1
    }
}


setup(
    version = "V0.1",
    description = "Windows Program",
    name = "winsetup",
    options = options,
    zipfile = None,
    windows = [{"script": "set-device-id.py", "icon_resources": [(1, "PyCrust.ico")] }],
)
