using { /Fortnite.com/Devices }
using { /Verse.org/Simulation }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /Verse.org/Random }

time_zone := enum<persistable>:
    UTC, PT, MT, CT, ET, GMT, CET, EET, MSK, IST, CST, JST, AET, BRT

clock_system := enum<persistable>:
    Hour_12, Hour_24

ToString(TimeZone:time_zone):string =
    case(TimeZone):
        time_zone.UTC => "Coordinated Universal Time"
        time_zone.PT => "Pacific Time"
        time_zone.MT => "Mountain Time"
        time_zone.CT => "Central Time"
        time_zone.ET => "Eastern Time"
        time_zone.GMT => "Greenwich Mean Time"
        time_zone.CET => "Central European Time"
        time_zone.EET => "Eastern European Time"
        time_zone.MSK => "Moscow Time"
        time_zone.IST => "India Standard Time"
        time_zone.CST => "China Standard Time"
        time_zone.JST => "Japan Standard Time"
        time_zone.AET => "Australian Eastern Time"
        time_zone.BRT => "Brasília Time"

date_time := struct:
    year: int
    month: int
    day: int
    hour: int
    minute: int
    second: int

date_time_provider := class:
    # Made By Himez
    # Discord : Himez
    # Twitter : @HimezUEFN
    # This class is used to get the current date and time from the seconds since epoch

    # Constants
    SecondsInMinute: int = 60
    SecondsInHour: int = 3600
    SecondsInDay: int = 86400
    SecondsInYear: int = 31536000
    SecondsInLeapYear: int = 31622400

    # Init date and time variables
    var Year: int = 1970
    var Month: int = 1
    var Day: int = 1
    var Hour: int = 0
    var Minute: int = 0
    var Second: int = 0
    var EpochSeconds: int = 0

    TimeZone:time_zone = time_zone.UTC
    ClockSystem:clock_system = clock_system.Hour_12

    # Get the current seconds since epoch
    GetMonthName<public>(MonthInt: int): string =
        Months: []string = array{"January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"}
        if(MonthName := Months[MonthInt - 1]) then return MonthName else return "Invalid Month"

    # Get Date and Time method (Modified by Steinn)
    GetDateAndTime<public>(): date_time =
        ResetDateAndTime()
        CurrentTimeZoneEpochSeconds :=
            if(TimeZone = time_zone.UTC) then GetSecondsSinceEpoch()
            else {GetSecondsSinceEpoch() + GetTimeZoneSecondsForDate()}
        if (Temp := Floor[CurrentTimeZoneEpochSeconds]) then set EpochSeconds = Temp
        CalculateDateAndTime()
        return date_time{year := Year, month := Month, day := Day, hour := Hour, minute := Minute, second := Second}

    # Calculate day and time
    CalculateDateAndTime<private>(): void =
        CalculateYear()
        CalculateDay()
        CalculateMonth()
        CalculateHour()
        CalculateMinute()
        CalculateSecond()

    # Reset date and time
    ResetDateAndTime<private>(): void =
        set Year = 1970
        set Month = 1
        set Day = 1
        set Hour = 0
        set Minute = 0
        set Second = 0
        set EpochSeconds = 0

    # Determine the year
    CalculateYear<private>(): void =
        loop:
            LeapYear := IsLeapYear(Year)
            SecondsInCurrentYear := if (LeapYear?) then SecondsInLeapYear else SecondsInYear
            if(EpochSeconds >= SecondsInCurrentYear):
                set EpochSeconds -= SecondsInCurrentYear
                set Year += 1
            else {break}

    # Helper function to determine if a year is a leap year
    IsLeapYear<private>(YearInt:int)<transacts>:logic =
        if(Mod[YearInt, 4] = 0 and Mod[YearInt, 100] <> 0 or Mod[YearInt, 400] = 0) then return true else return false

    # Calculate day
    CalculateDay<private>(): void =
        set Day = if(Temp := Floor(EpochSeconds / SecondsInDay)) then Temp + 1 else 1
        if(Temp := Mod[EpochSeconds, SecondsInDay]) then set EpochSeconds = Temp  # Calculate remaining seconds for time of day

    # Calculate month
    CalculateMonth<private>(): void =
        var DaysInMonth:[]int = array{31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31}
        LeapYear := IsLeapYear(Year)  # Check if it is a leap year
        if(LeapYear?) then if (set DaysInMonth[1] = 29 ): # Adjust February for leap year
        loop:
            if(Day > DaysInMonth[Month - 1]):
                if(set Day -= DaysInMonth[Month - 1]):
                set Month += 1
            else {break}

    # Calculate hour
    CalculateHour<private>(): void =
        set Hour = if(Temp := Floor(EpochSeconds / SecondsInHour)) then Temp else 0
        set EpochSeconds = if(Temp := Mod[EpochSeconds, SecondsInHour]) then Temp else 0  # Calculate remaining seconds

    # Calculate minute
    CalculateMinute<private>(): void =
        set Minute = if(Temp := Floor(EpochSeconds / SecondsInMinute)) then Temp else 0
        set EpochSeconds = if(Temp := Mod[EpochSeconds, SecondsInMinute]) then Temp else 0  # Calculate remaining seconds

    # Remaining seconds
    CalculateSecond<private>(): void =
        set Second += EpochSeconds
        set EpochSeconds = 0

    ################################################################################################################################
    # Made By Steinn
    # Discord : steinnfn
    # Twitter : @Steinn_fn

    GetTimeZoneSeconds()<transacts>:float =
        case(TimeZone):
            time_zone.UTC => 0.0
            time_zone.PT => -8.0 * 3600
            time_zone.MT => -7.0 * 3600
            time_zone.CT => -6.0 * 3600
            time_zone.ET => -5.0 * 3600
            time_zone.GMT => 0.0 * 3600
            time_zone.CET => 1.0 * 3600
            time_zone.EET => 2.0 * 3600
            time_zone.MSK => 3.0 * 3600
            time_zone.IST => 5.5 * 3600
            time_zone.CST => 8.0 * 3600
            time_zone.JST => 9.0 * 3600
            time_zone.AET => 10.0 * 3600
            time_zone.BRT => -3.0 * 3600

    # New method to get time zone offset including DST
    GetTimeZoneSecondsForDate():float =
        defer {ResetDateAndTime()}
        BaseOffset := GetTimeZoneSeconds()
        CurrentTimeZoneEpochSeconds := GetSecondsSinceEpoch() + BaseOffset
        if(Temp := Floor[CurrentTimeZoneEpochSeconds]) then set EpochSeconds = Temp
        CalculateDateAndTime()
        if(IsDaylightSavingTime()?):
            # Adjust the offset for DST (+1 hour)
            return BaseOffset + 3600.0
        return BaseOffset

    # Method to determine if DST is in effect
    IsDaylightSavingTime()<transacts>:logic =
        if(array{time_zone.PT, time_zone.MT, time_zone.CT, time_zone.ET}.Find[TimeZone]):
            return IsUSDaylightSavingTime(Year, Month, Day, Hour)
        else if (array{time_zone.CET, time_zone.EET, time_zone.MSK}.Find[TimeZone]):
            return IsEuropeanDaylightSavingTime(Year, Month, Day, Hour)
        return false

    # DST calculation for US time zones
    IsUSDaylightSavingTime(Yr:int, M:int, D:int, H:int)<transacts>:logic =
        if:
            SecondSundayInMarch := FindNthWeekdayOfMonth[Yr, 3, 0, 2] # 0=Sunday
            FirstSundayInNovember := FindNthWeekdayOfMonth[Yr, 11, 0, 1]
            DayOfYear := GetDayOfYear(Yr, M, D)
            SecondSundayInMarchDayOfYear := GetDayOfYear(Yr, 3, SecondSundayInMarch)
            FirstSundayInNovemberDayOfYear := GetDayOfYear(Yr, 11, FirstSundayInNovember)
            DayOfYear >= SecondSundayInMarchDayOfYear and DayOfYear <= FirstSundayInNovemberDayOfYear
        then:
            if(DayOfYear = SecondSundayInMarchDayOfYear, H < 2) then return false
            else if(DayOfYear = FirstSundayInNovemberDayOfYear, H >= 2) then return false
            return true
        return false

    # DST calculation for European time zones
    IsEuropeanDaylightSavingTime(Yr:int, M:int, D:int, H:int)<transacts>:logic =
        if:
            LastSundayInMarch := FindLastWeekdayOfMonth[Yr, 3, 0]
            LastSundayInOctober := FindLastWeekdayOfMonth[Yr, 10, 0]
            DayOfYear := GetDayOfYear(Yr, M, D)
            LastSundayInMarchDayOfYear := GetDayOfYear(Yr, 3, LastSundayInMarch)
            LastSundayInOctoberDayOfYear := GetDayOfYear(Yr, 10, LastSundayInOctober)
            DayOfYear >= LastSundayInMarch and DayOfYear <= LastSundayInOctoberDayOfYear
        then:
            if(DayOfYear = LastSundayInMarchDayOfYear, H < 2) then return false
            else if(DayOfYear = LastSundayInOctoberDayOfYear, H >= 2) then return false
            return true
        return false

    # Helper method to find the Nth occurrence of a weekday in a month
    FindNthWeekdayOfMonth(Yr:int, M:int, Weekday:int, N:int)<decides><transacts>:int =
        FirstDayOfMonthWeekday := GetWeekday[Yr, M, 1]
        Offset := Mod[Weekday - FirstDayOfMonthWeekday + 7, 7]
        FirstOccurrenceDay := 1 + Offset
        NthOccurrenceDay := FirstOccurrenceDay + (N - 1) * 7
        DaysInMonth := GetDaysInMonth(Yr, M)
        NthOccurrenceDay <= DaysInMonth
        NthOccurrenceDay

    # Helper method to find the last occurrence of a weekday in a month
    FindLastWeekdayOfMonth(Yr:int, M:int, Weekday:int)<decides><transacts>:int =
        DaysInMonth := GetDaysInMonth(Yr, M)
        LastDayOfMonthWeekday := GetWeekday[Yr, M, DaysInMonth]
        Offset := Mod[LastDayOfMonthWeekday - Weekday + 7, 7]
        LastOccurrenceDay := DaysInMonth - Offset
        LastOccurrenceDay

    # Helper method to get the day of the week for a given date
    GetWeekday(Yr:int, M:int, D:int)<transacts><decides>:int =
        MonthTable:[]int = array{0, 3, 2, 5, 0, 3, 5, 1, 4, 6, 2, 4}
        var Y:int = Yr
        if(M < 3) then set Y -= 1
        Mod[Y + Floor(Y/4) - Floor(Y/100) + Floor(Y/400) + MonthTable[M - 1] + D, 7]

    # Helper method to get the day of the year
    GetDayOfYear(Yr:int, M:int, D:int)<transacts>:int =
        DaysInMonth:[]int = array{31,28,31,30,31,30,31,31,30,31,30,31}
        var Days:int = D
        for(m := 1..M, set Days += DaysInMonth[m - 1]):
        if(M > 2, IsLeapYear(Yr)?) then set Days += 1
        return Days

    # Helper method to get the number of days in a month
    GetDaysInMonth(Yr:int, M:int)<transacts>:int =
        var Days:int = 0
        DaysInMonth:[]int = array{31,28,31,30,31,30,31,31,30,31,30,31}
        if(M = 2, IsLeapYear(Yr)?) then set Days = 29
        else if(D := DaysInMonth[M - 1]) then set Days = D
        return Days



