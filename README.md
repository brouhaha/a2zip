# a2zip - Infocom ZIP version 1 through 3 interpreters for Apple II, partially reverse-engineered

Original code copyright Infocom, Inc.
Disassembly including labels and comments copyright 1984 Eric Smith <spacewar@gmail.com>

z2zip development is hosted at the
[a2zip Github repository](https://github.com/brouhaha/a2zip/).

## Introduction

Infocom games are written in ZIL and compiled to Z-code, which is
interpreted on a ZIP interpreter. ZIP interpreters were written for
many computers, including the Apple II. In 1984 I did reverse-engineered
a substantial portion of the Apple II version 1 through 3 ZIP interpreters.

Originally I assembled the code using Microsoft ALDS; the version of the
sources for that assembler are in the alds subdirectory.

The current source code assembles using the Macro Assembler AS:
    http://john.ccac.rwth-aachen.de:8000/as/

ZIP version 1 is only known to have been used for Zork I release 2
(which might not have been released for the Apple II), and Zork I release 5,
which for the Apple II was provided on a 13-sector disk.

ZIP version 2 is only known to have been used for Zork I release 15
and Zork II release 7. These and all later Infocom games for the Apple II
were provided on 16-sector disks.

Later releases of the Zork games, and many other Infocom games, use
ZIP version 3. The earliest version 3 interpreter, like the version 1 and
version 2 interpreters, did not have any more specific interpreter revision
identification. Later version 3 interpreter revisions for the Apple II
had a revision letter, with revisions A, B, E, H, K, and M known to exist.
None of the lettered revisions are represented here yes.

Eventually game images exceeded the 128KiB limit of ZIP version 3, therefore
necessitating new ZIP versions 4, 5, and 6, which are not represented here.

