$outlook = New-Object -ComObject Outlook.Application
$ns = $outlook.GetNamespace('MAPI')
$cal = $ns.GetDefaultFolder(9)

$rangeStart = [datetime]'2026-04-01'
$rangeEnd = [datetime]'2026-06-30 23:59:59'

foreach ($item in $cal.Items) {
    if ($item.Subject -in @('Ohio AI Roundtable', 'Trust Pod 2026')) {
        Write-Host "=== $($item.Subject) === IsRecurring=$($item.IsRecurring) Categories=[$($item.Categories)]"
        if ($item.IsRecurring) {
            try {
                $p = $item.GetRecurrencePattern()
                Write-Host "  PatternStartDate: $($p.PatternStartDate)"
                Write-Host "  NoEndDate: $($p.NoEndDate)"
                try {
                    Write-Host "  PatternEndDate: $($p.PatternEndDate)"
                } catch {
                    Write-Host "  PatternEndDate: THREW ERROR -> $($_.Exception.Message.Split("`n")[0])"
                }
                $startsBeforeRangeEnd = $p.PatternStartDate -le $rangeEnd
                Write-Host "  starts on/before rangeEnd? $startsBeforeRangeEnd"
            } catch {
                Write-Host "  GetRecurrencePattern() THREW -> $($_.Exception.Message.Split("`n")[0])"
            }
        } else {
            Write-Host "  Start: $($item.Start)"
        }
        Write-Host ""
    }
}

[System.Runtime.InteropServices.Marshal]::ReleaseComObject($outlook) | Out-Null
