# a2zip - Infocom ZIP release 3 interpreter for Apple II, partially reverse-engineered

Original code copyright Infocom, Inc.
Disassembly including labels and comments copyright 1984 Eric Smith <spacewar@gmail.com>

z2zip development is hosted at the
[a2zip Github repository](https://github.com/brouhaha/a2zip/).

## Introduction

Infocom games are written in ZIL and compiled to Z-code, which is
interpreted on a ZIP interpreter. ZIP interpreters were written for
many computers, including the Apple II. In 1984 I did reverse-engineered
a substantial portion of the Apple II release 3 ZIP interpreter, as
used by e.g. Zork 3 release 10 and release 15.

Originally I assembled the code using Microsoft ALDS; the version of the
sources for that assembler are in the alds subdirectory.

The current source code assembles using the Macro Assembler AS:
    http://john.ccac.rwth-aachen.de:8000/as/
