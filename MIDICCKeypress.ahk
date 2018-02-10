; MIDI CC Keypress
; by Cuyler Stuwe (salembeats)

; Original code taken from genmce's AHK code (https://github.com/genmce/AHK_Generic-Midi-Program),
; which itself uses MIDI output code from TomB, modified by Lazslo and JimF (https://autohotkey.com/board/topic/17212-midi-output-from-ahk/) 

; Known issues: Device names are all fucky (at least in AHK_L 64-bit).
; Possibly caused by both the Unicode strings AND the 64-bit nature of the system.

; SIMPLE USAGE:

; UseMIDIDevice(index)
; SendMIDIKeypress(cc)

; (Really, if you know the MIDI index of the device you want to use, it can be that simple.)

OpenCloseMidiAPI() { 

    static hModule

    If hModule
        DllCall("FreeLibrary", UInt,hModule), hModule := ""

    If (0 = hModule := DllCall("LoadLibrary",Str,"winmm.dll")) {
        MsgBox Cannot load libray winmm.dll
        Exit
    }

}

midiOutOpen(uDeviceID = 0) {

    strh_midiout = 0000

    result := DllCall("winmm.dll\midiOutOpen", UInt,&strh_midiout, UInt,uDeviceID, UInt,0, UInt,0, UInt,0, UInt)

    If (result or ErrorLevel) {
        MsgBox There was an Error opening the midi port.`nError code %result%`nErrorLevel = %ErrorLevel%
        Return -1
    }

    Return UInt@(&strh_midiout)
}

midiOutShortMsg(h_midiout, MidiStatus, Param1, Param2) {

    result := DllCall("winmm.dll\midiOutShortMsg", UInt,h_midiout, UInt, MidiStatus|(Param1<<8)|(Param2<<16), UInt)
    
    If (result or ErrorLevel) {
        ; MsgBox There was an Error Sending the midi event: (%result%`, %ErrorLevel%)
        ; Return -1
    }
}

midiOutClose(h_midiout) {
    Loop 9 {

        result := DllCall("winmm.dll\midiOutClose", UInt,h_midiout)

        If !(result or ErrorLevel)
            Return

        Sleep 250
    }

    MsgBox Error in closing the midi output port. There may still be midi events being Processed.
    Return -1
}

MidiOutGetNumDevs() {
    Return DllCall("winmm.dll\midiOutGetNumDevs")
}

MidiOutNameGet(uDeviceID = 0) {

    VarSetCapacity(MidiOutCaps, 50, 0)
    OffsettoPortName := 8, PortNameSize := 32

    result := DllCall("winmm.dll\midiOutGetDevCapsA", UInt,uDeviceID, UInt,&MidiOutCaps, UInt, 50, UInt)

    If (result OR ErrorLevel) {
        MsgBox Error %result% (ErrorLevel = %ErrorLevel%) in retrieving the name of midi output ÞviceID
        Return -1
    }

    VarSetCapacity(PortName, PortNameSize)
    DllCall("RtlMoveMemory", Str,PortName, Uint,&MidiOutCaps+OffsettoPortName, Uint,PortNameSize)

    Return PortName
}

MidiOutsEnumerate() {

    local NumPorts, PortID
    MidiOutPortName =
    NumPorts := MidiOutGetNumDevs()

    Loop %NumPorts% {
        PortID := A_Index -1
        MidiOutPortName%PortID% := MidiOutNameGet(PortID)
    }

    Return NumPorts
}

UInt@(ptr) {
    Return *ptr | *(ptr+1) << 8 | *(ptr+2) << 16 | *(ptr+3) << 24
}

PokeInt(p_value, p_address) {
    DllCall("ntdll\RtlFillMemoryUlong", UInt,p_address, UInt,4, UInt,p_value)
}

h_midiout = 

UseMIDIDevice(deviceIndex) {

    global h_midiout

    OpenCloseMidiAPI()
    h_midiout := midiOutOpen(deviceIndex)
}

SendMIDIKeypress(cc, channel = 1) {
    
    global h_midiout

    midiOutShortMsg(h_midiout, (channel+175), cc, 127)
    midiOutShortMsg(h_midiout, (channel+175), cc, 0)
}

RunTests(deviceIndex) {
    TEST_CC := 50
    UseMIDIDevice(deviceIndex)
    SendMIDIKeypress(TEST_CC)
}

; Uncomment these two lines to test the module:

; TEST_DEVICE_INDEX := 2
; RunTests(TEST_DEVICE_INDEX)