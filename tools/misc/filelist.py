#!/usr/bin/env python
#
# Copyright (C) 2015 The Yudatun Open Source Project
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 2 as
# published by the Free Software Foundation
#

import os
import sys
import operator

def get_file_size(path):
  st = os.lstat(path)
  return st.st_size

def main(argv):
  output = []
  roots = argv[1:]

  for root in roots:
    base = len(root[:root.rfind(os.path.sep)])
    for dir, dirs, files in os.walk(root):
      relative = dir[base:]
      for f in files:
        try:
          row = (
              get_file_size(os.path.sep.join((dir, f))),
              os.path.sep.join((relative, f)),
          )
          output.append(row)
        except os.error:
          pass
  output.sort(key=operator.itemgetter(0), reverse=True)
  for row in output:
    print "%12d %s" % row

if __name__ == '__main__':
  main(sys.argv)
