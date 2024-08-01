using { /Fortnite.com/Characters }
using { /Fortnite.com/Devices }
using { /Fortnite.com/Game }
using { /Verse.org/Simulation }
using { /Verse.org/Simulation/Tags }
using { /UnrealEngine.com/Temporary/SpatialMath }


SpeedyRecoveryManager := class(creative_device):
    @editable
    SpeedyRecovery:speedy_recovery = speedy_recovery{}
    @editable
    Button:button_device = button_device{}


    OnBegin<override>()<suspends>:void =
        SpeedyRecovery.Initialize()
        Button.InteractedWithEvent.Subscribe(OnPlayerPressinghButton)

    OnPlayerPressinghButton(Agent:agent):void =
        if(FortChar := Agent.GetFortCharacter[]):
            FortChar.Damage(20.0)

GetPlayersB()<transacts>:[]player =
    SpeedyRecoveryManager{}.GetPlayspace().GetPlayers()

speedy_recovery := class<concrete>:
    @editable
    LevelTracker:tracker_device = tracker_device{}

    var DamagedEventMap:[player]event() = map{}

    Initialize():void =
        for:
            Player:GetPlayersB()
            FortChar := Player.GetFortCharacter[]
            set DamagedEventMap[Player] = event(){}
        # DamagedEvent() is for health only. DamagedShieldEvent() is for shield
        do {FortChar.DamagedEvent().Subscribe(OnPlayerDamaged)}

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

    CalculateHealingInterval(Value:float):float =
        0.02 / (Value / 100.0)

    Heal(Player:player)<suspends>:void =
        Delay := case(LevelTracker.GetValue(Player)):
            1 => 4.0
            2 => 2.5
            3 => 1.5
            _ => 1.0
        Rate := case(LevelTracker.GetValue(Player)):
            4 => CalculateHealingInterval(200.0)
            _ => CalculateHealingInterval(150.0)
        race:
            block:
                Print("Level {LevelTracker.GetValue(Player)} Timer: {Delay}")
                Sleep(Delay)
                Print("Rate: {Rate}")
                loop:
                    Sleep(Rate)
                    if:
                        LevelTracker.GetValue(Player) = 4
                        FortChar := Player.GetFortCharacter[]
                        FortChar.GetHealth() < 0.25 * FortChar.GetMaxHealth()
                    then:
                        FortChar.SetHealth(FortChar.GetMaxHealth())
                        break
                    else if:
                        FortChar := Player.GetFortCharacter[]
                        FortChar.GetHealth() < FortChar.GetMaxHealth()
                    then {FortChar.Heal(1.0)}
                    else {break}
                Print("Healing Complete")     
            if(Event := DamagedEventMap[Player]):
                Event.Await()
                Print("Healing Interrupted by Damage")
