from .definitions import SMFFormat, SMFEvent
from .header import SMFHeader
from .track import SMFTrack
import time


struct SMFParser:
    var _file_path: String
    var _file_header: SMFHeader
    var _tracks: List[SMFTrack]

    fn __init__(out self, file_path: String):
        self._file_path = file_path
        self._file_header = SMFHeader(format=SMFFormat.UNKNOWN, num_tracks=0, ticks_per_beat=0)
        self._tracks = List[SMFTrack]()

    @staticmethod
    fn _is_midi_file(midi_file: FileHandle) -> Bool:
        try:
            header_bytes = midi_file.read_bytes(8)
        except:
            return False
        if header_bytes.bytecount() < 8:
            return False
        if header_bytes[0] != ord('M') or header_bytes[1] != ord('T') or header_bytes[2] != ord('h') or header_bytes[3] != ord('d'):
            return False
        return (header_bytes[4] == header_bytes[5] == header_bytes[6] == 0) and header_bytes[7] == 6

    fn parse(mut self) raises:
        with open(self._file_path, 'rb') as file:
            if not self._is_midi_file(file):
                raise Error('Not a MIDI file')
            self._file_header.parse(midi_file=file)
            for _ in range(self._file_header.num_tracks):
                track = SMFTrack()
                track.parse(midi_file=file, header=self._file_header)
                self._tracks.append(track)
