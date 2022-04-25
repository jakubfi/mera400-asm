import serial
import struct
from crc_algorithms import Crc


# ------------------------------------------------------------------------
class FlopError(Exception):
    def __init__(self, message, interrupt):
        self.interrupt = interrupt
        if interrupt == Flop.INT_HW:
            self.err = "H"
        elif interrupt == Flop.INT_NOT_FOUND:
            self.err = "N"
        elif interrupt == Flop.INT_CRC:
            self.err = "C"
        elif interrupt == Flop.INT_BAD_SECTOR:
            self.err = "B"
        else:
            self.err = "E"
        super().__init__(message)


# ------------------------------------------------------------------------
class CommError(Exception):
    pass


# ------------------------------------------------------------------------
class Flop:

    SECT_LEN = 128
    SPT = 26
    TRACKS = 77

    CMD_RESET = 1
    CMD_SEEK_RD = 2
    CMD_READ = 3

    DRIVES = [0b000, 0b001, 0b100, 0b101]
    SIDES = [0, 1]

    RESP_UNKNOWN    = 0
    RESP_OK         = 1
    RESP_BAD_CMD    = 2
    RESP_BAD_CRC    = 3
    RESP_IOERR      = 4

    INT_HW = 0b00010
    INT_NOT_FOUND = 0b11010
    INT_CRC = 0b01010
    INT_BAD_SECTOR = 0b10010

    interrupt_names = {
        0b00001: 'READY',
        0b00100: 'DISK END',
        0b00010: 'HW ERROR',
        0b11010: 'PARITY OR SECTOR NOT FOUND',
        0b01010: 'CRC ERROR',
        0b10010: 'SECTOR MARKED BAD',
        0b00000: 'INTERRUPT EXPIRED',
    }

    status_names = {
        0: 'invalid response',
        1: 'OK',
        2: 'unknown command',
        3: 'CRC error',
        4: 'I/O error',
    }

    # ------------------------------------------------------------------------
    def __init__(self, device, speed, debug=False, cancel_echo=True):
        self.debug = debug
        self.cancel_echo = cancel_echo

        self.port = serial.Serial(
            device,
            baudrate = speed,
            bytesize = serial.EIGHTBITS,
            parity = serial.PARITY_NONE,
            stopbits = serial.STOPBITS_ONE,
            timeout = None,
            xonxoff = False,
            rtscts = False,
            dsrdtr = False
        )

        self.port.flushInput()
        self.port.flushOutput()

        self.crc = Crc(width = 16, poly = 0x1021, reflect_in = False, xor_in = 0x1D0F, reflect_out = False, xor_out = 0);

    # ------------------------------------------------------------------------
    def send_with_crc(self, fmt, data):
        csum = self.crc.table_driven(struct.pack(fmt, *data))
        buf = struct.pack(f"{fmt}H", *data, csum)
        if self.debug:
            print(f"Out: {data}, crc: {csum}, stream: {buf}")

        self.port.write(buf)
        if self.cancel_echo:
            self.port.read(len(buf))

    # ------------------------------------------------------------------------
    def recv_bytes_with_crc(self, length):
        buf = self.port.read(length)
        crc_received = struct.unpack(">H", self.port.read(2))[0]
        crc_check = self.crc.table_driven(buf)
        if self.debug:
            print(f"In: {buf}, crc received: {crc_received}, crc calculated: {crc_check}")
        if crc_received != crc_check:
            raise CommError("Received stream CRC error")
        return buf

    # ------------------------------------------------------------------------
    def recv_with_crc(self, fmt):
        length = struct.calcsize(fmt)
        buf = self.recv_bytes_with_crc(length)
        return struct.unpack_from(fmt, buf)

    # ------------------------------------------------------------------------
    def send_cmd(self, cmd, addr=0):
        self.send_with_crc(">HH", [cmd, addr])
        (interrupt, status) = self.recv_with_crc(">BB")
        if self.debug:
            print(f"Int: {interrupt}, status: {status}")
        if status != Flop.RESP_OK:
            status_name = Flop.status_names[status]
            message = f"Command error: {status_name}"
            if status == Flop.RESP_IOERR:
                interrupt_name = Flop.interrupt_names[interrupt]
                message = (f"{message}, interrupt: {interrupt_name}")
            raise FlopError(message, interrupt)

    # ------------------------------------------------------------------------
    def reset(self):
        self.send_cmd(Flop.CMD_RESET)

    # ------------------------------------------------------------------------
    def seek_rd(self, drive, side, track, sector):
        # addr format: dddstttttttSSSSS
        addr = (drive << 13) | (side << 12) | (track << 5) | sector
        self.send_cmd(Flop.CMD_SEEK_RD, addr)

    # ------------------------------------------------------------------------
    def read_sector(self):
        self.send_cmd(Flop.CMD_READ)
        data = self.recv_bytes_with_crc(Flop.SECT_LEN)
        return data
