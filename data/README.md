# EIP Activity Catalog reference data

`eip_activity_catalog.csv` is a transcription of the Engage portal's
Involvement → Catalog view (7 screenshots, captured 2026-08-18), listing
every reportable activity: category, activity name, description, point
value, and guidance notes.

`eip_categories.csv` is the deduplicated list of the 17 distinct
`category` values from `eip_activity_catalog.csv` (with an `activity_count`
per category), meant as the master reference/controlled vocabulary for
category names — e.g. to validate a matched or manually-assigned category
against, without re-deriving it from the full activity list each time.
Regenerate it from `eip_activity_catalog.csv` if that file changes rather
than hand-editing it. It excludes one blank-category row from the source
data (see below).

This schema matches Engage's own "Add Activity" form fields (Category →
Type → Date → Quantity → Notes → Points), confirmed against a real manual
entry example in `documents/eip activity example q3.png`.

This is reference data only — nothing in `scripts/` currently reads or
matches against it. It exists so that if/when the pipeline is extended to
suggest which catalog activity a calendar event corresponds to (rather than
just flagging the Outlook "EIP" category), there's a clean structured source
to match against instead of re-reading screenshots.

## Known data quality issues (from the source screenshots, not introduced here)

- **"ImprovingU Attendance"** appears twice with different point values (1
  point in one screenshot, 2 in another). Both rows are kept, each flagged
  in its `guidance` field. Verify the current value directly in Engage
  before relying on either.
- **"Professional Group Attendance" (3 points)** and **"User/Professional
  Group Attendance" (1 point)** are similarly named but distinct rows in
  the source. Unclear if these are the same activity recorded
  inconsistently or genuinely different activities. Flagged in both rows.
- One row (`activity_name` "Comment", source: eip catalog 6, 0 points) has
  a **blank category** — it reads as a system utility entry for adding a
  reviewer comment, not an actual EIP category/activity. Excluded from
  `eip_categories.csv` for that reason; still present as-is in
  `eip_activity_catalog.csv`.

Re-pull the catalog periodically — point values and available activities
can change, and this file is a point-in-time snapshot, not a live source.
