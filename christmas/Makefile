PROJECT=christmas
CFG=em400.ini
UPLOAD_PORT=/dev/ttyUSB0
INCLUDES=kz.asm stdio.asm

$(PROJECT): $(PROJECT).asm $(INCLUDES) raw.inc
	emas -o $(PROJECT) -c mera400 -Oraw $(PROJECT).asm

emu: $(PROJECT)
	em400 -c $(CFG) -p $(PROJECT)

push: $(PROJECT)
	embin -o $(UPLOAD_PORT) $(PROJECT)
raw.inc: raw.txt
	./escape.py raw.txt > raw.inc

clean:
	rm -f $(PROJECT) *.log raw.inc
