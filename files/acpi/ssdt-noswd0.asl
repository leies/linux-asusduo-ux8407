DefinitionBlock ("", "SSDT", 2, "UX8407", "NOSWD0", 0x00000001)
{
    External (_SB_.PC00.HDAS.IDA_.SNDW.SWD0, DeviceObj)

    Scope (_SB.PC00.HDAS.IDA.SNDW.SWD0)
    {
        Method (_STA, 0, NotSerialized)
        {
            Return (Zero)
        }
    }
}
