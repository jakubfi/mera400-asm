CFG=em400.ini
UPLOAD_PORT=/dev/ttyUSB0
PROJECT=memmap

$(PROJECT): $(PROJECT).asm $(INCLUDES)
	emas -o $(PROJECT) -c mera400 -Oraw $(PROJECT).asm

emu: $(PROJECT)
	em400 -c $(CFG) -p $(PROJECT)

push: $(PROJECT)
	embin -o $(UPLOAD_PORT) $(PROJECT)

clean:
	rm -f $(PROJECT) *.log
