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
(which might not have been released for the Apple II), and Zork I release 5.
Zork I release 5 was provided for the Apple II on a 13-sector disk, while no
later releases or other Infocom games were available on 13-sector disks.

ZIP version 2 is only known to have been used for Zork I release 15
and Zork II release 7.

Later releases of the Zork games, and many other Infocom games, use
ZIP version 3. The earliest version 3 interpreter, like the version 1 and
version 2 interpreters, did not have any more specific interpreter revision
identification. Later version 3 interpreter revisions for the Apple II
had a revision letter, with revisions A, B, E, H, K, and M known to exist.
Of the lettered revisions, only A and B are currently represented here.

Version 3 revision A added support for the Apple IIe 80-column text mode, with upper
and lower case display, and allowed the user to select a slot number for the
printer interface card, which previously was required to be slot 1.

Version 3 revision B added support for splitting the screen into two windows.

Changes introduced in later revisions of the version 3 interpreter have not
yet been analyzed.

Eventually game images exceeded the 128KiB limit of ZIP version 3, therefore
necessitating new ZIP versions 4, 5, and 6, also known as EZIP, XZIP, and YZIP,
respectively. These are not represented here.

## Acknowledgements

Special thanks to:

* Richard Turk, for saving the printed listing from the work I did in 1983,
  which was otherwise lost

* 4am, for preserving disk images of huge amounts of Apple II software,
  including early, now-rare Infocom games (e.g., Zork I release 5,
  Zork II release 7)
