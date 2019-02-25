MAIN=dc.asm
INCLUDES=stdio.asm kz.asm
BIN=dc
CFG=em400.cfg
UPLOAD_PORT=/dev/ttyUSB0

dc: $(MAIN) $(INCLUDES)
	emas -o $(BIN) -c mera400 -Oraw $(MAIN)

emu: $(BIN)
	em400 -c $(CFG) -p $(BIN)

push: $(BIN)
	embin -o $(UPLOAD_PORT) $(BIN)

clean:
	rm -f $(BIN) *.log
