EMAS=emas
EMDAS=emdas
EMLIN=emlin
EMELF=emelfread

PROJ=bootw.bin

all:	$(PROJ)

%.bin: %.asm
	$(EMAS) -o $@ -Oraw $<

dasm: $(PROJ)
	$(EMDAS) -o $(PROJ).asm $(PROJ)

clean:
	rm -f $(PROJ) $(PROJ).asm
