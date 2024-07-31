using { /Fortnite.com/Characters }
using { /Fortnite.com/Devices }
using { /Fortnite.com/Game }
using { /Verse.org/Simulation }
using { /Verse.org/Simulation/Tags }
using { /UnrealEngine.com/Temporary/SpatialMath }


Practice_device := class(creative_device):
    @editable
    ThunderBolt:thunderbolt = thunderbolt{}

    OnBegin<override>()<suspends>:void =
        ThunderBolt.Initialize()

GetPlayers()<transacts>:[]player =
    Practice_device{}.GetPlayspace().GetPlayers()


thunderbolt := class<concrete>:
    @editable
    Rift:teleporter_device = teleporter_device{}
    # Input trigger to grant access to other input triggers.
    @editable
    InputLeftTrigger:input_trigger_device = input_trigger_device{}
    # Input trigger to activate teleportation.
    @editable
    InputSpacebar:input_trigger_device = input_trigger_device{}
    # Input triggers for player movement
    @editable
    InputLeft:input_trigger_device = input_trigger_device{}
    @editable
    InputRight:input_trigger_device = input_trigger_device{}
    @editable
    InputForward:input_trigger_device = input_trigger_device{}
    @editable
    InputBackward:input_trigger_device = input_trigger_device{}
    # Used to check if the player currently possesses a thunderbolt in their inventory.
    # It acts as a prerequisite for enabling teleportation
    @editable
    ConditionalButton:conditional_button_device = conditional_button_device{}
    # Manages the removal of thunderbolt from player inventory.
    # This device plays a key role in controlling the number of thunderbolt strikes a player can perform, which is tied to their class level abilities.
    # For instance, players of a certain level might be limited to using one or two thunderbolt strikes.
    @editable
    ItemRemover:item_remover_device = item_remover_device{}
    # Tracks player levels to adjust teleportation capabilities
    @editable
    LevelTracker:tracker_device = tracker_device{}
    # Teleportation distance range
    @editable
    TeleportDistance:type{x:float where x >= 500.0, x <= 1500.0} = 750.0

    # Logic to track what input player is holding
    var IsHoldingLeft:[agent]logic = map{}
    var IsHoldingRight:[agent]logic = map{}
    var IsHoldingForward:[agent]logic = map{}
    var IsHoldingBackward:[agent]logic = map{}
    # Logic to track is spacebar is double tapped
    var IsDoubleTapped:[agent]logic = map{}

    # Tracks if the player has recently teleported and is temporarily unable to do so again.
    var IsTeleportLocked:[player]logic = map{}
    # Maps players to their class levels
    var ClassLevelMap:[player]type{x:int where x >= 1, x <= 3} = map{}
    # Tracks the number of teleports a player has left
    var NumOfTeleportsMap:[player]int = map{}
    # Tracks the last time player was not holding thunderbolt
    var Time1Map:[agent]float = map{}
    # Tracks the last time player was holding thunderbolt
    var Time2Map:[agent]float = map{}
    # Subscription for player elimination events
    var EliminationSubscriptionMap:[player]?cancelable = map{}
    # Events triggered upon player elimination.
    var EliminationEventMap:[player]event() = map{}
    # Events triggered upon player pressing spacebar.
    var SpacebarEventMap:[player]event() = map{}
    # Events triggered upon thunderbolt animation ending.
    var EndSpacebarEventMap:[player]event() = map{}
    # Array of input triggers for easy access and management.
    var InputTriggers:[]input_trigger_device = array{}

    # Will need modification together with initialize function
    # Maybe thunderbolt only initializes if at least one player in the map has the perk
    # this should save cpu resources 
    CheckIfPlayerHasZeusPerk(Agent:agent):void =
        block:
            #if(Yes):
                for(InputTrigger:InputTriggers):
                    InputTrigger.Register(Agent)

    # Initializes the thunderbolt class by setting up input triggers and subscribing to their events.
    Initialize():void =
        set InputTriggers = array:
            InputLeft, InputRight, InputForward, InputBackward
        InputSpacebar.PressedEvent.Subscribe(OnPlayerPressingSpacebar)
        InputLeftTrigger.PressedEvent.Subscribe(OnPlayerPressingLeftTrigger)
        InputLeft.PressedEvent.Subscribe(OnPlayerPressingLeft)
        InputLeft.ReleasedEvent.Subscribe(OnPlayerReleasingLeft)
        InputRight.PressedEvent.Subscribe(OnPlayerPressingRight)
        InputRight.ReleasedEvent.Subscribe(OnPlayerReleasingRight)
        InputForward.PressedEvent.Subscribe(OnPlayerPressingForward)
        InputForward.ReleasedEvent.Subscribe(OnPlayerReleasingForward)
        InputBackward.PressedEvent.Subscribe(OnPlayerPressingBackward)
        InputBackward.ReleasedEvent.Subscribe(OnPlayerReleasingBackward)
        

        # This should be replaced for InitializePlayer(Player)
        # That way it prevents unnecessary background spawn loops for players that dont have this set up
        for:
            Player:GetPlayers()
            set EliminationEventMap[Player] = event(){}
            set SpacebarEventMap[Player] = event(){}
            set EndSpacebarEventMap[Player] = event(){}
        do:
            #for loop used for testing, Remove for loop for actual implementation
            for(InputTrigger:InputTriggers):
                InputTrigger.Register(Player)
            AssignPlayerPerkLevel(Player)
            spawn {CheckIfPlayerHasThunderBolt(Player)}

    # Sets up event handlers for elimination and spacebar actions, assigns class levels, and monitors for thunderbolt possession.
    InitializePlayer(Player:player):void =
        option:
            set EliminationEventMap[Player] = event(){}
            set SpacebarEventMap[Player] = event(){}
            set EndSpacebarEventMap[Player] = event(){}
        AssignPlayerPerkLevel(Player)
        spawn {CheckIfPlayerHasThunderBolt(Player)}

    # Sends a signal to the awaiting event
    OnPlayerEliminated(Result:elimination_result):void =
        if:
            Player := player[Result.EliminatedCharacter.GetAgent[]]
            Event := EliminationEventMap[Player]
        then {Event.Signal()}
                
    # Determines and assigns a perk level to each player based on their progress tracked by LevelTracker.
    # Perk level influences player abilities, such as the number of available teleports
    AssignPlayerPerkLevel(Player:player):void =
        Print("Thunder Level: {LevelTracker.GetValue(Player)}")
        option:
            case(LevelTracker.GetValue(Player)):
                3 => set ClassLevelMap[Player] = 3
                2 => set ClassLevelMap[Player] = 2
                _ => set ClassLevelMap[Player] = 1
            AssignNumberOfTeleports[Player]

    # Sets the maximum number of teleports a player can use based on their perk level.
    AssignNumberOfTeleports(Player:player)<transacts><decides>:void =
        case(ClassLevelMap[Player]):
            1 => set NumOfTeleportsMap[Player] = 0
            2 => set NumOfTeleportsMap[Player] = 1
            3 => set NumOfTeleportsMap[Player] = 3

    # Monitors whether the player has the Thunderbolt item and manages event subscriptions accordingly.
    # It continuously checks the player's inventory for the Thunderbolt.
    # Subscribes to the elimination event if the item is present, otherwise unsubscribes. 
    # Additionally, it manages input trigger registration based on item possession.
    CheckIfPlayerHasThunderBolt(Agent:agent)<suspends>:void =
        loop:
            Sleep(0.0)
            if(Player := player[Agent]):
                if:
                    ConditionalButton.HasAllItems[Player]
                    FortCharacter := Agent.GetFortCharacter[]
                then:
                    if(not EliminationSubscriptionMap[Player]?):
                        Subscription := FortCharacter.EliminatedEvent().Subscribe(OnPlayerEliminated)
                        option:
                            set EliminationSubscriptionMap[Player] = option{Subscription}
                        InputLeftTrigger.Register(Agent)
                        Print("Registered")           
                else:
                    if:
                        EliminationSubscriptionMap[Player]?.Cancel()  
                        set EliminationSubscriptionMap[Player] = false
                    then:
                        InputLeftTrigger.Unregister(Agent)
                        Print("Unregistered")
                if:
                    ConditionalButton.IsHoldingItem[Player]
                    set Time2Map[Player] = GetSimulationElapsedTime()
                else if{set Time1Map[Player] = GetSimulationElapsedTime()}
    
    # Difference between the time player is holding item (TIme2) and time player is not holding item (TIme1)
    TimeDifference(Agent:agent)<transacts><decides>:float = Time2Map[Agent] - Time1Map[Agent]
   
    # This function controls the player's ability to execute thunderbolt strikes by matching the action with its visual representation.
    # The duration of the Sleep function varies according to the player's class level, and is synchronized to the animation length of thunderbolt strikes.
    DisableInputTriggers(Agent:agent)<suspends>:void =
        if(Player := player[Agent]):
            race:
                # Awaits an elimination event
                if(Event := EliminationEventMap[Player]):
                    Event.Await() # If signaled, Stops Sleep Timer(wins race) if player is eliminated
                if(PlayerLevel := ClassLevelMap[Player]):
                    case(PlayerLevel):
                        1 => Sleep(1.7) # Allows for only 1 thunderbolt strike
                        2 => Sleep(2.3) # Allows for only 2 thunderbolt strikes
                        3 => Sleep(4.5) # Allows for all 3 thunderbolt strikes
                        _=> {}
            DisableInputTriggerAccess(Player)
            # Removes the thunderbolt item from the player's inventory
            ItemRemover.Remove(Agent)
            # Updates the number of available teleports based on the player's class level.
            option {AssignNumberOfTeleports[Player]}
    
    # Registers player from input triggers 
    EnableInputTriggerAccess(Player:player):void =
        InputSpacebar.Register(Player)

    # Unregisters player from input triggers and cancels any pending double tap checks.
    DisableInputTriggerAccess(Player:player):void =
        ReleaseWASD(Player)
        if(Event := EndSpacebarEventMap[Player]) {Event.Signal()}
        InputSpacebar.Unregister(Player)
 
    # This function checks if the necessary conditions are met for a player to teleport
    OnPlayerPressingLeftTrigger(Agent:agent):void =
        # 0.5 seconds is the approximate time between thunderbolt pull-out time and when it can be used
        if(TimeDifference[Agent] >= 0.5): 
            if:
                Player := player[Agent]
                ClassLevelMap[player[Agent]] > 1
            then {EnableInputTriggerAccess(Player)}
            spawn {DisableInputTriggers(Agent)}
            spawn {CheckForDoubleTaps(Agent)}

    # Teleports player to location. Allows for a limited amount of teleports
    (FortCharacter:fort_character).Teleport(Location:vector3)<suspends>:void =
        if(Player := player[FortCharacter.GetAgent[]]):
            defer:
                option{set IsTeleportLocked[Player] = false}
            if: 
                NumOfTeleportsMap[Player] > 0
                Rift.TeleportTo[Location, IdentityRotation()]
                set IsTeleportLocked[Player] = true
                set NumOfTeleportsMap[Player] -= 1
            then:
                Rift.Teleport(Player)
                Sleep(0.5)

    # Sets all movement logic to false
    ReleaseWASD(Player:player):void =
        OnPlayerReleasingLeft(Player, 0.0)
        OnPlayerReleasingRight(Player, 0.0)
        OnPlayerReleasingForward(Player, 0.0)
        OnPlayerReleasingBackward(Player, 0.0)

    # Registers that the left directional input is being held by the player.
    OnPlayerPressingLeft(Agent:agent):void =
        option {set IsHoldingLeft[Agent] = true}

    # Resets the left directional input when the player releases the control.
    OnPlayerReleasingLeft(Agent:agent, Time:float):void =
        option {set IsHoldingLeft[Agent] = false}

    # Registers that the right directional input is being held by the player.
    OnPlayerPressingRight(Agent:agent):void =
        option {set IsHoldingRight[Agent] = true}

    # Resets the right directional input when the player releases the control.
    OnPlayerReleasingRight(Agent:agent, Time:float):void =
        option {set IsHoldingRight[Agent] = false}

    # Registers that the forward directional input is being held by the player.
    OnPlayerPressingForward(Agent:agent):void =
        option {set IsHoldingForward[Agent] = true}

    # Resets the forward directional input when the player releases the control.
    OnPlayerReleasingForward(Agent:agent, Time:float):void =
        option {set IsHoldingForward[Agent] = false}

    # Registers that the backward directional input is being held by the player.
    OnPlayerPressingBackward(Agent:agent):void =
        option {set IsHoldingBackward[Agent] = true}

    # Resets the backward directional input when the player releases the control.
    OnPlayerReleasingBackward(Agent:agent, Time:float):void =
        option {set IsHoldingBackward[Agent] = false}

    # Triggers the spacebar event for a specific player.
    OnPlayerPressingSpacebar(Agent:agent):void =
        if(Event := SpacebarEventMap[Agent]) {Event.Signal()}

    # Monitors for double tap actions on the spacebar to initiate teleportation.
    # This asynchronous function listens for two consecutive spacebar presses within a short timeframe (0.3 seconds), and triggers teleportation if detected.
    # It checks the current directional inputs held by the player (forward, backward, left, right) to determine the teleportation direction.
    # If conflicting inputs are detected (e.g. both forward and backward are pressed), no action is taken.
    # The method supports single direction inputs and diagonal teleportation if the player is holding two non-conflicting directional inputs simultaneously (e.g. forward and left).
    CheckForDoubleTaps(Agent:agent)<suspends>:void =
        loop:
            if(Player := player[Agent]):
                Sleep(0.0)
                race:
                    if(Event := EndSpacebarEventMap[Player]):
                        Event.Await()
                        option {set IsDoubleTapped[Agent] = false}
                        return
                    if(Event := SpacebarEventMap[Player]):
                        Event.Await()
                        Event.Await()
                        option {set IsDoubleTapped[Agent] = true}
                    if(Event := SpacebarEventMap[Player]):
                        Event.Await()
                        Sleep(0.3)
                        option {set IsDoubleTapped[Agent] = false}
                # Teleport player if spacebar is double tapped
                if(IsDoubleTapped[Agent]?):
                    defer:
                        option {set IsDoubleTapped[Agent] = false}
                    # Conflicting inputs
                    if(IsHoldingForward[Agent]? and IsHoldingBackward[Agent]?):
                        # Do nothing
                        Print("Forward and Backward")
                    else if(IsHoldingLeft[Agent]? and IsHoldingRight[Agent]?):
                        # Do nothing
                        Print("Left and Right")
                    # Diagonal inputs
                    else if(IsHoldingForward[Agent]? and IsHoldingLeft[Agent]?):
                        TeleportForwardLeft(Agent)
                        Print("Forward and Left")
                    else if(IsHoldingForward[Agent]? and IsHoldingRight[Agent]?):
                        TeleportForwardRight(Agent)
                        Print("Forward and Right")
                    else if(IsHoldingBackward[Agent]? and IsHoldingLeft[Agent]?):
                        TeleportBackwardLeft(Agent)
                        Print("Backward and Left")
                    else if(IsHoldingBackward[Agent]? and IsHoldingRight[Agent]?):
                        TeleportBackwardRight(Agent)
                        Print("Backward and Right")
                    # Single direction inputs
                    else if(IsHoldingLeft[Agent]?):
                        TeleportLeft(Agent)
                        Print("Left")
                    else if(IsHoldingRight[Agent]?):
                        TeleportRight(Agent)
                        Print("Right")
                    else if(IsHoldingForward[Agent]?):
                        TeleportForward(Agent)
                        Print("Forward")
                    else if(IsHoldingBackward[Agent]?):
                        TeleportBackward(Agent)
                        Print("Backward")
                    # No directional input
                    else {TeleportForwardLeft(Agent)}

    # Functions made by Steinn & CHATGPT/Verse Coder
    # The functions check if teleportation is currently allowed (not "IsTeleportLocked") to prevent consecutive teleportations without cooldown.
    # Teleports player to the left direction relative to their current orientation.
    TeleportLeft(Agent:agent):void =
        if:
            not IsTeleportLocked[Agent]?
            FortCharacter := Agent.GetFortCharacter[]
            Rotation := FortCharacter.GetTransform().Rotation
            LeftVector := Rotation.GetLocalRight() * -1.0
            MoveVector := LeftVector * TeleportDistance
            Location := FortCharacter.GetTransform().Translation + MoveVector
        then {spawn {FortCharacter.Teleport(Location)}}

    # Teleports player to the right direction relative to their current orientation.
    TeleportRight(Agent:agent):void =
        if:
            not IsTeleportLocked[Agent]?
            FortCharacter := Agent.GetFortCharacter[]
            Rotation := FortCharacter.GetTransform().Rotation
            RightVector := Rotation.GetLocalRight()
            MoveVector := RightVector * TeleportDistance
            Location := FortCharacter.GetTransform().Translation + MoveVector
        then {spawn {FortCharacter.Teleport(Location)}}

    # Teleports player to the forward direction relative to their current orientation.
    TeleportForward(Agent:agent):void =
        if:
            not IsTeleportLocked[Agent]?
            FortCharacter := Agent.GetFortCharacter[]
            Rotation := FortCharacter.GetTransform().Rotation
            ForwardVector := Rotation.GetLocalForward()
            MoveVector := ForwardVector * TeleportDistance
            Location := FortCharacter.GetTransform().Translation + MoveVector
        then {spawn {FortCharacter.Teleport(Location)}}

    # Teleports player to the backward direction relative to their current orientation.
    TeleportBackward(Agent:agent):void =
        if:
            not IsTeleportLocked[Agent]?
            FortCharacter := Agent.GetFortCharacter[]
            Rotation := FortCharacter.GetTransform().Rotation
            BackwardVector := Rotation.GetLocalForward() * -1.0
            MoveVector := BackwardVector * TeleportDistance
            Location := FortCharacter.GetTransform().Translation + MoveVector
        then {spawn {FortCharacter.Teleport(Location)}}

    # Teleports player to the forward-left direction relative to their current orientation.
    TeleportForwardLeft(Agent:agent):void =
        if:
            not IsTeleportLocked[Agent]?
            FortCharacter := Agent.GetFortCharacter[]
            Rotation := FortCharacter.GetTransform().Rotation
            ForwardVector := Rotation.GetLocalForward()
            LeftVector := Rotation.GetLocalRight() * -1.0
            NormalizedVector := (ForwardVector + LeftVector).Normalize()
            MoveVector := NormalizedVector * TeleportDistance
            Location := FortCharacter.GetTransform().Translation + MoveVector
        then {spawn {FortCharacter.Teleport(Location)}}

    # Teleports player to the forward-right direction relative to their current orientation.
    TeleportForwardRight(Agent:agent):void =
        if:
            not IsTeleportLocked[Agent]?
            FortCharacter := Agent.GetFortCharacter[]
            Rotation := FortCharacter.GetTransform().Rotation
            ForwardVector := Rotation.GetLocalForward()
            RightVector := Rotation.GetLocalRight()
            NormalizedVector := (ForwardVector + RightVector).Normalize()
            MoveVector := NormalizedVector * TeleportDistance
            Location := FortCharacter.GetTransform().Translation + MoveVector
        then {spawn {FortCharacter.Teleport(Location)}}

    # Teleports player to the backward-left direction relative to their current orientation.
    TeleportBackwardLeft(Agent:agent):void =
        if:
            not IsTeleportLocked[Agent]?
            FortCharacter := Agent.GetFortCharacter[]
            Rotation := FortCharacter.GetTransform().Rotation
            BackwardVector := Rotation.GetLocalForward() * -1.0
            LeftVector := Rotation.GetLocalRight() * -1.0
            NormalizedVector := (BackwardVector + LeftVector).Normalize()
            MoveVector := NormalizedVector * TeleportDistance
            Location := FortCharacter.GetTransform().Translation + MoveVector
        then {spawn {FortCharacter.Teleport(Location)}}

    # Teleports player to the backward-right direction relative to their current orientation.
    TeleportBackwardRight(Agent:agent):void =
        if:
            not IsTeleportLocked[Agent]?
            FortCharacter := Agent.GetFortCharacter[]
            Rotation := FortCharacter.GetTransform().Rotation
            BackwardVector := Rotation.GetLocalForward() * -1.0
            RightVector := Rotation.GetLocalRight()
            NormalizedVector := (BackwardVector + RightVector).Normalize()
            MoveVector := NormalizedVector * TeleportDistance
            Location := FortCharacter.GetTransform().Translation + MoveVector
        then {spawn {FortCharacter.Teleport(Location)}}

    # Calculates the magnitude(length) of a vector
    VectorMagnitude(Vector:vector3)<transacts>:float =
        Sqrt(Vector.X * Vector.X + Vector.Y * Vector.Y + Vector.Z * Vector.Z)

    # Function to normalize a vector3
    (Vector:vector3).Normalize()<transacts>:vector3 =
        Magnitude := VectorMagnitude(Vector)
        if(Magnitude > 0.0):
            # Avoid division by zero by ensuring magnitude is greater than zero
            vector3{X := Vector.X / Magnitude, Y := Vector.Y / Magnitude, Z := Vector.Z / Magnitude}
        # Return the original vector if the magnitude is zero; alternatively, handle this case as needed
        else {Vector}
            
            


        