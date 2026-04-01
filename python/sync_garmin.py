#!/usr/bin/python3
"""
Fetch running activities from Garmin Connect and output as JSON.
Credentials are passed as command-line arguments.
Uses garth token persistence to avoid repeated logins and rate limits.
"""

import json
import os
import sys
from datetime import datetime, timedelta

import garth
from garminconnect import Garmin
from garth.exc import GarthHTTPError

TOKEN_DIR = os.path.join(os.path.dirname(__file__), "..", "storage", "garmin_tokens")


def login_garmin(username, password, force_login=False):
    """Login to Garmin, reusing saved tokens when possible."""
    garmin = Garmin(username, password)

    if not force_login and os.path.exists(TOKEN_DIR):
        try:
            garmin.garth.load(TOKEN_DIR)
            garmin.display_name = garmin.garth.profile["displayName"]
            return garmin
        except Exception:
            pass

    garmin.login()
    os.makedirs(TOKEN_DIR, exist_ok=True)
    garmin.garth.dump(TOKEN_DIR)
    return garmin


def fetch_garmin_activities(username, password, days=7):
    """Fetch running activities from Garmin Connect."""
    garmin = login_garmin(username, password)

    end_date = datetime.now()
    start_date = end_date - timedelta(days=days)

    try:
        activities = garmin.get_activities_by_date(
            start_date.strftime("%Y-%m-%d"),
            end_date.strftime("%Y-%m-%d"),
            activitytype="running"
        )
    except GarthHTTPError as e:
        if "429" in str(e):
            raise  # Don't retry on rate limit — retrying makes it worse
        # Only re-login on auth errors (401/403), not on all failures
        garmin = login_garmin(username, password, force_login=True)
        activities = garmin.get_activities_by_date(
            start_date.strftime("%Y-%m-%d"),
            end_date.strftime("%Y-%m-%d"),
            activitytype="running"
        )
    except Exception:
        garmin = login_garmin(username, password, force_login=True)
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
            "avg_heart_rate": activity.get("averageHR"),
            "max_heart_rate": activity.get("maxHR"),
            "avg_cadence": activity.get("averageRunningCadenceInStepsPerMinute"),
            "elevation_gain": activity.get("elevationGain"),
            "vo2max": activity.get("vO2MaxValue"),
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
