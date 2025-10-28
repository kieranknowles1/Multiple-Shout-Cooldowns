Scriptname MSCDMCMScript extends mcm_configbase

; Variable DOES NOT have any gameplay impact, it is used only in the MCM
GlobalVariable property MSCDCurrentSlots Auto
MSCDPlayerAlias property PlayerScript Auto

Function UpdateDisplay()
    MSCDCurrentSlots.SetValue(PlayerScript.GetMaxCooldowns())
EndFunction

Event OnSettingChange(string a_ID)
    UpdateDisplay()
EndEvent

Event OnConfigOpen()
    UpdateDisplay()
EndEvent

Event OnInit()
    UpdateDisplay()
EndEvent

Event OnConfigClose()
    UpdateDisplay()
EndEvent
