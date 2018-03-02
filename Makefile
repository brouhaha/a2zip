all: zip.lst zip.bin check

%.p %.lst: %.asm
	asl $< -o $*.p -L

zip.bin: zip.p
	p2bin -r '$$0800-$$21ff' zip.p

check: zip.bin
	echo "2050236bf501794d01b7610288eafcaf54a739f5caaf77c17a253e75f4928f1a zip.bin" | sha256sum -c -

clean:
	rm liron-if.bin *.p *.lst

check:

.PRECIOUS: %.lst
