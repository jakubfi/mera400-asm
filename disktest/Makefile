PRJ=dt
INCLUDE_DIR=../lib/
CFG=em400.ini
HW_UPLOAD_PORT=/dev/ttyUSB0
EM400=~/projekty/mera400/em400/build/em400
EMBIN=embin
EMAS=emas

$(PRJ): $(PRJ).ppasm
	$(EMAS) -I $(INCLUDE_DIR) -o $(PRJ) -c mera400 -Oraw $(PRJ).ppasm

%.ppasm: %.asm
	cpp -I $(INCLUDE_DIR) -P -undef $< -o $@

emu: $(PRJ)
	$(EM400) -c $(CFG) -p $(PRJ)

push: $(PRJ)
	$(EMBIN) -o $(HW_UPLOAD_PORT) $(PRJ)

clean:
	rm -f $(PRJ) $(PRJ).ppasm *.log $(PRJ).inc dt-write-to-floppy

$(PRJ).inc:	$(PRJ)
	od -v --endian=big -x $(PRJ) | sed -e 's/^[0-9]*/.word/g' -e 's/\([0-9a-f]\{4\}\)/0x\1/g' -e 's/\([0-9a-f]\{4\}\)\ /\1, /g' | grep -v '^.word$$' > $(PRJ).inc

dt-write-to-floppy:	dt-write-to-floppy.asm $(PRJ).inc
	$(EMAS) -I $(INCLUDE_DIR) -o dt-write-to-floppy -c mera400 -Oraw dt-write-to-floppy.asm
