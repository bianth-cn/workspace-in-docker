#!/usr/bin/env python
# -*- coding: utf-8 -*-

# Author        : Tony Bian <biantonghe@gmail.com>
# Last Modified : 2020-04-19 12:44
# Filename      : eval_str.py


def eval_str(data):
    r_data = eval(data)
    return r_data


class FilterModule(object):
    filter_map = {'eval_str': eval_str}

    def filters(self):
        return self.filter_map
