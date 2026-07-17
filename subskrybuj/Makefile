PROJECT=subskrybuj
CFG=em400.ini
UPLOAD_PORT=/dev/ttyUSB0
INCLUDES=../lib/kz.asm ../lib/stdio.asm

$(PROJECT): $(PROJECT).asm $(INCLUDES)
	emas -o $(PROJECT) -c mera400 -I ../lib $(PROJECT).asm

emu: $(PROJECT)
	em400 -c $(CFG) -p $(PROJECT) ${EM400_OPTS}

push: $(PROJECT)
	embin -o $(UPLOAD_PORT) $(PROJECT)

clean:
	rm -f $(PROJECT) *.log raw.inc
