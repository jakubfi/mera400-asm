PRJ=dt
CFG=em400.cfg
HW_UPLOAD_PORT=/dev/ttyUSB0
EM400=em400
EMBIN=embin
EMAS=emas

$(PRJ): $(PRJ).ppasm
	$(EMAS) -o $(PRJ) -c mera400 -Oraw $(PRJ).ppasm

%.ppasm: %.asm
	cpp -P -undef $< -o $@

emu: $(PRJ)
	$(EM400) -c $(CFG) -p $(PRJ)

push: $(PRJ)
	$(EMBIN) -o $(HW_UPLOAD_PORT) $(PRJ)

clean:
	rm -f $(PRJ) $(PRJ).ppasm *.log
