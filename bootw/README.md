
About BOOTW
==========================================================================

BOOTW is a small CROOK-5 bootloader for EM400 that allows bootstrapping the system
from the first winchester (pysical line 28) connected to MULTIX on channel 1.

It is required for earlier EM400 versions (older than 0.3) to boot CROOK-5
from a winchester disk image. Original bootloaders
assume that MULTIX startup takes time, while synchronous MULTIX emulation
does it instantaneously and causes original bootloaders to fail.


Requirements
==========================================================================

To build bootw you need:

* GNU make
* emas


Build instructions
==========================================================================

Do the following in the source directory:

```
make
```

Running
==========================================================================

To use the bootloader, specify it as a binary to be loaded upon em400 startup:

```
em400 -s bootw.bin
```

Note that you will also need CROOK-5 disk image and a proper em400 configuration for this to work.

