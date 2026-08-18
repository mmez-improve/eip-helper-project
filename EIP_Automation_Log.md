# EIP Automation — Session Log

Running record of work on the EIP calendar reporting pipeline, kept as
evidence of iterative development across sessions (alongside git commit
history) for internal AI-maturity documentation.

---

## Session 1 — 2026-07-01

**Tool:** Claude Code (PowerShell / Outlook COM interop)

- Wrote `Export-EipMeetings.ps1`: pulls Outlook calendar items, filters by
  the "EIP" category, exports to CSV.
- Wrote `_debug_categories.ps1` to diagnose why category filtering wasn't
  matching expected results.
- Approach used Outlook COM automation (`Items.Restrict()` +
  `GetRecurrencePattern()`), driven from the local desktop Outlook install.

## Session 2 — 2026-07-06

**Tool:** Claude Code (PowerShell / Outlook COM interop)

- Wrote `Export-AllCalendarItems.ps1` as a raw, unfiltered dump to isolate
  whether the problem was the category filter or the underlying data pull.
- Root-caused two blocking issues with the COM approach:
  1. Classic Outlook's local cached data file (OST) was ~2 years out of
     sync with the live mailbox — the user works in modern (new) Outlook,
     which doesn't sync to that same OST.
  2. `Items.Restrict()` combined with recurrence expansion silently
     returned zero items while reporting a bogus count.
- Authored `Graph-API-Migration-Plan.md` recommending a move to Microsoft
  Graph API (`/calendarView`, which expands recurrence server-side and
  reads live from Exchange Online) instead of COM interop, with two auth
  paths (Graph PowerShell SDK vs. a scoped Entra ID app registration via
  Global IT Services if needed).

## Session 3 — 2026-08-18

**Tool:** Claude Cowork (Microsoft 365 connector)

- Rather than stand up the Graph API auth plumbing from Session 2's plan
  from scratch, connected Cowork's built-in Microsoft 365 connector, which
  already brokers Graph API auth and calendar search.
- Pulled Outlook calendar events for 8/3–8/7/2026 using
  `outlook_calendar_search` / `read_resource`. Confirmed the Graph API
  `categories` field is read correctly and live (matches modern Outlook) —
  the exact problem identified in Session 2 is resolved by this path.
- Identified 4 of 14 events tagged "EIP" and built a one-off xlsx export
  (`EIP_Calendar_Export_Test.xlsx`) as a proof of concept.
- Decided on a two-stage architecture going forward: Cowork owns the
  connector/auth pull (solves the Session 1–2 data-accuracy problem),
  Claude Code + git owns deterministic processing, version history, and
  evaluation (solves the "prove it works every run" requirement).

## Session 4 — 2026-08-18

**Tool:** Claude Cowork (scaffolding), handoff to Claude Code next

- Scaffolded `D:\EIP-Helper-Project` repo structure: `fixtures/`,
  `scripts/`, `evals/`, `outputs/`, README, `.gitignore`.
- Wrote deterministic `scripts/filter_eip_events.py` (EIP category
  filtering, sorting, row shaping) and `scripts/export_report.py` (xlsx
  report builder), factored out of the one-off Session 3 logic.
- Created a synthetic fixture (`fixtures/sample_calendar_export.json`)
  modeled on the real Graph API export shape, with fictional
  names/addresses so it's safe to commit.
- Wired up a promptfoo eval suite (`evals/promptfoo.config.yaml`) that runs
  the filter script against the fixture and asserts: total event count (8),
  EIP-flagged count (4), and the exact set of EIP-flagged titles.
- Verified end-to-end: ran `filter_eip_events.py` and `export_report.py`
  directly (both produced correct output), then ran
  `npx promptfoo eval -c evals/promptfoo.config.yaml` — **1/1 passed
  (100%)**. Fixed two real bugs found during this verification: a relative
  path issue (provider/fixture paths resolve from `evals/`, not repo root)
  and a promptfoo `GradingResult` shape issue (custom JS assertions require
  a `score` field, not just `pass`/`reason`).
- Initialized git, with commit history backdated to match each file's real
  authoring date (Sessions 1–3), then committed the scaffold from this
  session.

---

<!-- Add new entries above this line as work continues. -->
