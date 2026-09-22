# TODO

Live, editable task list for the EIP Helper pipeline. This tracks what's
*still open* — for the narrative record of what's already been done and
why, see `EIP_Automation_Log.md` instead. Check items off (or delete them)
as they're resolved; unlike the log, this file is meant to be edited in
place, not appended to forever.

## Open

- [ ] **Rewrite `scripts/filter_eip_events.py` for the real Cowork CSV
      shape.** It currently expects nested JSON (`start.dateTime`, etc.)
      per its docstring, but the actual Cowork output landing in `data/` is
      flat CSV with columns `Event Title, Date, Time (UTC), Categories,
      Show As Status, Match Reason, Description, My Response`. The script
      can't run against real data yet.
- [ ] **Build the catalog-matching step.** Match each calendar event to a
      specific `data/eip_activity_catalog.csv` row (category + activity
      name + points), not just a yes/no EIP flag — this is the actual
      report the pipeline is for. Decide matching approach (exact/fuzzy
      text match on title/description vs. flagging ambiguous ones for
      manual confirmation).
- [x] ~~Confirm what's actually driving the Cowork pull.~~ Resolved: it's
      the **`outlook-calendar-category-export`** Cowork skill (an
      Anthropic-provided skill, not `skills/pull-eip-calendar-events/
      SKILL.md`), which bundles `data/eip_export.py` — real deterministic
      Python filtering on `categories`/`showAs`, not LLM judgment. That's
      what's produced every real CSV in `data/` so far.
- [ ] **Reconcile/retire `skills/pull-eip-calendar-events/SKILL.md`.** It's
      superseded by the `outlook-calendar-category-export` skill above.
      Decide: delete it, or update it to point at the real skill so it
      doesn't look like an active source of truth it isn't.
- [ ] **Verify the Out of Office (`showAs=oof`) matching is actually
      working.** Zero OOO rows have shown up in any real export so far
      (Aug or Sept 2026). Confirm by hand whether that's because there was
      no OOO time in those months, or because the filter isn't triggering.
- [ ] **Update `scripts/export_report.py`** once the catalog-matching
      output shape is decided — it currently builds a report off the old
      yes/no-flag shape.
- [ ] **Update `evals/promptfoo.config.yaml` + `fixtures/`** to cover the
      new CSV input shape and catalog-matching logic once built, so the
      eval suite stays meaningful instead of testing stale logic.
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
- [x] `prompts/pull_eip_calendar_events.md` verified working and packaged
      as `skills/pull-eip-calendar-events/SKILL.md`.
