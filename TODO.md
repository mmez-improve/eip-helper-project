# TODO

Live, editable task list for the EIP Helper pipeline. This tracks what's
*still open* — for the narrative record of what's already been done and
why, see `EIP_Automation_Log.md` instead. Check items off (or delete them)
as they're resolved; unlike the log, this file is meant to be edited in
place, not appended to forever.

**Paused 2026-09-22** — picking back up when ready. Immediate next step is
manual (see first Open item below), not automated eval.

## Open

- [ ] **You: manually review the matching prompt's output a few more
      times before we automate anything further.** Run
      `prompts/match_event_to_eip_category.prompt.txt` (by hand, e.g. in
      Claude Code or Cowork chat) against another real export or two and
      judge the results yourself. This was the explicit decision today:
      get more confidence in output quality first, automated eval second
      — don't over-invest in eval tooling before that.
- [ ] **Decide the matching-architecture question:** should
      event-to-category matching be a *prompt/skill* (AI judgment,
      measured by an eval harness — chosen today, see "Done" below) or a
      deterministic script? Today's direction is prompt-based, on purpose,
      because the AI-fluency certification goal is to demonstrate and
      measure AI judgment, not just deterministic code. Revisit only if
      that goal changes.
- [ ] **`evals/category_matching.config.yaml` doesn't run yet** — hit a
      promptfoo internal bug (`SqliteError: FOREIGN KEY constraint
      failed`) on its local results database, unrelated to our prompt or
      config content. Confirmed pre-existing: the *original* deterministic
      eval suite (`evals/promptfoo.config.yaml`, previously verified
      passing in Session 4) fails identically on a fresh `npm install` on
      this machine. Likely a promptfoo/Node.js version mismatch (Node 24
      here; promptfoo was bumped from `^0.100.0` to `^0.123.1` in
      `package.json` mid-session but not yet confirmed to fix it).
      **Deliberately not pursued further today** — parked per explicit
      instruction, not urgent while validation is manual. When picked back
      up: retry after the version bump, and if still broken, treat it as
      an environment/tooling issue to solve on its own, separate from the
      pipeline's actual logic.
- [ ] **Rewrite `scripts/filter_eip_events.py` for the real Cowork CSV
      shape.** It currently expects nested JSON (`start.dateTime`, etc.)
      per its docstring, but the actual Cowork output landing in `data/` is
      flat CSV with columns `Event Title, Date, Time (UTC), Categories,
      Show As Status, Match Reason, Description, My Response`. The script
      can't run against real data yet. (May end up superseded entirely by
      the prompt-based matching approach — decide alongside the item
      above.)
- [ ] **Reconcile/retire `skills/pull-eip-calendar-events/SKILL.md`.** It's
      superseded by the `outlook-calendar-category-export` skill (see
      Done). Decide: delete it, or update it to point at the real skill so
      it doesn't look like an active source of truth it isn't.
- [ ] **Verify the Out of Office (`showAs=oof`) matching is actually
      working.** Zero OOO rows have shown up in any real export so far
      (Aug or Sept 2026). Confirm by hand whether that's because there was
      no OOO time in those months, or because the filter isn't triggering.
- [ ] **Update `scripts/export_report.py`** once the catalog-matching
      output shape/architecture is decided — it currently builds a report
      off the old yes/no-flag shape.
- [ ] **Sanity-check "User Experience" and "Improving Path"** in
      `data/eip_categories.csv` (2–3 rows each) against the source
      screenshots — confirm these aren't OCR/transcription slips.
- [ ] Once the pipeline is stable end-to-end, set up the recurring/
      scheduled run in Cowork.

## Done (recent)

- [x] Two-stage architecture (Cowork extraction → Claude Code processing)
      designed and documented in `README.md`, with a Mermaid flowchart.
- [x] Cowork now writes directly to `D:\EIP-Helper-Project\data\` (no
      longer stuck in its sandbox session folder).
- [x] `data/eip_activity_catalog.csv` (128 rows) and `data/eip_categories.csv`
      (17 categories) transcribed/derived and documented in `data/README.md`.
- [x] `prompts/pull_eip_calendar_events.md` verified working; later found
      superseded by the real `outlook-calendar-category-export` Cowork
      skill (bundled `data/eip_export.py` — deterministic, not LLM-driven).
- [x] Confirmed what's actually driving the Cowork pull: the
      `outlook-calendar-category-export` skill, not
      `skills/pull-eip-calendar-events/SKILL.md`.
- [x] **Built the event-to-category matching prompt**
      (`prompts/match_event_to_eip_category.prompt.txt`, documented in
      `prompts/match_event_to_eip_category.md`) — deliberately a prompt,
      not a script, so an AI-fluency eval can measure its accuracy.
      Embeds the full 128-row catalog directly so it's self-contained.
- [x] **Manually validated the prompt against all 14 real events** in
      `data/EIP_Calendar_Export_2026-08-01_to_2026-08-31.csv` — 12/14
      matched with high confidence on the first pass; the 2 flagged
      low-confidence cases were resolved with the user directly:
      "Cleveland CT - Mystery Speakeasy" = Come Together / In-Person
      Attendance, "Path Shaun-Michael" = Improving Path / Meeting.
- [x] Captured those 14 confirmed events as ground truth in
      `evals/category_matching.testcases.yaml`, and scaffolded
      `evals/category_matching.config.yaml` to eval the prompt against
      them via a real Anthropic Sonnet call (kept deliberately simple:
      one provider, one plain pass/fail assertion, no rubric grading —
      per the "don't overcomplicate the eval, deadline in a month"
      instruction). Not yet successfully run — see the promptfoo bug
      above.
