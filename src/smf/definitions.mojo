from utils import Variant


struct SMFFormat:
    alias SMF_0 = UInt16(0)
    alias SMF_1 = UInt16(1)
    alias SMF_2 = UInt16(2)
    alias UNKNOWN = UInt16(UInt16.MAX)


@value
struct SMFEvent(Representable):
    var rel_tick: UInt32
    var abs_tick: UInt32
    var rel_time: Float64
    var abs_time: Float64
    var event_type: UInt8
    var data: List[UInt8]

    fn __repr__(self) -> String:
        try:
            formatted_str = 'SMF Event:\n\t- Delta Tick:{0}\n\t- Abs Tick {1}\n\t- Delta Time: {2}\n\t- Abs Time: {3}\n\t- Type: {4}\n\t- Data: {5}'
            return formatted_str.format(self.rel_tick, self.abs_tick, self.rel_time, self.abs_time, self.event_type, ', '.join(self.data))
        except:
            return ''

    fn __lt__(self, rhs: SMFEvent) -> Bool:
        return self.abs_time < rhs.abs_time

    fn __gt__(self, rhs: SMFEvent) -> Bool:
        return self.abs_time > rhs.abs_time

    fn __eq__(self, rhs: SMFEvent) -> Bool:
        return self.abs_time == rhs.abs_time

    @staticmethod
    fn sort_ascending_cmp(a: SMFEvent, b: SMFEvent) capturing -> Bool:
        return a.abs_time < b.abs_time


@value
struct MidiNoteOn:
    var rel_time: Float64
    var abs_time: Float64
    var abs_offset_time: Float64
    var channel: UInt8
    var key: UInt8
    var velocity: UInt8

    fn __init__(out self, smf_event: SMFEvent):
        self.rel_time = smf_event.rel_time
        self.abs_time = smf_event.abs_time
        self.abs_offset_time = 0.0
        self.channel = smf_event.event_type & 0x0f
        self.key = smf_event.data[0]
        self.velocity = smf_event.data[1]

    fn __repr__(self) -> String:
        try:
            formatted_str = 'Note On:\n\t- Relative Time (s): {0}\n\t- Absolute Time (s): {1}\n\t- Offset Time (s): {2}\n\t- Channel: {3}\n\t- Key: {4}\n\t- Velocity: {5}'
            return formatted_str.format(self.rel_time, self.abs_time, self.abs_offset_time, self.channel, self.key, self.velocity)
        except:
            return ''


@value
struct MidiNoteOff:
    var rel_time: Float64
    var abs_time: Float64
    var abs_onset_time: Float64
    var channel: UInt8
    var key: UInt8
    var velocity: UInt8

    fn __init__(out self, smf_event: SMFEvent):
        self.rel_time = smf_event.rel_time
        self.abs_time = smf_event.abs_time
        self.abs_onset_time = 0.0
        self.channel = smf_event.event_type & 0x0f
        self.key = smf_event.data[0]
        self.velocity = smf_event.data[1]

    fn __repr__(self) -> String:
        try:
            formatted_str = 'Note Off:\n\t- Relative Time (s): {0}\n\t- Absolute Time (s): {1}\n\t- Onset Time (s): {2}\n\t- Channel: {3}\n\t- Key: {4}\n\t- Velocity: {5}'
            return formatted_str.format(self.rel_time, self.abs_time, self.abs_onset_time, self.channel, self.key, self.velocity)
        except:
            return ''


@value
struct MidiControlChange:
    var rel_time: Float64
    var abs_time: Float64
    var channel: UInt8
    var control_number: UInt8
    var value: UInt8

    fn __init__(out self, smf_event: SMFEvent):
        self.rel_time = smf_event.rel_time
        self.abs_time = smf_event.abs_time
        self.channel = smf_event.event_type & 0x0f
        self.control_number = smf_event.data[0]
        self.value = smf_event.data[1]

    fn __repr__(self) -> String:
        try:
            formatted_str = 'Control Change:\n\t- Relative Time (s): {0}\n\t- Absolute Time (s): {1}\n\t- Channel: {2}\n\t- CC: {3}\n\t- Value: {4}'
            return formatted_str.format(self.rel_time, self.abs_time, self.channel, self.control_number, self.value)
        except:
            return ''


@value
struct MidiPolyphonicAftertouch:
    var rel_time: Float64
    var abs_time: Float64
    var channel: UInt8
    var key: UInt8
    var pressure: UInt8

    fn __init__(out self, smf_event: SMFEvent):
        self.rel_time = smf_event.rel_time
        self.abs_time = smf_event.abs_time
        self.channel = smf_event.event_type & 0x0f
        self.key = smf_event.data[0]
        self.pressure = smf_event.data[1]

    fn __repr__(self) -> String:
        try:
            formatted_str = 'Polyphonic Aftertouch:\n\t- Relative Time (s): {0}\n\t- Absolute Time (s): {1}\n\t- Channel: {2}\n\t- Key: {3}\n\t- Pressure: {4}'
            return formatted_str.format(self.rel_time, self.abs_time, self.channel, self.key, self.pressure)
        except:
            return ''


@value
struct MidiPitchBend:
    var rel_time: Float64
    var abs_time: Float64
    var channel: UInt8
    var lsb: UInt8
    var msb: UInt8

    fn __init__(out self, smf_event: SMFEvent):
        self.rel_time = smf_event.rel_time
        self.abs_time = smf_event.abs_time
        self.channel = smf_event.event_type & 0x0f
        self.lsb = smf_event.data[0]
        self.msb = smf_event.data[1]

    fn __repr__(self) -> String:
        try:
            formatted_str = 'Pitch Bend Change:\n\t- Relative Time (s): {0}\n\t- Absolute Time (s): {1}\n\t- Channel: {2}\n\t- LSB: {3}\n\t- MSB: {4}'
            return formatted_str.format(self.rel_time, self.abs_time, self.channel, self.lsb, self.msb)
        except:
            return ''


@value
struct MidiProgramChange:
    var rel_time: Float64
    var abs_time: Float64
    var channel: UInt8
    var program: UInt8

    fn __init__(out self, smf_event: SMFEvent):
        self.rel_time = smf_event.rel_time
        self.abs_time = smf_event.abs_time
        self.channel = smf_event.event_type & 0x0f
        self.program = smf_event.data[0]

    fn __repr__(self) -> String:
        try:
            formatted_str = 'Program Change:\n\t- Relative Time (s): {0}\n\t- Absolute Time (s): {1}\n\t- Channel: {2}\n\t- Program: {3}'
            return formatted_str.format(self.rel_time, self.abs_time, self.channel, self.program)
        except:
            return ''


@value
struct MidiChannelAftertouch:
    var rel_time: Float64
    var abs_time: Float64
    var channel: UInt8
    var pressure: UInt8

    fn __init__(out self, smf_event: SMFEvent):
        self.rel_time = smf_event.rel_time
        self.abs_time = smf_event.abs_time
        self.channel = smf_event.event_type & 0x0f
        self.pressure = smf_event.data[0]

    fn __repr__(self) -> String:
        try:
            formatted_str = 'Channel Aftertouch:\n\t- Relative Time (s): {0}\n\t- Absolute Time (s): {1}\n\t- Channel: {2}\n\t- Pressure: {3}'
            return formatted_str.format(self.rel_time, self.abs_time, self.channel, self.pressure)
        except:
            return ''

alias MidiEvent = Variant[
    MidiNoteOn, MidiNoteOff, MidiControlChange, MidiPolyphonicAftertouch,
    MidiPitchBend, MidiProgramChange, MidiChannelAftertouch
]
