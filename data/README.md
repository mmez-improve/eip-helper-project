# EIP Activity Catalog reference data

`eip_activity_catalog.csv` is a transcription of the Engage portal's
Involvement → Catalog view (7 screenshots, captured 2026-08-18), listing
every reportable activity: category, activity name, description, point
value, and guidance notes.

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

Re-pull the catalog periodically — point values and available activities
can change, and this file is a point-in-time snapshot, not a live source.
