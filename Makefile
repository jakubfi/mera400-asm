PRJ=t64
INI=em400.ini
UPLOAD_PORT=/dev/ttyUSB0

${PRJ}: $(PRJ).asm
	emas -o $(PRJ) -c mera400 -Oraw $(PRJ).asm

emu: $(PRJ)
	em400 -c $(INI) -p $(PRJ)

push: $(BIN)
	embin -o $(UPLOAD_PORT) $(PRJ)

clean:
	rm -f $(PRJ) em400.log