# Example of how to use the Date_Time_Provider class
DateAndTime := class<concrete>:
    @editable
    Billboard:billboard_device = billboard_device{}

    DateTimeProvider:date_time_provider = date_time_provider{TimeZone := time_zone.CT, ClockSystem := clock_system.Hour_12}

    S2M<localizes>(Value:string):message = "{Value}"

    Start()<suspends>:void =
        loop:
            DateTime := DateTimeProvider.GetDateAndTime()
            MonthName := DateTimeProvider.GetMonthName(DateTime.month)
            Minute := if(DateTime.minute < 10) then "0{DateTime.minute}" else "{DateTime.minute}"
            Second := if(DateTime.second < 10) then "0{DateTime.second}" else "{DateTime.second}"
            if(DateTimeProvider.ClockSystem = clock_system.Hour_24):
                Hour := if(DateTime.hour < 10) then "0{DateTime.hour}" else "{DateTime.hour}"
                Billboard.SetText(S2M("{MonthName} {DateTime.day}, {DateTime.year}\n{DateTimeProvider.TimeZone}: {Hour}:{Minute}:{Second}"))
            else:
                HourIn12Format := 
                    if(DateTime.hour = 0) then 12  # Special case for midnight
                    else if(DateTime.hour > 12) then DateTime.hour - 12
                    else DateTime.hour
                Hour := if(HourIn12Format < 10) then "0{HourIn12Format}" else "{HourIn12Format}"
                if(DateTime.hour < 12):
                    Billboard.SetText(S2M("{MonthName} {DateTime.day}, {DateTime.year}\n{DateTimeProvider.TimeZone}: {Hour}:{Minute}:{Second}AM"))
                else {Billboard.SetText(S2M("{MonthName} {DateTime.day}, {DateTime.year}\n{DateTimeProvider.TimeZone}: {Hour}:{Minute}:{Second}PM"))}
            Sleep(1.0)