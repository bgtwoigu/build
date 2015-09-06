#!/usr/bin/env python
#
# Copyright (C) 2015 The Yudatun Open Source Project
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 2 as
# published by the Free Software Foundation
#

import sys
import re

from types import *

class Bug(object):

  def blue(self, msg):
    print "\033[1;34m%s\033[0m" % msg

  def green(self, msg):
    print "\033[1;32m%s\033[0m" % msg

  def ok(self, msg):
    self.green(msg)

  def info(self, msg):
    print "\033[1;31m"
    print "INFO: %s" % msg
    print "\033[0m"

  def warn(self, msg):
    print "\033[1;31m"
    print "WARNING: %s" % msg
    print "\033[0m"
    sys.exit(1)

  def error(self, msg):
    print "\033[1;31m"
    print "ERROR: %s" % msg
    print "\033[0m"
    sys.exit(1)

BUG = Bug()

########################################

BYTES_PER_SECTOR = 512

def str2bool(s):
  return s.lower() in ("True", "true")

def kb2sectors(kb):
  return int(kb * 1024 / BYTES_PER_SECTOR)

########################################

class Instructions(object):

  def __init__(self):
    self.WRITE_PROTECT_BOUNDARY_IN_KB = 65536  # 64 * 1024
    self.WRITE_PROTECT_GPT_PARTITION_TABLE = False

    self.SECTOR_SIZE_IN_BYTES = 512

    self.PERFORMANCE_BOUNDARY_IN_KB = 0
    self.ALIGN_PERFORMANCE_BOUNDARY_IN_KB = False

    self.GROW_LAST_PARTITION_TO_FILL_DISK = False
    self.USE_GPT_PARTITIONING = False
    self.DISK_SIGNATURE = 0x00000000
    self.ALIGN_BOUNDARY_IN_KB = self.WRITE_PROTECT_BOUNDARY_IN_KB

  def align_to_pb(self):
    if self.PERFORMANCE_BOUNDARY_IN_KB > 0 and \
       self.ALIGN_PERFORMANCE_BOUNDARY_IN_KB is True:
      return True
    return False

  def trim_spaces(self, text):
    # Trim the left of '=' spaces
    tmp = re.sub(r"(\t| )+=", "=", text)
    # Trim the right of '=' spaces
    tmp = re.sub(r"=(\t| )+", "=", tmp)
    return tmp

  def text2list(self, text):
    tmp = re.sub(r"\s+|\n", " ", text)  # Trim '\n'
    tmp = re.sub(r"^\s+", "", tmp)      # Trim '\t\n\r\f\v'
    tmp = re.sub(r"\s+$", "", tmp)
    return tmp.split(' ')

  def text2expr(self, text):
    _list = self.text2list(self.trim_spaces(text))
    for l in _list:
      tmp = l.split('=')
      if len(tmp) == 2:
        key   = tmp[0].strip()
        value = tmp[1].strip()
        if key == 'WRITE_PROTECT_BOUNDARY_IN_KB':
          if str.isdigit(value):
            self.WRITE_PROTECT_BOUNDARY_IN_KB = int(value)
        elif key == 'WRITE_PROTECT_GPT_PARTITION_TABLE':
          self.WRITE_PROTECT_GPT_PARTITION_TABLE = str2bool(value)
        elif key == 'SECTOR_SIZE_IN_BYTES':
          if str.isdigit(value):
            self.SECTOR_SIZE_IN_BYTES = int(value)
            BYTES_PER_SECTOR = self.SECTOR_SIZE_IN_BYTES
        elif key == 'PERFORMANCE_BOUNDARY_IN_KB':
          if str.isdigit(value):
            self.PERFORMANCE_BOUNDARY_IN_KB = int(value)
        elif key == 'ALIGN_PERFORMANCE_BOUNDARY_IN_KB':
          self.ALIGN_PERFORMANCE_BOUNDARY_IN_KB = str2bool(value)
        elif key == 'GROW_LAST_PARTITION_TO_FILL_DISK':
          self.GROW_LAST_PARTITION_TO_FILL_DISK = str2bool(value)
        elif key == 'USE_GPT_PARTITIONING':
          self.USE_GPT_PARTITIONING = str2bool(value)
        elif key == 'DISK_SIGNATURE':
          if str.isdigit(value):
            self.DISK_SIGNATURE = int(value, 16)
        else:
          BUG.warn("Invalidate key (%s)" % key)
      else:
        BUG.warn("Invalidate expression (%s)" % l)

  def check_validate(self):
    if self.align_to_pb() is False and \
       (self.PERFORMANCE_BOUNDARY_IN_KB > 0 or \
        self.ALIGN_PERFORMANCE_BOUNDARY_IN_KB is True):
      BUG.warn("The PERFORMANCE_BOUNDARY_IN_KB %i KB, But " \
               "ALIGN_PERFORMANCE_BOUNDARY_IN_KB is (%s)." \
               % (self.PERFORMANCE_BOUNDARY_IN_KB, \
                  str(self.ALIGN_PERFORMANCE_BOUNDARY_IN_KB)))

