using { /Fortnite.com/Devices }
using { /Verse.org/Random }
using { /Verse.org/Simulation }
using { /UnrealEngine.com/Temporary/SpatialMath }

# RNG function using a seed
LCG(Seed:int)<transacts><decides>:int =
    # Use a linear congruential generator (LCG) to generate a pseudo-random number
    Multiplier := 1664525
    Increment := 1013904223
    Modulus := 4294967296 # 2^32
    # Apply the LCG formula to generate the next value in the sequence
    Mod[Seed * Multiplier + Increment, Modulus]

# Mersenne Twister RNG implementation
MersenneTwister(Seed:int)<transacts><decides>:[]int =
    # Constants for the Mersenne Twister
    N := 624
    M := 397
    A := 0x9908B0DF  # Matrix A coefficient
    U := 11
    S := 7
    B := 0x9D2C5680
    T := 15
    C := 0xEFC60000
    L := 18
    F := 1812433253
    R := 31

    # Initialize the state array
    var MT:[]int = for(Index := 1..N) do 0
    set MT[0] = Seed
    # Fill the state array using an initialization function
    for(Index := 1..N - 1):
        Temp := Mod[(F * BitwiseXor(MT[Index - 1], RightShift(MT[Index - 1], (R - 1))) + Index), 4294967296]
        set MT[Index] = Temp

    var Y:int = 0
    # Generate N words (to fill the MT state array with random values)
    for(Index := 0..N - 1):
        Temp1 := BitwiseAnd(MT[Index], 0x80000000) + BitwiseAnd(MT[Mod[(Index + 1), N]], 0x7FFFFFFF)
        set Y = Temp1
        Temp2 := BitwiseXor(MT[Mod[(Index + M), N]], RightShift(Y, 1))
        set MT[Index] = Temp2
        if(Mod[Y, 2] <> 0):
            Temp3 := BitwiseXor(MT[Index], A)
            set MT[Index] = Temp3

    # Apply tempering transformations to all elements
    for(Index := 0..N - 1):
        Temp4 := MT[Index]
        set Y = Temp4
        set Y = BitwiseXor(Y, RightShift(Y, U))
        set Y = BitwiseXor(Y, BitwiseAnd(LeftShift(Y, S), B))
        set Y = BitwiseXor(Y, BitwiseAnd(LeftShift(Y, T), C))
        set Y = BitwiseXor(Y, RightShift(Y, L))
        Temp5 := Mod[Y, 4294967296]
        set MT[Index] = Temp5
    # Return the entire array of tempered random values
    return MT


# Bitwise operator functions
BitwiseAnd(Value1:int, Value2:int)<transacts>:int =
    # Function to perform bitwise AND operation between two integers
    var Result:int = 0
    var Bit:int = 1
    var A:int = Value1
    var B:int = Value2
    loop:
        if(A > 0 or B > 0):
            if(Mod[A, 2] = 1 and Mod[B, 2] = 1):
                set Result += Bit
            set A = RightShift(A, 1)
            set B = RightShift(B, 1)
            set Bit = LeftShift(Bit, 1)
        else {break}
    return Result

BitwiseOr(Value1:int, Value2:int)<transacts>:int =
    # Function to perform bitwise OR operation between two integers
    var Result:int = 0
    var Bit:int = 1
    var A:int = Value1
    var B:int = Value2
    loop:
        if(A > 0 or B > 0):
            if(Mod[A, 2] = 1 or Mod[B, 2] = 1):
                set Result += Bit
            set A = RightShift(A, 1)
            set B = RightShift(B, 1)
            set Bit = LeftShift(Bit, 1)
        else {break}
    return Result

BitwiseXor(Value1:int, Value2:int)<transacts>:int =
    # Function to perform bitwise XOR operation between two integers
    var Result:int = 0
    var Bit:int = 1
    var A:int = Value1
    var B:int = Value2
    loop:
        if(A > 0 or B > 0):
            if(Mod[A, 2] <> Mod[B, 2]):
                set Result += Bit
            set A = RightShift(A, 1)
            set B = RightShift(B, 1)
            set Bit = LeftShift(Bit, 1)
        else {break}
    return Result

BitwiseNot(Value:int)<transacts>:int =
    # Function to perform bitwise NOT operation
    var Result:int = 0
    var Bit:int = 1
    var A:int = Value
    loop:
        if(A > 0):
            if(Mod[A, 2] = 0):
                set Result += Bit
            set A = RightShift(A, 1)
            set Bit = LeftShift(Bit, 1)
        else {break}
    return Result

LeftShift(A:int, ShiftBy:int)<transacts>:int =
    # Function to perform left bitwise shift operation
    var Result:int = A
    for (Index := 0..ShiftBy - 1):
        set Result *= 2
    return Result

