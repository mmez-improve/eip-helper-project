#!/usr/bin/env python3
"""
eip_export.py - Deterministic filter + CSV builder for Outlook calendar category/showAs exports.

Part of the "outlook-calendar-category-export" Cowork skill. This script does the actual
filtering and CSV construction as real code (not LLM judgment), specifically to avoid the
error-prone manual-review approach that once dropped a recurring meeting from an export.

Usage:
    python eip_export.py filter <raw_events.json> <matches_out.json> --category EIP --showas oof
    python eip_export.py csv <matches_full.json> <output.csv>

Input event schema expected by `filter` (one JSON array of objects):
    {
        "uri": str,                # calendar:///events/{id}, used to fetch full detail if needed
        "subject": str,
        "isOrganizer": bool,
        "start": {"dateTime": "2026-09-02T15:30:00.0000000"},
        "end":   {"dateTime": "2026-09-02T16:00:00.0000000"},
        "isAllDay": bool,
        "categories": [str] | null,
        "showAs": str,              # e.g. "busy", "free", "tentative", "oof"
        "summary": str,             # optional description/body preview text
        "my_response": str          # optional; own RSVP status if already resolved
    }

The `csv` command reads the output of `filter` (or a manually-enriched copy of it) and writes
a sorted CSV with columns: Event Title, Date, Time (UTC), Categories, Show As Status,
Match Reason, Description, My Response.
"""
import argparse
import csv as csv_module
import html
import json
import re
from datetime import datetime, timedelta


def strip_html(raw):
    if not raw:
        return ""
    text = re.sub(r"<[^>]+>", " ", raw)
    text = html.unescape(text)
    text = re.sub(r"[ \t]+", " ", text)
    text = re.sub(r"\n\s*\n+", "\n", text)
    return text.strip()


def cmd_filter(args):
    with open(args.input, "r", encoding="utf-8") as f:
        events = json.load(f)

    category = args.category
    showas = args.showas

    matches = []
    cat_only = 0
    showas_only = 0
    both = 0

    for ev in events:
        categories = ev.get("categories") or []
        ev_showas = ev.get("showAs")

        cat_hit = bool(category) and any(
            c.strip().lower() == category.strip().lower() for c in categories
        )
        showas_hit = bool(showas) and ev_showas == showas

        if not (cat_hit or showas_hit):
            continue

        if cat_hit and showas_hit:
            reason = "both"
            both += 1
        elif cat_hit:
            reason = f"category:{category}"
            cat_only += 1
        else:
            reason = f"showAs:{showas}"
            showas_only += 1

        matches.append({**ev, "match_reason": reason})

    result = {
        "total_events_scanned": len(events),
        "total_matches": len(matches),
        "matched_category_only": cat_only,
        "matched_showas_only": showas_only,
        "matched_both": both,
        "matches": matches,
    }

    with open(args.output, "w", encoding="utf-8") as f:
        json.dump(result, f, indent=2)

    print(f"Scanned {len(events)} events. Matched {len(matches)} "
          f"(category only: {cat_only}, showAs only: {showas_only}, both: {both}).")
    print(f"Wrote {args.output}")
    for m in matches:
        print(f"  {m['start']['dateTime'][:10]}  {m['subject']}  [{m['match_reason']}]"
              f"  organizer={m.get('isOrganizer', False)}")


def parse_graph_datetime(raw):
    """Graph API returns fractional seconds with up to 7 digits (.NET ticks-style
    precision), but Python's datetime only accepts up to 6-digit microseconds.
    Truncate/pad the fractional part instead of relying on strict fromisoformat."""
    raw = raw.replace("Z", "")
    if "." in raw:
        base, frac = raw.split(".", 1)
        frac = (frac + "000000")[:6]
        raw = f"{base}.{frac}"
    return datetime.fromisoformat(raw)


def format_date_range(start, end, is_all_day):
    start_dt = parse_graph_datetime(start["dateTime"])
    end_dt = parse_graph_datetime(end["dateTime"])

    if is_all_day:
        end_display = end_dt
        if end_dt.time() == datetime.min.time():
            end_display = end_dt - timedelta(days=1)
        if start_dt.date() == end_display.date():
            return start_dt.strftime("%Y-%m-%d"), "All day"
        return f"{start_dt.strftime('%Y-%m-%d')} to {end_display.strftime('%Y-%m-%d')}", "All day"

    date_str = start_dt.strftime("%Y-%m-%d")
    time_str = f"{start_dt.strftime('%H:%M')}-{end_dt.strftime('%H:%M')}"
    return date_str, time_str


def cmd_csv(args):
    with open(args.input, "r", encoding="utf-8") as f:
        data = json.load(f)

    matches = data["matches"] if isinstance(data, dict) and "matches" in data else data

    rows = []
    for m in matches:
        date_str, time_str = format_date_range(m["start"], m["end"], m.get("isAllDay", False))
        body = m.get("body")
        if isinstance(body, dict):
            description = strip_html(body.get("content")) or m.get("bodyPreview") or m.get("summary") or ""
        else:
            description = m.get("bodyPreview") or m.get("summary") or ""

        rows.append({
            "sort_key": m["start"]["dateTime"],
            "Event Title": m.get("subject", ""),
            "Date": date_str,
            "Time (UTC)": time_str,
            "Categories": "; ".join(m.get("categories") or []),
            "Show As Status": m.get("showAs", ""),
            "Match Reason": m.get("match_reason", ""),
            "Description": description[:2000],
            "My Response": m.get("my_response", "Organizer" if m.get("isOrganizer") else "Unknown"),
        })

    rows.sort(key=lambda r: r["sort_key"])

    fieldnames = ["Event Title", "Date", "Time (UTC)", "Categories", "Show As Status",
                  "Match Reason", "Description", "My Response"]

    with open(args.output, "w", newline="", encoding="utf-8") as f:
        writer = csv_module.DictWriter(f, fieldnames=fieldnames, quoting=csv_module.QUOTE_ALL)
        writer.writeheader()
        for r in rows:
            writer.writerow({k: r[k] for k in fieldnames})

    print(f"Wrote {len(rows)} rows to {args.output}")


def main():
    parser = argparse.ArgumentParser(description="Calendar category/showAs export helper")
    sub = parser.add_subparsers(dest="command", required=True)

    p_filter = sub.add_parser("filter")
    p_filter.add_argument("input")
    p_filter.add_argument("output")
    p_filter.add_argument("--category", default="EIP")
    p_filter.add_argument("--showas", default="oof")
    p_filter.set_defaults(func=cmd_filter)

    p_csv = sub.add_parser("csv")
    p_csv.add_argument("input")
    p_csv.add_argument("output")
    p_csv.set_defaults(func=cmd_csv)

    args = parser.parse_args()
    args.func(args)


if __name__ == "__main__":
    main()
