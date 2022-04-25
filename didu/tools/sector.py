# ------------------------------------------------------------------------
class Sector:

    UNKNOWN = 0     # never read
    ERR = 1         # read error
    OK = 2          # read correctly
    BAD = 3         # marked as bad, unreadable
    
    correct_status = [UNKNOWN, ERR, OK, BAD]
    
    # ------------------------------------------------------------------------
    def __init__(self, track, sector, len, data=None):
        self.len = len
        self.track = track
        self.sector = sector
        self.data = data
        if self.data:
            self.status = Sector.OK
        else:
            self.status = Sector.UNKNOWN

    # ------------------------------------------------------------------------
    def update(self, data):
        assert len(data) == self.len

        self.data = data
        self.status = Sector.OK

    # ------------------------------------------------------------------------
    def set_status(self, status):
        assert status in Sector.correct_status

        self.status = status
        self.data = None

    # ------------------------------------------------------------------------
    def __bytes__(self):
        return self.data if self.ok else (self.len * b'?')

    @property
    def unknown(self):
        return self.status == Sector.UNKNOWN
    
    @property
    def err(self):
        return self.status == Sector.ERR

    @property
    def ok(self):
        return self.status == Sector.OK

    @property
    def bad(self):
        return self.status == Sector.BAD