RightShift(A:int, ShiftBy:int)<transacts>:int =
    # Function to perform right bitwise shift operation
    var Result:int = A
    for(Index := 0..ShiftBy - 1, Temp := Floor(Result / 2)):
        set Result = Temp
    return Result

# Function to convert a string to an integer
Int(String:string)<transacts><decides>:int =
    var Result:int = 0
    var Negative:logic = false
    var Index:int = 0

    # Check if the number is negative
    if(String[0] = '-'):
        set Negative = true
        set Index += 1

    # Iterate through each character in the string
    for(I := Index..String.Length - 1):
        CharValue := String[I]
        DigitValue:?int = case(CharValue):
            '0' => option{0}
            '1' => option{1}
            '2' => option{2}
            '3' => option{3}
            '4' => option{4}
            '5' => option{5}
            '6' => option{6}
            '7' => option{7}
            '8' => option{8}
            '9' => option{9}
            _ => false
        Value := DigitValue?
        set Result = Result * 10 + Value
    # Apply negative sign if necessary
    if(Negative?) then set Result = -Result
    return Result

# Class for item placement within the game
item_placer := class<unique>:
    Device:item_placer_device
    Location:vector3

    # Method to reset the item placer to its original location
    Reset()<transacts><decides>:void =
        Device.TeleportTo[Location, rotation{}]

# RNG class to handle the placement of items
RNG := class<concrete>:
    @editable
    ItemPlacerDevices:[]item_placer_device = array{}
    @editable
    NumberofDailyItems:int = 3
    @editable
    InitialItemPosition:vector3 = vector3:
        X := 0.0, Y := 0.0, Z := 0.0
    @editable
    Offset:float = 0.0

    var ItemPlacers:[]item_placer = array{}
    var DailyItemPlacers:[]item_placer = array{}

    # Block to initialize item placers from given devices
    block:
        set ItemPlacers =
            for(Device:ItemPlacerDevices):
                item_placer:
                    Device := Device
                    Location := Device.GetTransform().Translation

    # Method to start the RNG item placement process
    Start()<suspends>:void =  
        loop:
            # Get current date and time
            Date := date_time_provider{}.GetDateAndTime()
            # Format the day with leading zeros if necessary
            Day := if(Date.day < 10) then "0{Date.day}" else "{Date.day}"
            Month := Date.month; Year := Date.year
            String := "{Month}" + "{Day}" + "{Year}"
            Print(String)

            Print("RNG STARTED")
            option:
                # Generate seed from the date string
                Seed := Int[String]
                MTArray := MersenneTwister[Seed]
                var Index:int = 0
                var ItemIndices:[]int = array{}
                # Select random items without duplication
                for(I := 1..NumberofDailyItems):
                    loop:
                        defer {set Index += 1}
                        if:
                            RandomValue := MTArray[Index]
                            ItemIndex := Mod[RandomValue, ItemPlacers.Length] 
                            not ItemIndices.Find[ItemIndex]
                            set ItemIndices += array{ItemIndex}
                        then break
                        else Print("Duplicate Found")
                # Store selected item placers
                set DailyItemPlacers += array:
                    ItemPlacers[ItemIndices[0]], ItemPlacers[ItemIndices[1]], ItemPlacers[ItemIndices[2]]
                # Set initial position for item placement
                var Position:vector3 = InitialItemPosition
                # Place items at specified positions
                for(ItemPlacer:DailyItemPlacers, ItemPlacer.Device.TeleportTo[Position, rotation{}]):
                    set Position = vector3:
                        X := Position.X + Offset, Y := Position.Y, Z := Position.Z
                Print("{ItemIndices[0]} : {ItemIndices[1]} : {ItemIndices[2]}")
                Print("Seed = {Seed}\nRandom Value := {MTArray[0]}")
            Print("RNG ENDED")

            # Determine time until next midnight
            if(Delay := TimeToNextMidnight[], Delay <= 18000): # 18000s = 5hrs
                Print("Waiting for {Delay} seconds")
                Sleep(Delay * 1.0)
                Print("It's 12am UTC\n Resetting Items")
                # Reset daily item placers at midnight
                for:
                    ItemPlacer:DailyItemPlacers
                    ItemPlacer.Reset[]
                do {Print("Item Placer Reset")}
                set DailyItemPlacers = array{}
            else {Print("Not Waiting. Server will expire before 12am UTC"); break} 

    # Method to calculate time until next midnight
    TimeToNextMidnight()<transacts><decides>:int =
        CurrentTime := Floor[GetSecondsSinceEpoch()]
        # Find how many seconds have passed since today's 12am UTC
        SecondsPassedToday := Mod[CurrentTime, 86400] 
        NextMidnightEpoch := 86400 - SecondsPassedToday
