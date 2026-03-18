CFG=em400.ini
UPLOAD_PORT=/dev/ttyUSB0
PROJECT=tt
INCLUDES=../lib/kz.asm ../lib/stdio.asm

$(PROJECT): $(PROJECT).asm $(INCLUDES)
	emas -o $(PROJECT) -c mera400 -I ../lib $(PROJECT).asm

emu: $(BIN)
	em400 -c $(CFG) -p $(PROJECT)

push: $(BIN)
	embin -o $(UPLOAD_PORT) $(PROJECT)

clean:
	rm -f $(PROJECT) *.log
