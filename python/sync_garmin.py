#!/usr/bin/python3
"""
Fetch running activities from Garmin Connect and output as JSON.
Credentials are passed as command-line arguments.
"""

import json
import sys
from datetime import datetime, timedelta

from garminconnect import Garmin


def fetch_garmin_activities(username, password, days=7):
    """Fetch running activities from Garmin Connect."""
    garmin = Garmin(username, password)
    garmin.login()

    end_date = datetime.now()
    start_date = end_date - timedelta(days=days)

    activities = garmin.get_activities_by_date(
        start_date.strftime("%Y-%m-%d"),
        end_date.strftime("%Y-%m-%d"),
        activitytype="running"
    )

    result = []
    for activity in activities:
        started_at_str = activity.get("startTimeLocal")
        if not started_at_str:
            continue

        distance_meters = activity.get("distance", 0)
        duration_seconds = activity.get("duration", 0)

        result.append({
            "started_at": started_at_str.replace(" ", "T"),
            "distance_meters": distance_meters,
            "duration_seconds": duration_seconds,
        })

    return result


def main():
    if len(sys.argv) < 3:
        print(json.dumps({"error": "Usage: sync_garmin.py <username> <password> [days]"}))
        sys.exit(1)

    username = sys.argv[1]
    password = sys.argv[2]
    days = int(sys.argv[3]) if len(sys.argv) > 3 else 7

    try:
        activities = fetch_garmin_activities(username, password, days)
        print(json.dumps({"activities": activities}))
    except Exception as e:
        print(json.dumps({"error": str(e)}))
        sys.exit(1)


if __name__ == "__main__":
    main()
