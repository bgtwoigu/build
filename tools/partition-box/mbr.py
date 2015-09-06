#!/usr/bin/env python
#
# Copyright (C) 2015 The Yudatun Open Source Project
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 2 as
# published by the Free Software Foundation
#

import sys

import pt

BUG = pt.BUG

BYTES_PER_SECTOR = pt.BYTES_PER_SECTOR

class MBRPartitionTable(object):

  MAGIC_0 = 0x55
  MAGIC_1 = 0xAA

  def __init__(self):
    self.code_addr      = 0x0
    self.signature_addr = 0x1B8  # 440
    self.reserve_addr   = 0x1BC  # 444
    self.pt_addr        = 0x1BE  # 446
    self.magic_0_addr   = 0x1FE  # 510
    self.magic_1_addr   = 0x1FF  # 511

    self.code      = None
    self.signature = None
    self.reserve   = None
    self.pt        = None
    self.magic_0   = self.MAGIC_0
    self.magic_1   = self.MAGIC_1

    self.array = [0] * BYTES_PER_SECTOR

  def set(self, code, signature, reserve, pt, magic_0, magic_1):

    if code is not None:
      if len(code) > 0 and len(code) <= 440:
        self.code = []
        for b in code:
          self.code.append(b)
      else:
        BUG.error("Invalidate codes (%d)." % len(code))

    self.signature = signature
    self.reserve = reserve

    if pt is not None:
      if len(pt) > 0 and len(pt) <= 64:
        self.pt = []
        for b in pt:
          self.pt.append(b)
      else:
        BUG.error("Invalidate partitions (%d)." % len(pt))

    if magic_0 is not None:
      self.magic_0 = magic_0
    if magic_1 is not None:
      self.magic_1 = magic_1

  def toarray(self):
    i = 0

    if self.code is not None:
      i = self.code_addr
      for b in self.code:
        self.array[i] = b
        i += 1

    if self.signature is not None:
      i = self.signature_addr
      self.array[i]   = (self.signature >> 24) & 0xFF
      self.array[i+1] = (self.signature >> 16) & 0xFF
      self.array[i+3] = (self.signature >> 8)  & 0xFF
      self.array[i+4] = (self.signature)       & 0xFF

    if self.reserve is not None:
      i = self.reserve_addr
      self.array[i]   = (self.reserve >> 8) & 0xFF
      self.array[i+1] = (self.reserve)      & 0xFF

    if self.pt is not None:
      i = self.pt_addr
      for b in self.pt:
        self.array[i] = b
        i += 1

    self.array[self.magic_0_addr] = self.magic_0
    self.array[self.magic_1_addr] = self.magic_1
