<#
.SYNOPSIS
    Raw dump of Outlook calendar items overlapping a date range (one row per item/series, no
    per-occurrence recurrence expansion). Filter/categorize the CSV afterward.

.PARAMETER StartDate
    Start of the date range. Defaults to 2026-04-01.

.PARAMETER EndDate
    End of the date range. Defaults to 2026-06-30.

.PARAMETER OutputPath
    Path to the CSV file to create. Defaults to Desktop\All_Calendar_Items.csv.

.EXAMPLE
    .\Export-AllCalendarItems.ps1
    .\Export-AllCalendarItems.ps1 -StartDate 2026-01-01 -EndDate 2026-03-31
#>
[CmdletBinding()]
param(
    [datetime]$StartDate = "2026-04-01",
    [datetime]$EndDate = "2026-06-30 23:59:59",
    [string]$OutputPath = (Join-Path ([Environment]::GetFolderPath("Desktop")) "All_Calendar_Items.csv")
)

function Get-RecurrencePatternSafe($item) {
    if (-not $item.IsRecurring) { return $null }
    try { $item.GetRecurrencePattern() } catch { $null }
}

function Get-RecurrenceSummary($p) {
    if (-not $p) { return "" }
    $days = @()
    if ($p.DayOfWeekMask -band 1)   { $days += "Sun" }
    if ($p.DayOfWeekMask -band 2)   { $days += "Mon" }
    if ($p.DayOfWeekMask -band 4)   { $days += "Tue" }
    if ($p.DayOfWeekMask -band 8)   { $days += "Wed" }
    if ($p.DayOfWeekMask -band 16)  { $days += "Thu" }
    if ($p.DayOfWeekMask -band 32)  { $days += "Fri" }
    if ($p.DayOfWeekMask -band 64)  { $days += "Sat" }
    $typeName = switch ($p.RecurrenceType) {
        0 { "Daily" }
        1 { "Weekly" }
        2 { "Monthly" }
        5 { "Monthly (nth weekday)" }
        6 { "Yearly" }
        10 { "Yearly (nth weekday)" }
        default { "Type $($p.RecurrenceType)" }
    }
    $endDesc = if ($p.NoEndDate) { "no end date" } else { "ends $($p.PatternEndDate.ToString('yyyy-MM-dd'))" }
    "$typeName every $($p.Interval), days=[$($days -join ',')], starts $($p.PatternStartDate.ToString('yyyy-MM-dd')), $endDesc"
}

function Get-PropSafe($item, [string]$propName) {
    try { $item.$propName } catch { "" }
}

function Test-OverlapsRange($item, $pattern, [datetime]$rangeStart, [datetime]$rangeEnd) {
    if ($pattern) {
        # Series overlaps the range if it starts on/before the range ends, and (has no end
        # date, or) ends on/after the range starts. Uses only pattern start/end - no
        # GetOccurrence() calls, so it avoids the per-occurrence COM bug entirely.
        if ($pattern.PatternStartDate -gt $rangeEnd) { return $false }
        if (-not $pattern.NoEndDate -and $pattern.PatternEndDate -lt $rangeStart) { return $false }
        return $true
    } else {
        return ($item.Start -ge $rangeStart -and $item.Start -le $rangeEnd)
    }
}

$outlook = $null
$namespace = $null
$calendar = $null

try {
    try {
        $outlook = New-Object -ComObject Outlook.Application
    } catch {
        throw "Could not connect to Outlook. Make sure desktop Outlook is installed and you are signed in. $($_.Exception.Message)"
    }

    $namespace = $outlook.GetNamespace("MAPI")
    $calendar = $namespace.GetDefaultFolder(9) # olFolderCalendar

    $results = foreach ($item in $calendar.Items) {
        $pattern = Get-RecurrencePatternSafe $item
        if (-not (Test-OverlapsRange $item $pattern $StartDate $EndDate)) { continue }

        [PSCustomObject]@{
            Subject           = Get-PropSafe $item "Subject"
            Start             = Get-PropSafe $item "Start"
            End               = Get-PropSafe $item "End"
            DurationMins      = Get-PropSafe $item "Duration"
            Categories        = Get-PropSafe $item "Categories"
            IsRecurring       = Get-PropSafe $item "IsRecurring"
            RecurrenceSummary = Get-RecurrenceSummary $pattern
            Location          = Get-PropSafe $item "Location"
            Organizer         = Get-PropSafe $item "Organizer"
            RequiredAttendees = Get-PropSafe $item "RequiredAttendees"
            OptionalAttendees = Get-PropSafe $item "OptionalAttendees"
        }
    }

    $matchedCount = $results.Count
    $results | Sort-Object Start | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8

    $writtenCount = (Import-Csv -Path $OutputPath).Count
    Write-Host "Matched $matchedCount calendar items overlapping $StartDate to $EndDate; wrote $writtenCount rows to $OutputPath"
    if ($writtenCount -ne $matchedCount) {
        Write-Warning "Row count mismatch: $matchedCount matched but only $writtenCount were written. Re-run and compare - do not trust this file alone."
    }
}
finally {
    foreach ($com in @($calendar, $namespace, $outlook)) {
        if ($com) { [System.Runtime.InteropServices.Marshal]::ReleaseComObject($com) | Out-Null }
    }
    [System.GC]::Collect()
    [System.GC]::WaitForPendingFinalizers()
}
