# a2zip - Infocom ZIP release 3 interpreter for Apple II, partially reverse-engineered

Original code copyright Infocom, Inc.
Disassembly including labels and comments copyright 1984 Eric Smith <spacewar@gmail.com>

In 1984, the best 6502 assembler available to me was the Microsoft
ALDS assembler, which ran on CP/M on the Apple II using a Microsoft
Z80 Softcard. The assembly source code was thus written for that
assembler, and would not without some changes assemble with any other
assembler. This directory contains the old code which assembles with
ALDS. It is preserved only for historical interest, and it is not
expected that any updates will be made to this version.

To use ALDS, ensure that the source files use CR LF line endings (as
used by MS-DOS) and have a control-Z character at the end. (CP/M doesn't
have precise file lengths, so it uses a control-Z to denote end of file.)
Copy the files to an Apple CP/M disk (or disk image).

An single Apple II floppy isn't large enough to hold all of the files
needed. If you have a larger drive (perhaps a hard disk) accessible to
CP/M, you can use these commands:

    m80 =zip/l/c/r
    cref80 =zip
    l80 zip,zip/n/e

If you need to use multiple drives, the commands will have to be adjusted.
For example, if you have tools and source code on drive A, scratch files
on drive B, and final object code and listing files on drive C, you could
use:

    m80 zip,b:zip=zip/c
    cref80 c:zip=b:zip
    l80 zip,c:zip/n/e

