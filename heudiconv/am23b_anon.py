#!/usr/bin/env python
import sys

#def strip(sid):
#  if sid.startswith("DK_"):
#    return sid[3:]
#  elif sid.startswith("DK"):
#    return sid[2:]
#  else:
#    return sid

def strip(sid):
    parts = sid.split("_")

    for part in parts:
        if part.startswith("B") and part[1:].isdigit():
            return part
    return sid

sid = sys.argv[-1]
print(strip(sid))

