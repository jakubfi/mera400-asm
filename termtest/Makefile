CFG=em400.ini
UPLOAD_PORT=/dev/ttyUSB0
PROJECT=tt

$(PROJECT): $(PROJECT).asm $(INCLUDES)
	emas -o $(PROJECT) -c mera400 -Oraw $(PROJECT).asm

emu: $(BIN)
	em400 -c $(CFG) -p $(PROJECT)

push: $(BIN)
	embin -o $(UPLOAD_PORT) $(PROJECT)

clean:
	rm -f $(PROJECT) *.log
