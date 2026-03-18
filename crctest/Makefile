PRJ=crctest
INCLUDES=../lib/stdio.asm ../lib/kz.asm ../lib/crc.asm
CFG=em400.ini
UPLOAD_PORT=/dev/ttyUSB0

$(PRJ): $(PRJ).asm $(INCLUDES)
	cpp -P -undef $(PRJ).asm -o preproc_$(PRJ).asm
	emas preproc_$(PRJ).asm -I ../lib -o $(PRJ)

emu: $(PRJ)
	em400 -c $(CFG) -p $(PRJ)

push: $(PRJ)
	embin -o $(UPLOAD_PORT) $(PRJ)

clean:
	rm -f preproc_* $(PRJ) *.log
