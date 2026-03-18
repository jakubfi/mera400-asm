PROJECT=subskrybuj
CFG=em400.ini
UPLOAD_PORT=/dev/ttyUSB0
INCLUDES=../lib/kz.asm ../lib/stdio.asm

$(PROJECT): $(PROJECT).asm $(INCLUDES)
	emas -o $(PROJECT) -c mera400 -I ../lib $(PROJECT).asm

emu: $(PROJECT)
	~/projekty/mera400/em400/build/em400 -c $(CFG) -p $(PROJECT)

push: $(PROJECT)
	~/projekty/mera400/em400/build/embin -o $(UPLOAD_PORT) $(PROJECT)

clean:
	rm -f $(PROJECT) *.log raw.inc
