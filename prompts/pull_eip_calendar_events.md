# Prompt: Pull EIP-tagged calendar events (Cowork + Microsoft 365 connector)

**Tool:** Claude Cowork, with the Microsoft 365 connector connected
(provides `outlook_calendar_search` / `read_resource` over the Outlook
calendar via Graph API).

**Status:** Verified working — ran successfully against a live 8/3–8/7/2026
date range, correctly read the native `categories` field, and produced an
accurate xlsx export. This is the reference prompt to reuse each reporting
period; adjust the date range as needed. (Updated 2026-08-19 to output CSV
instead of xlsx — the Claude Code stage builds the final xlsx locally, so
Cowork no longer needs to — and to name the file after the date range for
weekly reuse.)

## Prompt text

```
Connect to my Outlook calendar using the Microsoft 365 connector.
Pull all calendar events from 8-3-2026 to 8-7-26 that either:
(a) are labeled with the category "EIP", or
(b) have their "Show as" status set to "Out of Office" (Graph API
showAs = "oof") — this is a separate field from categories, set via
the Show As menu, not Categorize.
For each matching event, extract:
- Event title
- Date and time
- Category label(s) assigned
- Show As / free-busy status (showAs field)
- Match reason: whether it matched on category "EIP", showAs "oof",
  or both
- Any notes or description text in the event body
- Attendees (if relevant)
Output the results as a table, sorted by date, and export it to a CSV file
named "EIP_Calendar_Export_[START_DATE]_to_[END_DATE].csv" (using the actual
date range pulled, e.g. "EIP_Calendar_Export_2026-08-03_to_2026-08-07.csv").
Save it to D:\EIP-Helper-Project\outputs. If you cannot write directly to
that path, give me the file to download and tell me explicitly so I can
save it there myself.
If you cannot filter by category or showAs directly through the calendar
search, pull all events in the date range instead and flag which ones
carry an EIP-related category or an Out of Office showAs status, so I can
confirm both fields are being read correctly before we filter
automatically.
Do not send any emails, create any calendar events, or modify anything
in Outlook. This is a read-only test.
```

## Notes on reuse

- Every run should output to `D:\EIP-Helper-Project\outputs`. Cowork may not
  have direct filesystem write access to a local path depending on how it's
  running — if it can't save there directly, it will hand you a download
  instead; move that file into `outputs\` yourself before running the
  Claude Code processing stage against it.
- Swap the date range (`8-3-2026 to 8-7-26`) for the current reporting
  period each time this is run.
- The "if you cannot filter by category directly" fallback instruction can
  likely be dropped now that we've confirmed the connector reads native
  Graph API `categories` correctly — filtering by category directly should
  work going forward. Kept here for the record since it's part of what was
  actually verified.
- Filename now bakes in the date range (e.g.
  `EIP_Calendar_Export_2026-08-03_to_2026-08-07.csv`) so weekly runs don't
  collide or overwrite each other in `outputs\`.
- This prompt only performs the extraction/export stage. The deterministic
  filtering and report-building logic it produced has since been factored
  out into `scripts/filter_eip_events.py` and `scripts/export_report.py`
  for the Claude Code side of the pipeline (see `README.md`).
- Out of Office time counts toward the "Direct Revenue" category (40hr
  weeks qualify). OOO is set via Outlook's **Show As** status, a separate
  field from Categorize — it will never carry an "EIP" category label, so
  it has to be pulled as its own match condition (`showAs = "oof"`), not by
  relabeling OOO events as "EIP" in Outlook. Keeping the two conditions
  distinct (and recording which one each row matched) means the
  "Direct Revenue" qualification rule lives in `filter_eip_events.py` where
  it's versioned and testable, instead of depending on manual calendar
  relabeling every week.
- This prompt has been packaged as a Cowork skill for consistent weekly/
  scheduled reuse: see `skills/pull-eip-calendar-events/SKILL.md`. This file
  remains the narrative record of how the extraction logic was tested and
  verified; update both together if the logic changes.
