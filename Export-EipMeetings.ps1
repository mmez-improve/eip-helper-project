<#
.SYNOPSIS
    Exports Outlook calendar items categorized as "EIP" to a CSV file.

.PARAMETER CategoryName
    Outlook category to filter on. Defaults to "EIP".

.PARAMETER StartDate
    Start of the date range to search. Defaults to 6 months ago.

.PARAMETER EndDate
    End of the date range to search. Defaults to 6 months from now.

.PARAMETER OutputPath
    Path to the CSV file to create. Defaults to Desktop\EIP_Meetings.csv.

.EXAMPLE
    .\Export-EipMeetings.ps1
    .\Export-EipMeetings.ps1 -StartDate 2026-01-01 -EndDate 2026-12-31 -OutputPath C:\temp\eip.csv
#>
[CmdletBinding()]
param(
    [string]$CategoryName = "EIP",
    [datetime]$StartDate = "2026-04-01",
    [datetime]$EndDate = "2026-06-30 23:59:59",
    [string]$OutputPath = (Join-Path ([Environment]::GetFolderPath("Desktop")) "EIP_Meetings.csv")
)

$outlook = $null
$namespace = $null
$calendar = $null
$items = $null

try {
    try {
        $outlook = New-Object -ComObject Outlook.Application
    } catch {
        throw "Could not connect to Outlook. Make sure desktop Outlook is installed and you are signed in. $($_.Exception.Message)"
    }

    $namespace = $outlook.GetNamespace("MAPI")
    $calendar = $namespace.GetDefaultFolder(9) # olFolderCalendar
    $items = $calendar.Items

    # NOTE: Items.Restrict() combined with IncludeRecurrences, and plain enumeration with
    # IncludeRecurrences, are both unreliable in this Outlook COM environment (Restrict silently
    # returns zero items while .Count reports a bogus sentinel; unfiltered enumeration doesn't
    # reliably expand series either). Instead, enumerate masters/singles only (default, no
    # IncludeRecurrences) and manually walk each recurring series day-by-day with
    # GetRecurrencePattern().GetOccurrence(), which is deterministic and also reflects
    # per-occurrence category overrides.
    function New-MeetingRecord($occ) {
        [PSCustomObject]@{
            Subject           = $occ.Subject
            Start             = $occ.Start
            End               = $occ.End
            DurationMins      = $occ.Duration
            Location          = $occ.Location
            Organizer         = $occ.Organizer
            Categories        = $occ.Categories
            IsRecurring       = $occ.IsRecurring
            RequiredAttendees = $occ.RequiredAttendees
            OptionalAttendees = $occ.OptionalAttendees
        }
    }

    $results = foreach ($item in $items) {
        if (-not $item.Categories) { continue }
        $cats = $item.Categories -split '\s*[;,]\s*'
        if ($cats -notcontains $CategoryName) { continue }

        if ($item.IsRecurring) {
            $pattern = $item.GetRecurrencePattern()
            $day = $StartDate.Date
            while ($day -le $EndDate.Date) {
                try {
                    $occ = $pattern.GetOccurrence($day)
                    New-MeetingRecord $occ
                } catch {
                    # No occurrence on this date (skipped/deleted instance) - expected, not an error
                }
                $day = $day.AddDays(1)
            }
        } else {
            if ($item.Start -ge $StartDate -and $item.Start -le $EndDate) {
                New-MeetingRecord $item
            }
        }
    }

    if (-not $results) {
        Write-Warning "No meetings found with category '$CategoryName' between $StartDate and $EndDate."
    } else {
        $sorted = $results | Sort-Object Start
        $sorted | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8

        $totalMinutes = ($sorted | Measure-Object -Property DurationMins -Sum).Sum
        $totalHours = [math]::Round($totalMinutes / 60, 2)
        Add-Content -Path $OutputPath -Value "`nTotal Hours,$totalHours"

        Write-Host "Exported $($sorted.Count) meetings to $OutputPath"
        Write-Host "Total hours: $totalHours"
    }
}
finally {
    foreach ($com in @($items, $calendar, $namespace, $outlook)) {
        if ($com) { [System.Runtime.InteropServices.Marshal]::ReleaseComObject($com) | Out-Null }
    }
    [System.GC]::Collect()
    [System.GC]::WaitForPendingFinalizers()
}
