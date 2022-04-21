#define puts(buf, dev)		\
	lw	r1, buf		\
	lw	r2, dev		\
	lj	puts

#define put2c(c, dev)		\
	lw	r1, c		\
	lw	r2, dev		\
	lj	put2c

#define memcmp(buf1, buf2, len)	\
	lw	r1, buf1	\
	lw	r2, buf2	\
	lw	r3, len		\
	lj	memcmp

#define memset(buf, len, w)	\
	lw	r1, buf		\
	lw	r2, len		\
	lw	r3, w		\
	lj	memset

#define kz_init(CH)	\
	lw	r1, CH		\
	lj	kz_init

#define kz_reset(dev)		\
	lw	r2, dev		\
	lj	kz_reset

#define kz_detach(dev)		\
	lw	r2, dev		\
	lj	kz_detach

#define kz_seek(addr, dev)	\
	lw	r1, addr	\
	lw	r2, dev		\
	lj	kz_seek

#define kz_wrseek(addr, dev)	\
	lw	r1, addr	\
	lw	r2, dev		\
	lj	kz_wrseek

#define rndfill(buf, len)	\
	lw	r1, buf		\
	lw	r2, len		\
	lj	rndfill

#define write(buf, dev, len)	\
	lw	r1, buf		\
	lw	r2, dev		\
	lw	r3, len		\
	lj	write

#define writew(buf, dev, len)	\
	lw	r1, buf		\
	lw	r2, dev		\
	lw	r3, len		\
	lj	writew

#define read(buf, dev, len)	\
	lw	r1, buf		\
	lw	r2, dev		\
	lw	r3, len		\
	lj	read

#define readw(buf, dev, len)	\
	lw	r1, buf		\
	lw	r2, dev		\
	lw	r3, len		\
	lj	readw
