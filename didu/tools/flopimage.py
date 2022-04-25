from pathlib import Path
from sector import Sector


# ------------------------------------------------------------------------
class ImageSizeError(Exception):
    pass


# ------------------------------------------------------------------------
class DataPresent(Exception):
    pass


# ------------------------------------------------------------------------
class FlopImage:

    # status mapping between status file and sector status
    to_sector_status = {
        'E': Sector.ERR,
        'U': Sector.UNKNOWN,
        'B': Sector.BAD,
    }
    from_sector_status = dict((v, k) for k, v in to_sector_status.items())

    # ------------------------------------------------------------------------
    def __init__(self, image_name, tracks, spt, sect_len, old_format=False):
        self.tracks = tracks
        self.spt = spt
        self.sect_len = sect_len

        self.image_name = Path(image_name)
        self.image_state = self.image_name.with_suffix('.state')
        self.image = self._empty()

        if self.image_name.exists():
            if self.image_name.is_file():
                if old_format:
                    self._load_old()
                else:
                    self._load()
            else:
                raise IsADirectoryError(f"{self.image_name} is not a regular file")

    # ------------------------------------------------------------------------
    def _empty(self):
        return [
            Sector(i // self.spt, (i % self.spt) + 1, self.sect_len, data=None)
            for i in range(self.tracks * self.spt)
        ]

    # ------------------------------------------------------------------------
    def _load(self):
        size_actual = self.image_name.stat().st_size
        size_wanted = self.tracks * self.spt * self.sect_len
        if size_wanted != size_actual:
            tracks = size_actual / self.sect_len / self.spt
            raise ImageSizeError(f"Image size {size_actual} is different than expected {size_wanted} ({tracks} tracks?).")

        # read data
        with open(self.image_name, "rb") as f:
            for s in self.image:
                s.update(f.read(self.sect_len))

        # read sector states
        with open(self.image_state, "r") as f:
            while True:
                l = f.readline().strip()
                if not l:
                    break
                track, sector, status = l.split()
                s = self.sector(int(track), int(sector))
                s.set_status(self.to_sector_status[status])

    # ------------------------------------------------------------------------
    def _load_old(self):
        size_actual = self.image_name.stat().st_size
        size_wanted = self.tracks * self.spt * self.sect_len
        if size_wanted != size_actual:
            tracks = size_actual / self.sect_len / self.spt
            raise ImageSizeError(f"Image size {size_actual} is different than expected {size_wanted} ({tracks} tracks?).")
        if self.image_state.exists():
            raise FileExistsError(f"State file '{self.image_state}' for the image '{self.image_name}' already exists. Already converted?")

        with open(self.image_name, "rb") as f:
            for s in self.image:
                data = f.read(self.sect_len)
                if data == self.sect_len * b'?':
                    s.set_status(Sector.UNKNOWN)
                else:
                    s.update(data)

    # ------------------------------------------------------------------------
    def sector(self, track, sector):
        return self.image[track * self.spt + sector - 1]

    # ------------------------------------------------------------------------
    def save(self):
        with open(self.image_name, "wb") as f:
            for s in self.image:
                f.write(bytes(s))

        with open(self.image_state, "w") as f:
            for s in self.image:
                if not s.ok:
                    status = self.from_sector_status[s.status]
                    f.write(f"{s.track} {s.sector} {status}\n")

    # ------------------------------------------------------------------------
    def debug_dump(self):
        print(f"Image: {self.image_name}")
        for s in self.image:
            print(s)

    # ------------------------------------------------------------------------
    def __iter__(self):
        return iter(self.image)