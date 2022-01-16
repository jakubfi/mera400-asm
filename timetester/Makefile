CFG=em400.ini
UPLOAD_PORT=/dev/ttyUSB0
PROJECT=timetester
INCLUDES=kz.asm stdio.asm

all: $(PROJECT)

$(PROJECT): $(PROJECT).asm $(INCLUDES)
	emas -o $(PROJECT) -c mera400 -Oraw $(PROJECT).asm

emu: $(PROJECT)
	em400 -c $(CFG) -p $(PROJECT)

push: $(PROJECT)
	embin -o $(UPLOAD_PORT) $(PROJECT)

clean:
	rm -f $(PROJECT) *.log
