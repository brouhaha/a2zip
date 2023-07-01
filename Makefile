all: zip1.lst  zip1.bin  zip1-check \
     zip2.lst  zip2.bin  zip2-check \
     zip3.lst  zip3.bin  zip3-check \
     zip3a.lst zip3a.bin zip3a-check \
     zip3b.lst zip3b.bin zip3b-check \
     zip3f.lst zip3f.bin zip3f-check \
     zip3h.lst zip3h.bin zip3h-check \
     zip3k.lst zip3k.bin zip3k-check \
     zip3m.lst zip3m.bin zip3m-check \
     ezip2a.lst ezip2a.bin ezip2a-check \
     ezip2b.lst ezip2b.bin ezip2b-check \
     ezip2c.lst ezip2c.bin ezip2c-check \
     ezip2d.lst ezip2d.bin ezip2d-check \
     ezip2h.lst ezip2h.bin ezip2h-check


%.p %.lst: %.asm
	asl $< -o $*.p -L


zip1.p zip1.lst: zip.asm
	asl zip.asm -o zip1.p -L -OLIST zip1.lst -D iver='$$0100'

zip1.bin: zip1.p
	p2bin -r '$$0800-$$21ff' zip1.p

zip1-check: zip1.bin
	echo "f8794ae41175b27a80af3a11a049d2696b16b560541b20be03d64efc0278286f zip1.bin" | sha256sum -c -


zip2.p zip2.lst: zip.asm
	asl zip.asm -o zip2.p -L -OLIST zip2.lst -D iver='$$0200'

zip2.bin: zip2.p
	p2bin -r '$$0800-$$21ff' zip2.p

zip2-check: zip2.bin
	echo "137bc760bf92fe1ab0054c03e0d253d8d21933a24ff23f09c88db851bbd18762 zip2.bin" | sha256sum -c -


zip3.p zip3.lst: zip.asm
	asl zip.asm -o zip3.p -L -OLIST zip3.lst -D iver='$$0300'

zip3.bin: zip3.p
	p2bin -r '$$0800-$$21ff' zip3.p

zip3-check: zip3.bin
	echo "2050236bf501794d01b7610288eafcaf54a739f5caaf77c17a253e75f4928f1a zip3.bin" | sha256sum -c -


zip3a.p zip3a.lst: zip.asm
	asl zip.asm -o zip3a.p -L -OLIST zip3a.lst -D iver='$$0301'

zip3a.bin: zip3a.p
	p2bin -r '$$0800-$$23ff' zip3a.p

zip3a-check: zip3a.bin
	echo "a349844df88798e3a98aca046098db388fad098924dfb8dd0049c04235e32b28 zip3a.bin" | sha256sum -c -


zip3b.p zip3b.lst: zip.asm
	asl zip.asm -o zip3b.p -L -OLIST zip3b.lst -D iver='$$0302'

zip3b.bin: zip3b.p
	p2bin -r '$$0800-$$23ff' zip3b.p

zip3b-check: zip3b.bin
	echo "98ab866beb68f1d78b978a36106e611fd9196ffe7cd6d2e534c145197be3ebc1 zip3b.bin" | sha256sum -c -


zip3f.p zip3f.lst: zip-late.asm
	asl zip-late.asm -o zip3f.p -L -OLIST zip3f.lst -D iver='$$0306'

zip3f.bin: zip3f.p
	p2bin -r '$$0900-$$27ff' zip3f.p

zip3f-check: zip3f.bin
	echo "6bcc991eb5bdc55a6c0ddb6f307c630ee273f7b95ad0d5f3bc1d9e34ee0ed988 zip3f.bin" | sha256sum -c -


zip3h.p zip3h.lst: zip-late.asm
	asl zip-late.asm -o zip3h.p -L -OLIST zip3h.lst -D iver='$$0308'

zip3h.bin: zip3h.p
	p2bin -r '$$0900-$$27ff' zip3h.p

zip3h-check: zip3h.bin
	echo "7523c44811190cbce363eaf9ed04f67780794a86d849470acd5e0b8b6bb4d6a7 zip3h.bin" | sha256sum -c -


zip3k.p zip3k.lst: zip-late.asm
	asl zip-late.asm -o zip3k.p -L -OLIST zip3k.lst -D iver='$$030b'

zip3k.bin: zip3k.p
	p2bin -r '$$0900-$$27ff' zip3k.p

zip3k-check: zip3k.bin
	echo "0fd531fb0366bff94fdc1e4e95fee8ca77d2a513d3dbb5ddc4fd518acbeb0c60 zip3k.bin" | sha256sum -c -


zip3m.p zip3m.lst: zip-late.asm
	asl zip-late.asm -o zip3m.p -L -OLIST zip3m.lst -D iver='$$030d'

zip3m.bin: zip3m.p
	p2bin -r '$$0900-$$27ff' zip3m.p

zip3m-check: zip3m.bin
	echo "e9f42d7f2ea8b8cd942a95abc11a90a46d69fa4dd3102bd1ec35bb9cfd3f9a97 zip3m.bin" | sha256sum -c -


ezip2a.p ezip2a.lst: ezip.asm
	asl ezip.asm -o ezip2a.p -L -OLIST ezip2a.lst -D iver='$$0201'

ezip2a.bin: ezip2a.p
	p2bin -r '$$d000-$$f6ff' ezip2a.p

ezip2a-check: ezip2a.bin
	echo "27791a3458d8c37a8db84a07dc74ce38ec902297a42acf578d259485a4b652db ezip2a.bin" | sha256sum -c


ezip2b.p ezip2b.lst: ezip.asm
	asl ezip.asm -o ezip2b.p -L -OLIST ezip2b.lst -D iver='$$0202'

ezip2b.bin: ezip2b.p
	p2bin -r '$$d000-$$f7ff' ezip2b.p

ezip2b-check: ezip2b.bin
	echo "86b3cfd5a834f304bdf8094ed56efaab5d75f318291590fdc4594c87c731f701 ezip2b.bin" | sha256sum -c


ezip2c.p ezip2c.lst: ezip.asm
	asl ezip.asm -o ezip2c.p -L -OLIST ezip2c.lst -D iver='$$0203'

ezip2c.bin: ezip2c.p
	p2bin -r '$$d000-$$f7ff' ezip2c.p

ezip2c-check: ezip2c.bin
	echo "9fd17f9952a447affc995948ae6356b83f68e828caed50dfaa850826083d5248 ezip2c.bin" | sha256sum -c


ezip2d.p ezip2d.lst: ezip.asm
	asl ezip.asm -o ezip2d.p -L -OLIST ezip2d.lst -D iver='$$0204'

ezip2d.bin: ezip2d.p
	p2bin -r '$$d000-$$f7ff' ezip2d.p

ezip2d-check: ezip2d.bin
	echo "2171db824068a23d9291031a20ea81bbbeea7d5af8174e42153adfb282dc99a5 ezip2d.bin" | sha256sum -c


ezip2h.p ezip2h.lst: ezip.asm
	asl ezip.asm -o ezip2h.p -L -OLIST ezip2h.lst -D iver='$$0208'

ezip2h.bin: ezip2h.p
	p2bin -r '$$d000-$$f7ff' ezip2h.p

ezip2h-check: ezip2h.bin
	echo "2683ce2f038bce968796540a3a9ce652a9e4120d06a75ee2e80c09cab7c09503 ezip2h.bin" | sha256sum -c


clean:
	rm -f zip{1,2,3,3a,3b}.{p,lst,bin}
	rm -f ezip2{a,b,c,d,h}.{p,lst,bin}


.PRECIOUS: %.lst
