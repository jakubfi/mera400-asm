PRJ=t64
CFG=em400.cfg
UPLOAD_PORT=/dev/ttyUSB0

all: $(PRJ)

${PRJ}: $(PRJ).asm
	emas -o $(PRJ) -c mera400 -Oraw $(PRJ).asm

emu: $(PRJ)
	em400 -c $(CFG) -p $(PRJ)

push: $(BIN)
	embin -o $(UPLOAD_PORT) $(PRJ)

clean:
	rm -f $(PRJ) em400.log

