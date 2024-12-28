
@value
struct SMFHeader(Representable):
    var format: UInt16
    var num_tracks: UInt16
    var ticks_per_beat: UInt16

    fn __repr__(self) -> String:
        try:
            return 'SMF Header Info:\n\t- Format: SMF{0}\n\t- Track Count: {1}\n\t- Ticks per Beat: {2}'.format(
                self.format, self.num_tracks, self.ticks_per_beat
            )
        except:
            return ''

    fn _parse_format(mut self, header_bytes: List[UInt8]):
        if header_bytes.bytecount() < 2:
            return
        self.format = (header_bytes[0].cast[DType.uint16]() << 8) | header_bytes[1].cast[DType.uint16]()

    fn _parse_num_tracks(mut self, header_bytes: List[UInt8]):
        if header_bytes.bytecount() < 4:
            return
        self.num_tracks = (header_bytes[2].cast[DType.uint16]() << 8) | header_bytes[3].cast[DType.uint16]()

    fn _parse_ticks_per_beat(mut self, header_bytes: List[UInt8]):
        if header_bytes.bytecount() < 6:
            return
        self.ticks_per_beat = (header_bytes[4].cast[DType.uint16]() << 8) | header_bytes[5].cast[DType.uint16]()

    fn parse(mut self, midi_file: FileHandle):
        try:
            header_bytes = midi_file.read_bytes(6)
        except:
            return
        self._parse_format(header_bytes=header_bytes)
        self._parse_num_tracks(header_bytes=header_bytes)
        self._parse_ticks_per_beat(header_bytes=header_bytes)
