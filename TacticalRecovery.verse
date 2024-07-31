using { /Fortnite.com/Characters }
using { /Fortnite.com/Devices }
using { /Fortnite.com/Game }
using { /Verse.org/Simulation }
using { /Verse.org/Simulation/Tags }
using { /UnrealEngine.com/Temporary/SpatialMath }


TacticalRecoveryManager := class(creative_device):
    @editable
    TacticalRecovery:tact_recovery = tact_recovery{}
    @editable
    Button:button_device = button_device{}

    OnBegin<override>()<suspends>:void =
        TacticalRecovery.Initialize()
        Button.InteractedWithEvent.Subscribe(OnPlayerPressinghButton)

    OnPlayerPressinghButton(Agent:agent):void =
        if(FortChar := Agent.GetFortCharacter[]):
            FortChar.Damage(20.0)

GetPlayersA()<transacts>:[]player =
    TacticalRecoveryManager{}.GetPlayspace().GetPlayers()

tact_recovery := class<concrete>:
    @editable
    LevelTracker:tracker_device = tracker_device{}

    var DamagedEventMap:[player]event() = map{}
    var ShieldDamagedEventMap:[player]event() = map{}
    #DefaultHealingRate:float = 0.02

    Initialize():void =
        for:
            Player:GetPlayersA()
            FortChar := Player.GetFortCharacter[]
            set DamagedEventMap[Player] = event(){}
            set ShieldDamagedEventMap[Player] = event(){}
        # DamagedEvent() is for health only. DamagedShieldEvent() is for shield
        do:
            FortChar.DamagedEvent().Subscribe(OnPlayerDamaged)
            if(LevelTracker.GetValue() = 5):
                Print("Level 5")
                FortChar.DamagedShieldEvent().Subscribe(OnPlayerShieldDamaged)

    OnPlayerDamaged(Result:damage_result):void =
        Print("PlayerDamaged")
        if:
            FortChar := fort_character[Result.Target]
            Player := player[FortChar.GetAgent[]]
            Event := DamagedEventMap[Player]
        then:
            Event.Signal()
            Print("About to Start Heal Function")
            spawn {Heal(Player)}
            
    OnPlayerShieldDamaged(Result:damage_result):void =
        Print("PlayerShieldDamaged")
        if:
            FortChar := fort_character[Result.Target]
            Player := player[FortChar.GetAgent[]]
            Event := ShieldDamagedEventMap[Player]
        then:
            Event.Signal()
            Print("About to Start HealShield Function")
            spawn {HealShield(Player)}

    CalculateHealingInterval(Value:float):float =
        0.02 / (Value / 100.0)

    Heal(Player:player)<suspends>:void =
        Delay := case(LevelTracker.GetValue()):
            1 => 4.0
            2 => 3.0
            3 => 2.0
            4 => 1.0
            _ => 0.0
        Rate := case(LevelTracker.GetValue()):
            5 => CalculateHealingInterval(50.0)
            _ => CalculateHealingInterval(75.0)
        race:
            block:
                Print("Level {LevelTracker.GetValue()} Timer: {Delay}")
                Sleep(Delay)
                Print("Rate: {Rate}")
                loop:
                    Sleep(Rate)
                    if:
                        FortChar := Player.GetFortCharacter[]
                        FortChar.GetHealth() < FortChar.GetMaxHealth()
                    then {FortChar.Heal(1.0)}
                    else {break}
                Print("Healing Complete")     
            if(Event := DamagedEventMap[Player]):
                Event.Await()
                Print("Healing Interrupted by Damage")

    HealShield(Player:player)<suspends>:void =
        Rate := CalculateHealingInterval(5.0)
        race:
            block:
                Print("Rate: {Rate}")
                loop:
                    Sleep(Rate)
                    if:
                        FortChar := Player.GetFortCharacter[]
                        FortChar.GetShield() < FortChar.GetMaxShield()
                    then {FortChar.SetShield(FortChar.GetShield() + 1.0)}
                    else {break}
                Print("Shield Healing Complete") 
            if(Event := ShieldDamagedEventMap[Player]):
                Event.Await()
                Print("Shield Healing Interrupted by Damage")
