all: zip1.lst zip1.bin zip1-check \
     zip2.lst zip2.bin zip2-check \
     zip3.lst zip3.bin zip3-check

%.p %.lst: %.asm
	asl $< -o $*.p -L


zip1.p zip1.lst: zip.asm
	asl zip.asm -o zip1.p -L -OLIST zip1.lst -D iver=1

zip1.bin: zip1.p
	p2bin -r '$$0800-$$21ff' zip1.p

zip1-check: zip1.bin
	echo "f8794ae41175b27a80af3a11a049d2696b16b560541b20be03d64efc0278286f zip1.bin" | sha256sum -c -


zip2.p zip2.lst: zip.asm
	asl zip.asm -o zip2.p -L -OLIST zip2.lst -D iver=2

zip2.bin: zip2.p
	p2bin -r '$$0800-$$21ff' zip2.p

zip2-check: zip2.bin
	echo "137bc760bf92fe1ab0054c03e0d253d8d21933a24ff23f09c88db851bbd18762 zip2.bin" | sha256sum -c -


zip3.p zip3.lst: zip.asm
	asl zip.asm -o zip3.p -L -OLIST zip3.lst -D iver=3

zip3.bin: zip3.p
	p2bin -r '$$0800-$$21ff' zip3.p

zip3-check: zip3.bin
	echo "2050236bf501794d01b7610288eafcaf54a739f5caaf77c17a253e75f4928f1a zip3.bin" | sha256sum -c -




clean:
	rm -f zip[23].{p,lst,bin}


.PRECIOUS: %.lst
