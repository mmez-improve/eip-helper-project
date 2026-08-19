---
name: pull-eip-calendar-events
description: Pull EIP-tagged and Out of Office calendar events from Outlook for a given date range and export them to CSV for the weekly/quarterly EIP reporting pipeline. Use when asked to run the weekly EIP calendar pull, generate the EIP export, or process EIP reporting for a date range.
---

# Pull EIP calendar events

Extraction stage of the EIP Helper reporting pipeline. This skill only pulls
and exports raw calendar data — it does not filter, apply the "Direct
Revenue" rule, or build the final report. That deterministic work happens
separately in `scripts/filter_eip_events.py` and `scripts/export_report.py`
in the `EIP-Helper-Project` repo (Claude Code side of the pipeline).

## Requirements

- Microsoft 365 connector must be connected (provides Outlook calendar
  access via Graph API: `outlook_calendar_search` / `read_resource`).
- Read-only. Never send emails, create/modify/delete calendar events, or
  change categories or Show As status on any event.

## Inputs

Ask the user for the date range if not given (start date, end date). Default
to "this past week" only if the user explicitly says to use the default.

## Steps

1. Connect to the user's Outlook calendar via the Microsoft 365 connector.
2. Pull all calendar events in the given date range that match either:
   - (a) category "EIP", or
   - (b) Show As status = Out of Office (Graph API `showAs` = `"oof"`).
     This is a separate field from categories (set via the Show As menu,
     not Categorize) — do not expect it to carry an "EIP" category label.
3. If category or `showAs` cannot be filtered directly through the search
   API, pull all events in the range instead and flag which ones carry an
   EIP-related category or an Out of Office `showAs` status, rather than
   silently dropping events.
4. For each matching event extract:
   - Event title
   - Date and time
   - Category label(s) assigned
   - Show As / free-busy status (`showAs` field)
   - Match reason: category "EIP", `showAs` "oof", or both
   - Any notes/description text in the event body
   - Attendees (if relevant)
5. Sort the results by date and export to CSV (not xlsx — the Claude Code
   stage builds the final xlsx/report from this raw CSV, so keep this
   stage's output plain and simple).
6. Name the file `EIP_Calendar_Export_[START_DATE]_to_[END_DATE].csv` using
   the actual date range pulled, e.g.
   `EIP_Calendar_Export_2026-08-03_to_2026-08-07.csv`.
7. Save the file to `D:\EIP-Helper-Project\outputs`. If direct filesystem
   write access to that path isn't available, hand the user a downloadable
   file and say explicitly that it needs to be moved into `outputs\`
   manually — do not silently save it somewhere else without saying so.

## Guardrails

- Read-only against Outlook. No sends, no event creation, no edits.
- Do not relabel Out of Office events with an "EIP" category to make them
  match — pull them via `showAs` instead, and record the match reason. The
  "OOO counts toward Direct Revenue" business rule belongs in
  `scripts/filter_eip_events.py`, not in manual Outlook relabeling.
- If unsure whether an event should count, include it and flag it rather
  than silently excluding it — the user reviews the raw export before it
  feeds the deterministic filtering stage.

## Source

Derived from `prompts/pull_eip_calendar_events.md` in the EIP-Helper-Project
repo (`github.com/mmez-improve/eip-helper-project`), which remains the
narrative/verification record of how this was tested and verified working.
Update both files together if the extraction logic changes.
