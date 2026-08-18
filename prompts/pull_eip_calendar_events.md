# Prompt: Pull EIP-tagged calendar events (Cowork + Microsoft 365 connector)

**Tool:** Claude Cowork, with the Microsoft 365 connector connected
(provides `outlook_calendar_search` / `read_resource` over the Outlook
calendar via Graph API).

**Status:** Verified working — ran successfully against a live 8/3–8/7/2026
date range, correctly read the native `categories` field, and produced an
accurate xlsx export. This is the reference prompt to reuse each reporting
period; adjust the date range as needed.

## Prompt text

```
Connect to my Outlook calendar using the Microsoft 365 connector.
Pull all calendar events from 8-3-2026 to 8-7-26 that are labeled
with the category "EIP".
For each matching event, extract:
- Event title
- Date and time
- Category label(s) assigned
- Any notes or description text in the event body
- Attendees (if relevant)
Output the results as a table, sorted by date, and export it to an Excel
file named "EIP_Calendar_Export_Test.xlsx".
If you cannot filter by category directly through the calendar search,
pull all events in the date range instead and flag which ones carry an
EIP-related category, so I can confirm the category field is being read
correctly before we filter automatically.
Do not send any emails, create any calendar events, or modify anything
in Outlook. This is a read-only test.
```

## Notes on reuse

- Swap the date range (`8-3-2026 to 8-7-26`) for the current reporting
  period each time this is run.
- The "if you cannot filter by category directly" fallback instruction can
  likely be dropped now that we've confirmed the connector reads native
  Graph API `categories` correctly — filtering by category directly should
  work going forward. Kept here for the record since it's part of what was
  actually verified.
- Output filename can be changed from the `_Test` suffix once this moves
  from pilot to the standing quarterly process.
- This prompt only performs the extraction/export stage. The deterministic
  filtering and report-building logic it produced has since been factored
  out into `scripts/filter_eip_events.py` and `scripts/export_report.py`
  for the Claude Code side of the pipeline (see `README.md`).
