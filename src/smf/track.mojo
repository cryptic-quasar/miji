from .definitions import (SMFEvent, MidiEvent)
from .header import SMFHeader


struct TrackParsingFSM:
    alias PARSE_DELTA_TIME = 0
    alias PARSE_STATUS = 1
    alias PARSE_EVENT_META = 2
    alias PARSE_EVENT_MIDI_SYS_EX = 3
    alias PARSE_EVENT_MIDI_STD = 4


@value
struct TrackParsingProps:
    var fsm: Int
    var iter_idx: Int
    var status_byte: UInt8
    var delta_tick: UInt32
    var abs_tick: UInt32
    var abs_time: Float64
    var tempo: UInt32


@value
struct SMFTrack(Representable):
    var byte_size: Int64
    var events: List[SMFEvent]
    var midi_events: List[MidiEvent]
    var parsingProps: TrackParsingProps

    fn __init__(out self):
        self.byte_size = 0
        self.events = List[SMFEvent]()
        self.midi_events = List[MidiEvent]()
        self.parsingProps = TrackParsingProps(TrackParsingFSM.PARSE_DELTA_TIME, 0, 0, 0, 0, 0.0, 500_000)

    fn __repr__(self) -> String:
        try:
            return 'SMF Track Info:\n\t- Data Byte Size: {0}\n\t- Number of Events: {1}'.format(self.byte_size, len(self.events))
        except:
            return ''

    fn _is_midi_track(self, midi_file: FileHandle) -> Bool:
        try:
            track_header_bytes = midi_file.read_bytes(4)
        except:
            return False
        if track_header_bytes.bytecount() < 4:
            return False
        return (
            track_header_bytes[0] == ord('M') and track_header_bytes[1] == ord('T') and \
            track_header_bytes[2] == ord('r') and track_header_bytes[3] == ord('k')
        )

    @staticmethod
    fn _convert_tick_to_seconds(rel_tick: UInt32, ticks_per_beat: UInt16, tempo: UInt32) -> Float64:
        return Float64(int(rel_tick)) * Float64(int(tempo)) * 1e-6 / Float64(int(ticks_per_beat))

    fn _parse_data_byte_size(mut self, midi_file: FileHandle):
        try:
            track_header_bytes = midi_file.read_bytes(4)
        except:
            return
        if track_header_bytes.bytecount() < 4:
            return
        self.byte_size = (
            (track_header_bytes[3].cast[DType.int64]() << 0x00) |
            (track_header_bytes[2].cast[DType.int64]() << 0x08) |
            (track_header_bytes[1].cast[DType.int64]() << 0x10) |
            (track_header_bytes[0].cast[DType.int64]() << 0x18)
        )

    @always_inline
    fn _parse_event_time(mut self, track_data_bytes: List[UInt8], header: SMFHeader):
        while True:
            track_byte = track_data_bytes[self.parsingProps.iter_idx]
            self.parsingProps.iter_idx += 1
            self.parsingProps.delta_tick = (self.parsingProps.delta_tick << 7) | (track_byte.cast[DType.uint32]() & 0x7f)
            if track_byte < 0x80:
                break
        self.parsingProps.abs_tick += self.parsingProps.delta_tick
        rel_time = self._convert_tick_to_seconds(
            self.parsingProps.delta_tick, header.ticks_per_beat, self.parsingProps.tempo
        )
        self.parsingProps.abs_time += rel_time
        self.events.append(
            SMFEvent(
                self.parsingProps.delta_tick, self.parsingProps.abs_tick, rel_time, self.parsingProps.abs_time,
                0, List[UInt8]()
            )
        )
        self.parsingProps.fsm = TrackParsingFSM.PARSE_STATUS
        self.parsingProps.delta_tick = 0

    @always_inline
    fn _parse_event_status(mut self, track_data_bytes: List[UInt8]):
        track_byte = track_data_bytes[self.parsingProps.iter_idx]
        if track_byte >= 0x80:
            self.parsingProps.iter_idx += 1
            self.parsingProps.status_byte = track_byte
        self.events[-1].event_type = self.parsingProps.status_byte
        self.parsingProps.fsm = TrackParsingFSM.PARSE_EVENT_MIDI_STD
        if self.parsingProps.status_byte == 0xff:
            self.parsingProps.fsm = TrackParsingFSM.PARSE_EVENT_META
        elif self.parsingProps.status_byte >= 0xf0:
            self.parsingProps.fsm = TrackParsingFSM.PARSE_EVENT_MIDI_SYS_EX

    @always_inline
    fn _parse_meta_event(mut self, track_data_bytes: List[UInt8]):
        meta_type = track_data_bytes[self.parsingProps.iter_idx]
        self.parsingProps.iter_idx += 1
        self.events[-1].data.append(meta_type)
        data_length = track_data_bytes[self.parsingProps.iter_idx]
        self.parsingProps.iter_idx += 1
        self.events[-1].data.append(data_length)
        meta_data = track_data_bytes[self.parsingProps.iter_idx : self.parsingProps.iter_idx + int(data_length)]
        self.events[-1].data.extend(meta_data)
        if meta_type == 0x51:
            self.parsingProps.tempo = (
                (meta_data[0].cast[DType.uint32]() << 16) |
                (meta_data[1].cast[DType.uint32]() << 8) |
                (meta_data[2].cast[DType.uint32]() << 0)
            )
        self.parsingProps.iter_idx += int(data_length)
        self.parsingProps.fsm = TrackParsingFSM.PARSE_DELTA_TIME

    @always_inline
    fn _parse_std_midi_event(mut self, track_data_bytes: List[UInt8]):
        status = self.events[-1].event_type
        if (UInt8(0x80) <= status <= UInt8(0xbf)) or (UInt8(0xe0) <= status <= UInt8(0xef)):
            self.events[-1].data.extend(track_data_bytes[self.parsingProps.iter_idx : self.parsingProps.iter_idx + 2])
            self.parsingProps.iter_idx += 2
        elif UInt8(0xc0) <= status <= UInt8(0xdf):
            self.events[-1].data.extend(track_data_bytes[self.parsingProps.iter_idx : self.parsingProps.iter_idx + 1])
            self.parsingProps.iter_idx += 1
        self.parsingProps.fsm = TrackParsingFSM.PARSE_DELTA_TIME

    fn _parse_track_events(mut self, track_data_bytes: List[UInt8], header: SMFHeader):
        while self.parsingProps.iter_idx < track_data_bytes.bytecount():
            if self.parsingProps.fsm == TrackParsingFSM.PARSE_DELTA_TIME:
                self._parse_event_time(track_data_bytes, header)
            elif self.parsingProps.fsm == TrackParsingFSM.PARSE_STATUS:
                self._parse_event_status(track_data_bytes)
            elif self.parsingProps.fsm == TrackParsingFSM.PARSE_EVENT_META:
                self._parse_meta_event(track_data_bytes)
            elif self.parsingProps.fsm == TrackParsingFSM.PARSE_EVENT_MIDI_STD:
                self._parse_std_midi_event(track_data_bytes)

    fn parse(mut self, midi_file: FileHandle, header: SMFHeader):
        if not self._is_midi_track(midi_file=midi_file):
            return
        self._parse_data_byte_size(midi_file=midi_file)
        try:
            self._parse_track_events(
                track_data_bytes=midi_file.read_bytes(self.byte_size), header=header
            )
        except:
            return

    fn duration(self) -> Float64:
        from memory import Span
        if len(self.events) > 0:
            return self.events[-1].abs_time
        return 0.0
