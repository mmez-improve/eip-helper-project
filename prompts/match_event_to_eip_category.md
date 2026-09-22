# Prompt: Match a calendar event to its EIP catalog category/activity

**Purpose:** Given one Outlook calendar event (already confirmed as EIP-
relevant by the extraction stage), decide which specific EIP catalog
category + activity name it corresponds to, so it can be logged in Engage
with the right point value. This is the AI-driven matching step of the
pipeline — deliberately a prompt, not a deterministic script, so its
accuracy can be measured with an eval harness as evidence for AI-fluency
certification.

**The actual executable prompt text is
[`match_event_to_eip_category.prompt.txt`](match_event_to_eip_category.prompt.txt),
not this file.** promptfoo (and any other harness) should load that file
directly — it's plain text with `{{event_title}}` / `{{event_date}}` /
`{{show_as}}` / `{{event_description}}` template variables and no markdown
formatting, so nothing but the intended instructions reaches the model.
This `.md` file is documentation only; don't hand-edit the prompt in two
places; edit the `.txt` file and this doc separately if their content
needs to diverge (e.g. this doc's status notes vs. the prompt's
instructions), but keep the *instructions themselves* in exactly one file.

**Status:** Manually validated 2026-09-22 against all 14 real events in
`data/EIP_Calendar_Export_2026-08-01_to_2026-08-31.csv` (run by hand, no
harness) — 12 of 14 matched with high confidence on the first pass; the
2 flagged low-confidence cases ("Cleveland CT - Mystery Speakeasy" and
"Path Shaun-Michael") were confirmed by the user as Come Together /
In-Person Attendance and Improving Path / Meeting respectively. These 14
events + confirmed labels are the ground truth for
`evals/category_matching.testcases.yaml`. Not yet run through an
automated eval — see `TODO.md`.

## What it does

Takes one calendar event (title, date, description, Show As status) and
the full EIP catalog (embedded directly in the prompt so it's
self-contained), and returns a JSON object:
`matched_category`, `matched_activity`, `points`, `confidence`,
`alternatives`, `reasoning`. Ambiguous events are meant to come back with
`confidence: "low"` and are not meant to be applied without confirmation.
Payroll-derived "Direct Revenue" activities (e.g. "40 Billable Hour Week")
are explicitly excluded — those can't legitimately be inferred from
calendar data.

## Notes on reuse

- The catalog block embedded in the prompt is a trimmed copy (descriptions
  truncated, formatting flattened) of `data/eip_activity_catalog.csv`.
  Regenerate it if the catalog changes — don't hand-edit it out of sync.
- The JSON output schema is designed so an eval harness can assert against
  it, and so ambiguous matches surface for manual confirmation instead of
  being silently applied.
