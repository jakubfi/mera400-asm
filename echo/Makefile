PROJECT=echo
CFG=em400.ini
UPLOAD_PORT=/dev/ttyUSB0
INCLUDES=kz.asm stdio.asm

$(PROJECT): $(PROJECT).asm $(INCLUDES)
	emas -o $(PROJECT) -c mera400 -O raw $(PROJECT).asm

emu: $(PROJECT)
	em400 -c $(CFG) -p $(PROJECT)

push: $(PROJECT)
	embin -o $(UPLOAD_PORT) $(PROJECT)

clean:
	rm -f $(PROJECT) *.log
