# a2zip - Infocom ZIP interpreters for Apple II, Z-Machine architectures 1 through 4, partially reverse-engineered

Original code copyright Infocom, Inc.
Disassembly including labels and comments copyright 1983-2023 Eric Smith <spacewar@gmail.com>

z2zip development is hosted at the
[a2zip Github repository](https://github.com/brouhaha/a2zip/).

## Introduction

Infocom games are written in ZIL and compiled to Z-code, which is
interpreted on a ZIP interpreter. ZIP interpreters were written for
many computers, including the Apple II. In 1983 to 1984 I reverse-engineered
a substantial portion of the Apple II version 1 through 3 ZIP interpreters.

More recently I've partially reverse-engineered soem newer Apple II
ZIP, EZIP, and XZIP interpreters.

The reverse-engineered "source code" cross-assembles using the
Macro Assembler AS, which is open source and supports common development
host platforms.:
    http://john.ccac.rwth-aachen.de:8000/as/

No effort has been made to make it possible to assemble the code with
any other assemblers, either native or cross. The code depends on the macro
and local label capabilities of AS.

The provided Makefile is for GNU Make.

## ZIP (Z-Machine architectures v1 through v3)

The Apple II ZIP intepreters for v1, v2, v3, v3 A, and v3B can be built from
the source file "zip.asm", which also uses an include file "zipmac.inc"
defining various macros.  These interpreters depend on boot code and RWTS
(disk routines) not included here. Aside from being relocated to a different
start address, the RWTS routines are very similar to those Apple used in
DOS 3.2.1 and DOS 3.3, with minor changes for the relatively simple
copy protection.

Z-Machine architectures v1 through v3 have only fairly minor differences. The
interpreters for these versions are known as ZIP. The v1 and v2 architectures
were only used for early releases of Zork I and Zork II, and were quickly
obsolted by v3. which was the most common architecture for Infocom games that
did not require more than 128 KiB of virtual machine memory.

Z-Machine architecture v1 is only known to have been used for Zork I release 2
(which might not have been released for the Apple II), and Zork I release 5.
Zork I release 5 was provided for the Apple II on a 13-sector disk, while no
later releases or other Infocom games were available on 13-sector disks.

Z-Machine architecture v2 is only known to have been used for Zork I release 15
and Zork II release 7.

The earliest v3 interpreter for the Apple II, like those for v1 and v2, did
not have any more specific interpreter revision identification. Later v3
interpreter revisions had a revision letter, with revisions A, B, F, H, K,
and M known to exist. Of the lettered revisions, only A and B are currently
represented here.

Revision A added support for the Apple IIe 80-column text mode, with upper
and lower case display, and allowed the user to select a slot number for the
printer interface card, which previously was required to be slot 1.

Revision B added support for splitting the screen into two windows.

## Later ZIP interpreter revisions

Between revision B and revision F of the Apple II ZIP interpreters, a
substantial rearrangement of the code occurred.

The disk I/O routines are derived from RWTS but no longer structured
in the same way as Apple DOS RWTS, and are now more tightly integrated
with the interpreter.

Currently revisions F, H, K, and M can be built from the source file
"zip-late.asm".

## EZIP

Z-Machine architecture v4 doubled the available virtual machine memory size
to 256 KiB, allowed a game to have more objects, allowed vocabulary words to
have up to nine significant characters, and added some improvements to I/O
capabilities. The v4 interpreters are known as EZIP.

There were five revisions of the Apple II EZIP interpreter, designated
2A through 2D, and 2H.  The numric character, 2 is a platform
identifier, referencing the Apple II family, while the alphabetic
character is the revision of the interpreter for that platform.  These
interpeters require an Apple IIe, IIc, IIC+, or IIgs with at least 128
KiB of RAM.

As with later Apple II ZIP interpreter versions, the disk routines are more
tightly integrated with the interpreter. In EZIP (and the later XZIP),
games are usually distributed on two sides, designated A and B. Side A is
bootable and contains the lower addressed portion of the game image, in the
same mildly copy-protected form as the Apple II ZIP interpreters. Side B
is encoded in an 18 sector per track format, similar in concept to
Roland Gustafsson's RWTS18.

Early work on reverse-engineering these is present in the source file
"ezip.asm". This does not use an include file for macro definitions.

## XZIP

The Z-Machine architecture v5 added support for character-cell graphics and
timed input. The v5 interpreters are known as XZIP.

There were five revisions of the Apple II XZIP interpreter, A, C, E,
F, and H. The platform number will be reported as 2, except when using
an Apple IIc, which will be reported as 9.

Early work on reverse-engineering thes is present int eh source file
"xzip.asm". This does not use an include file for macro definitions.

## YZIP

Eventually Infocom added graphics and mouse support, resulting in
Z-Machine architectures 6, with the interpreter known as YZIP.

YZIP is not currently represented here.

## Archive of earliest reverse-engineered source files

When I originally reverse-engineered the early interpreters in 1983-1984, I
assembled the code using Microsoft ALDS, which is not easily available
or easy to use today. The version of the sources for that assembler are in
the "alds" subdirectory.

## Acknowledgements

Special thanks to:

* Richard Turk, for saving the printed listing from the work I did in 1983-1984,
  which was otherwise lost

* 4am, for preserving disk images of huge amounts of Apple II software,
  including early, now-rare Infocom games (e.g., Zork I release 5,
  Zork II release 7)
