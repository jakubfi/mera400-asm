INCLUDES=../lib/stdio.asm ../lib/kz.asm ../lib/crc.asm
CFG=em400.ini
UPLOAD_PORT=/dev/ttyUSB0

dd: dd.asm $(INCLUDES)
	emas -o dd -c mera400 -I ../lib dd.asm

emu: $(BIN)
	em400 -c $(CFG) -p dd ${EM400_OPTS}

push: $(BIN)
	embin -o $(UPLOAD_PORT) dd

clean:
	rm -f dd *.log