INSTRUCTIONS = Instructions()

########################################

class WriteProtectPartition(object):

  def __init__(self):
    self.reset()

  def set(self, start, end, num_sectors, \
          ph_part_num, bd_num, num_bd_covered):
    self.start_sector = start
    self.end_sector   = end
    self.num_sectors  = num_sectors
    self.phsical_partition_num  = ph_part_num
    self.boundary_num           = bd_num
    self.num_boundaries_covered = num_bd_covered

  def reset(self):
    self.set(0, 0, 0, 0, 0, 0)

  def update(self, start, sectors, wp_in_sectors):
    if wp_in_sectors <= 0:
      return

    self.boundary_num = start / wp_in_sectors
    end_sector = start + sectors - 1
    while end_sector > self.end_sector:
      self.end_sector  += wp_in_sectors
      self.num_sectors += wp_in_sectors
      self.num_boundaries_covered = self.num_sectors / wp_in_sectors

########################################

class Partitions(object):

  GPT_TYPE = "gpt"
  MBR_TYPE = "mbr"

  def __init__(self):
    self._type              = None
    self.part_list          = []
    self.wp_part_list       = []
    self.current_wp_part    = -1
    self.min_sectors_needed = 0

  def add_part(self, part):
    self.part_list.append(part)

  def add_wp_part(self, wp_part):
    self.wp_part_list.append(wp_part)
    self.current_wp_part += 1

  def update_wp_part(self, start, sectors, wp_in_sectors):
    if wp_in_sectors <= 0:
      return

    if self.current_wp_part < 0:
      wp_part = WriteProtectPartition()
      wp_part.update(start, sectors, wp_in_sectors)
      self.add_wp_part(wp_part)
      return

    start_sector = start - 1
    current_wp_part = self.wp_part_list[self.current_wp_part]
    if start_sector <= current_wp_part.end_sector:
      current_wp_part.update(start, sectors, wp_in_sectors)
    else:
      wp_part = WriteProtectPartition()
      wp_part.update(start, sectors, wp_in_sectors)
      self.add_wp_part(wp_part)

  def count_min_sectors_needed(self):
    # To be here means we're not growing final partition.
    # thereore, obey the sizes they've specified.
    num_part = len(self.part_list)
    if num_part > 4:
      # MBR + num_part - 3(EBRs)
      self.min_sectors_needed = 1 + (num_part - 3)
    else:
      self.min_sectors_needed = 1
    for part in self.part_list:
      print "label (%s) with (%d) sectors" % (part.label, part.size)
      self.min_sectors_needed += part.size

PARTITIONS = Partitions()

########################################

