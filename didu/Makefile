INCLUDES=stdio.asm kz.asm crc.asm
CFG=em400.ini
UPLOAD_PORT=/dev/ttyUSB0

dd: dd.asm $(INCLUDES)
	emas -o dd -c mera400 -Oraw dd.asm

emu: $(BIN)
	em400 -c $(CFG) -p dd

push: $(BIN)
	embin -o $(UPLOAD_PORT) dd

clean:
	rm -f dd *.log
