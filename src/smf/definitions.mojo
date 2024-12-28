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


alias MidiEvent = Variant[MidiNoteOn, MidiNoteOff, MidiControlChange]
