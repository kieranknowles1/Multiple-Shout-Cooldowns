Scriptname MSCDPlayerAlias extends ReferenceAlias
{Main script for Multiple Shout Cooldowns, attached to the player.}

Actor Property PlayerRef Auto

GlobalVariable Property MSCDWordsUnlockedPerCooldown Auto

Message Property MSCDMessageNumAvailable Auto
{"%d of %d cooldowns available."}

float property EMPTY_SLOT = -1.0 autoreadonly
{The value that represents an empty slot in the cooldown array.}
int property UPDATE_FREQUENCY = 1 autoreadonly
{The delay between each update, in seconds.}

; This script, in effect, turns the vanilla slot plus a cooldown array into an
; unsorted priority queue, all operations are O(n) since we have to walk the array.
; The exception to this is our vanilla slot, which is always at the front of the
; queue and acts as an overflow when no cooldowns are available.
float[] cooldowns

Event OnInit()
    cooldowns = new Float[128]


    int i = 0
    while i < cooldowns.Length - 1
        cooldowns[i] = EMPTY_SLOT
        i += 1
    endwhile
endevent

int function GetMaxCooldowns()
{Get the maximum number of cooldowns the player can have, based on their progress.}
    int wordsUnlocked = Game.QueryStat("Words of Power Unlocked")
    int wordsPerCooldown = MSCDWordsUnlockedPerCooldown.GetValue() as int

    return 1 + (wordsUnlocked / wordsPerCooldown)
endfunction

int function GetShortestCooldownIndex()
{Get the index of the shortest cooldown, or -1 if there is nothing queued.}
    float shortest = 999999.0
    int shortestIndex = -1

    int i = 0
    while i < cooldowns.Length
        if (cooldowns[i] != EMPTY_SLOT && cooldowns[i] < shortest)
            shortest = cooldowns[i]
            shortestIndex = i
        endif
        i += 1
    endwhile

    return shortestIndex
endfunction

int function GetNextFreeSlot()
{Get the index of the next free slot}
    int i = 0
    while i < cooldowns.Length
        if (cooldowns[i] == EMPTY_SLOT)
            return i
        endif
        i += 1
    endwhile

    ; Should never happen
    Debug.MessageBox("You broke it. Stop yelling for a bit.")
    return -1
endfunction

int function GetUsedSlotCount()
{Get the number of slots in use, including the vanilla one}

    int used = 0
    int i = 0
    while i < cooldowns.Length
        if (cooldowns[i] != EMPTY_SLOT)
            used += 1
        endif
        i += 1
    endwhile

    ; See if the vanilla shout is on cooldown
    if (PlayerRef.GetVoiceRecoveryTime() > 0)
        used += 1
    endif

    return used
endfunction

event OnUpdate()
    ; Check if the vanilla shout cooldown is done, if not, let vanilla handle it
    if (PlayerRef.GetVoiceRecoveryTime() > 0)
        RegisterForSingleUpdate(UPDATE_FREQUENCY)
        return
    endif

    ; Get the next cooldown to reduce
    int shortestIndex = GetShortestCooldownIndex()
    ; Everything is done, nothing to do until the player shouts again
    if (shortestIndex == -1)
        UnregisterForUpdate()
        return
    endif

    ; Reduce the cooldown
    cooldowns[shortestIndex] = cooldowns[shortestIndex] - UPDATE_FREQUENCY
    ; Cooldown is done, free up the slot and tell the player
    if (cooldowns[shortestIndex] <= 0)
        cooldowns[shortestIndex] = EMPTY_SLOT
        ShowAvailableSlots()
    endif

    ; Register for the next update
    RegisterForSingleUpdate(UPDATE_FREQUENCY)
endevent

function ShowAvailableSlots()
    int usedSlots = GetUsedSlotCount()
    int totalSlots = GetMaxCooldowns()

    MSCDMessageNumAvailable.Show(totalSlots-usedSlots, totalSlots)
endfunction

function OnPlayerShout()
    int usedSlots = GetUsedSlotCount()
    int totalSlots = GetMaxCooldowns()
    float recoveryTime = PlayerRef.GetVoiceRecoveryTime()

    ; Tell the player how many slots are available no matter what
    ; Order doesn't matter, as the vanilla slot is counted in GetUsedSlotCount
    ShowAvailableSlots()

    ; If any slots are available, move the vanilla slot to the first available slot
    if (usedSlots < totalSlots)
        int nextSlot = GetNextFreeSlot()
        cooldowns[nextSlot] = recoveryTime
        PlayerRef.SetVoiceRecoveryTime(0)
        RegisterForSingleUpdate(UPDATE_FREQUENCY)
    else
        ; If all slots are full, and the new cooldown is longer than the shortest one, swap them
        int shortestIndex = GetShortestCooldownIndex()
        if shortestIndex == -1
            return
        endif

        if recoveryTime > cooldowns[shortestIndex]
            float temp = cooldowns[shortestIndex]
            cooldowns[shortestIndex] = recoveryTime
            PlayerRef.SetVoiceRecoveryTime(temp)
            ; Updates are already registered, so no need to do it again
        endif
    endif
endfunction

int previousTimesShouted = 0
event OnSpellCast(Form akSpell)
    int newTimesShouted = Game.QueryStat("Times Shouted")

    if (newTimesShouted != previousTimesShouted)
        ; It's a shout and not a fireball or something
        previousTimesShouted = newTimesShouted
        OnPlayerShout()
    endif
endevent
