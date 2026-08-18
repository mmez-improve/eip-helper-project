"""
Deterministic EIP calendar filtering logic.

Input: raw calendar export JSON (list of events under an "events" key), in
the shape produced by the Cowork Microsoft 365 connector's
outlook_calendar_search / read_resource tools:
  { "events": [ { "subject", "start": {"dateTime","timeZone"},
                  "end": {...}, "categories": [...], "organizer",
                  "attendees": [...], "bodyPreview" }, ... ] }

Output: a list of row dicts, sorted by start date/time, with an explicit
EIP flag column. This is intentionally plain Python with no LLM calls, so
its output is 100% reproducible and safe to assert against in promptfoo.
"""

import json
import sys
from datetime import datetime


def load_events(path):
    with open(path, "r", encoding="utf-8") as f:
        data = json.load(f)
    return data.get("events", [])


def is_eip_event(event):
    categories = event.get("categories") or []
    return any(str(c).strip().lower() == "eip" for c in categories)


def _parse_dt(dt_obj):
    if not dt_obj or not dt_obj.get("dateTime"):
        return None
    # dateTime is a wall-clock string in the named timeZone; treat as naive
    # for sorting purposes (all sample/real exports here use a single zone).
    raw = dt_obj["dateTime"].split(".")[0]
    return datetime.fromisoformat(raw)


def to_row(event):
    start = event.get("start") or {}
    end = event.get("end") or {}
    start_dt = _parse_dt(start)
    categories = event.get("categories") or []
    attendees = event.get("attendees") or []
    return {
        "date": start_dt.date().isoformat() if start_dt else None,
        "start_time": start_dt.time().isoformat(timespec="minutes") if start_dt else None,
        "end_time": (_parse_dt(end).time().isoformat(timespec="minutes")
                     if _parse_dt(end) else None),
        "title": event.get("subject"),
        "categories": "; ".join(categories) if categories else "None",
        "eip_flag": "Yes" if is_eip_event(event) else "No",
        "notes": event.get("bodyPreview") or "",
        "attendees": "; ".join(attendees) if attendees else "None listed",
        "organizer": event.get("organizer"),
        "_sort_key": start_dt or datetime.min,
    }


def filter_and_sort(events):
    rows = [to_row(e) for e in events]
    rows.sort(key=lambda r: r["_sort_key"])
    for r in rows:
        del r["_sort_key"]
    return rows


def eip_only(rows):
    return [r for r in rows if r["eip_flag"] == "Yes"]


def main():
    if len(sys.argv) < 2:
        print("Usage: python filter_eip_events.py <path_to_export.json> [--eip-only]", file=sys.stderr)
        sys.exit(1)

    path = sys.argv[1]
    events = load_events(path)
    rows = filter_and_sort(events)

    if "--eip-only" in sys.argv:
        rows = eip_only(rows)

    print(json.dumps(rows, indent=2))


if __name__ == "__main__":
    main()