class Partition(object):

  GUID_RE_1 = "0x([a-fA-F\d]{32})"
  GUID_RE_2 = "([a-fA-F\d]{8})-([a-fA-F\d]{4})-"                \
              "([a-fA-F\d]{4})-([a-fA-F\d]{2})([a-fA-F\d]{2})-" \
              "([a-fA-F\d]{2})([a-fA-F\d]{2})([a-fA-F\d]{2})"   \
              "([a-fA-F\d]{2})([a-fA-F\d]{2})([a-fA-F\d]{2})"

  TYPE_RE   = "^(0x)?([a-fA-F\d][a-fA-F\d]?)$"

  PARTITION_BASIC_DATA_GUID = 0xC79926B7B668C0874433B9E5EBD0A0A2

  def __init__(self):
    self.filename    = ""
    self.sparse      = ""

    self.bootable   = False
    self.label      = ""
    self.size_in_kb = 0  # KB
    self.size       = 0  # sector
    self._type      = ""
    self.uniqueguid = ""
    # Attributes
    self.readonly      = False
    self.hidden        = False
    self.dontautomount = False
    self.system        = False

  def is_validate_GUID(self, GUID):
    if type(GUID) is not str:
      GUID = str(GUID)

    m = re.search(self.GUID_RE_1, GUID)
    if (type(m) is not NoneType) and (len(GUID) == 32):
      return True
    m = re.search(self.GUID_RE_2, GUID)
    if (type(m) is not NoneType) and (len(GUID) == 36):
      return True

    return False

  def is_validate_TYPE(self, TYPE):
    if type(TYPE) is int:
      if TYPE >= 0 and TYPE <= 255:
        return True

    if type(TYPE) is not str:
      TYPE = str(TYPE)

    m = re.search(self.TYPE_RE, TYPE)
    if type(m) is not NoneType:
      return True

    return False

  def validate_GUID(self, GUID):
    if type(GUID) is not str:
      GUID = str(GUID)

    m = re.search(self.GUID_RE_1, GUID)
    if type(m) is not NoneType:
      tmp = int(m.group(1), 16)
      return tmp

    m = re.search(self.GUID_RE_2, GUID)
    if type(m) is not NoneType:
      tmp  = int(m.group(4),  16) << 64
      tmp |= int(m.group(3),  16) << 48
      tmp |= int(m.group(2),  16) << 32
      tmp |= int(m.group(1),  16)

      tmp |= int(m.group(8),  16) << 96
      tmp |= int(m.group(7),  16) << 88
      tmp |= int(m.group(6),  16) << 80
      tmp |= int(m.group(5),  16) << 72

      tmp |= int(m.group(11), 16) << 120
      tmp |= int(m.group(10), 16) << 112
      tmp |= int(m.group(9),  16) << 104
      return tmp
    else:
      return self.PARTITION_BASIC_DATA_GUID

  def validate_TYPE(self, TYPE):
    if type(TYPE) is int:
      if TYPE >= 0 and TYPE <= 255:
        return TYPE

    if type(TYPE) is not str:
      TYPE = str(TYPE)

    m = re.search(self.TYPE_RE, TYPE)
    if type(m) is not NoneType:
      return int(m.group(2), 16)

    BUG.warn("type (%s) is not in the form 0x##." % TYPE)

  def items2expr(self, items):
    for key, value in items:
      if key == 'filename':
        self.filename = value
      elif key == 'sparse':
        self.sparse = value
      elif key == 'bootable':
        self.bootable = str2bool(value)
      elif key == 'label':
        self.label = value
      elif key == 'size_in_kb':
        if str.isdigit(value):
          self.size_in_kb = int(value)
        else:
          BUG.warn("Invalidate value (%s) for key (%s)" % (value, key))
      elif key == 'type':
        if self.is_validate_GUID(value) is True:
          self.is_gpt = True
          self._type = self.validate_GUID(value)
        elif self.is_validate_TYPE(value) is True:
          self.is_mbr = True
          self._type = self.validate_TYPE(value)
        else:
          BUG.warn("Invalidate type (%s)." % value)
      elif key == 'uniqueguid':
        self.uniqueguid = value
      elif key == 'readonly':
        self.readonly = str2bool(value)
      elif key == 'hidden':
        self.hidden = str2bool(value)
      elif key == 'dontautomount':
        self.dontautomount = str2bool(value)
      elif key == 'system':
        self.system = str2bool(value)
      else:
        BUG.warn("Invalidate key (%s)." % key)

    self.size = kb2sectors(self.size_in_kb)
