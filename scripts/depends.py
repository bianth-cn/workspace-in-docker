#!/usr/bin/env python
# -*- coding: utf-8 -*-

# Author        : Tony Bian <biantonghe@gmail.com>
# Last Modified : 2018-12-25 05:21
# Filename      : depends.py

import json
import sys

pkg = sys.argv[1]

data = json.load(sys.stdin)

pkg_dependencies = set([pkg])
other_dependencies = set()
pkg_parents = set()

protect_pkgs = set(['pip', 'setuptools', 'wheel'])


def get_pkg_depends_on(pkg, data):
    for pkg_info in data:
        if pkg_info['package']['key'] == pkg:
            for depend_pkg_info in pkg_info['dependencies']:
                depend_pkg = depend_pkg_info['key']
                pkg_dependencies.add(depend_pkg)
                get_pkg_depends_on(depend_pkg, data)
    return pkg_dependencies


def get_pkg_depends_by(child_pkg, data):
    for pkg_info in data:
        for child_pkg_info in pkg_info['dependencies']:
            if child_pkg == child_pkg_info['key']:
                parent_pkg = pkg_info['package']['key']
                pkg_parents.add(parent_pkg)
                get_pkg_depends_by(parent_pkg, data)
    return pkg_parents


def get_other_depends(pkg_depends, data):
    for pkg_info in data:
        if pkg_info['package']['key'] not in pkg_depends:
            for depend_pkg_info in pkg_info['dependencies']:
                depend_pkg = depend_pkg_info['key']
                other_dependencies.add(depend_pkg)
    return other_dependencies


pkg_dependencies = get_pkg_depends_on(pkg, data)
other_dependencies = get_other_depends(pkg_dependencies, data)
pkg_parents = get_pkg_depends_by(pkg, data)

if pkg_parents:
    print(pkg_parents)
else:
    pkgs = ' '.join(pkg_dependencies - other_dependencies - protect_pkgs)
    print(pkgs)
