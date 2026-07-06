# EIP Meeting Export: Migration to Microsoft Graph API

## Why

The current script uses Outlook COM interop, which reads from classic desktop Outlook's local cached data file (OST). That cache was found to be about two years out of sync with the live mailbox. Since you use modern (new) Outlook day to day, which reads live from Exchange Online rather than syncing to the same local OST that COM automation depends on, COM interop is not a reliable data source going forward. Microsoft Graph API reads directly from Exchange Online and will match what modern Outlook, OWA, and mobile all show.

This also resolves a second, unrelated problem hit during development: Outlook COM's `Items.Restrict()` combined with recurrence expansion is unreliable (it silently returns zero items while reporting a bogus count). Graph's `/calendarView` endpoint expands recurring events server-side and does not have this failure mode.

## Two paths, try in this order

### Path A: Microsoft Graph PowerShell SDK, no new app registration (try first)

The Microsoft Graph PowerShell SDK ships with its own pre-registered, Microsoft-owned multi-tenant Entra app. If Improving's tenant allows user consent for low-risk delegated scopes, this works with no IT request at all.

Test with:

```powershell
Install-Module Microsoft.Graph.Calendar -Scope CurrentUser
Connect-MgGraph -Scopes "Calendars.Read"
```

If this completes without an admin consent prompt or error, no registration is needed. Skip to the implementation section.

### Path B: Dedicated Entra ID app registration (only if Path A is blocked)

If tenant policy blocks user consent for `Calendars.Read`, request the following from Global IT Services / whoever administers Entra ID app registrations at Improving:

- **App registration type:** Single-tenant, public client (no client secret required)
- **Redirect URI:** `http://localhost` (required for MSAL interactive or device-code auth flows)
- **API permission:** Microsoft Graph, delegated, `Calendars.Read` (read-only, no write access needed)
- **Admin consent:** grant consent for that one delegated scope
- **Purpose/justification to state in the request:** personal, read-only export of your own calendar for quarterly EIP time-submission reporting; runs interactively under your own credentials, not as a background service or daemon

Keep the ask narrow: one delegated read-only scope, no secrets, no service principal with standing access. This is the kind of request that should be fast to approve since it carries minimal risk.

## Technical implementation outline

Once either path grants access:

1. **Auth:** `Connect-MgGraph -Scopes "Calendars.Read"` (interactive browser or device code, run once per session)
2. **Data pull:** `Get-MgUserCalendarView -UserId "me" -StartDateTime <start> -EndDateTime <end>` — this endpoint expands recurring series into individual occurrences server-side, which eliminates the recurrence-handling problems from the COM version entirely
3. **Filter:** same as today — check each event's `Categories` collection for `"EIP"` in PowerShell after retrieval
4. **Output:** same CSV shape and total-hours summary line as the current script

## What changes from the current script

- No dependency on desktop Outlook being installed, running, or synced
- No COM object lifecycle management (no `ReleaseComObject` cleanup needed)
- Recurrence expansion becomes reliable (handled by Graph, not manual day-by-day `GetOccurrence` looping)
- Auth becomes token-based (interactive sign-in per run, or a cached token) instead of implicit via the local Windows session

## Open questions to resolve before/with IT

- Is the Microsoft Graph PowerShell SDK already consented for `Calendars.Read` in Improving's tenant? (Test Path A first — this may make the rest moot.)
- If a new app registration is required, who at Improving owns that approval (Global IT Services)?
- Do any conditional access policies on this device affect interactive or device-code sign-in?
