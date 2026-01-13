#!/usr/bin/python3
"""
Sync running activities from Garmin Connect to the workout_bro database.
Reads credentials from .env file and inserts new run workouts.
"""

import os
import sqlite3
from datetime import datetime, timedelta
from pathlib import Path

from dotenv import load_dotenv
from garminconnect import Garmin


def get_db_path():
    """Get the path to the SQLite database."""
    script_dir = Path(__file__).parent
    # In Docker container, DB is at /rails/storage/production.sqlite3
    # Locally for development, it's at ../storage/development.sqlite3
    production_db = script_dir.parent / "storage" / "production.sqlite3"
    development_db = script_dir.parent / "storage" / "development.sqlite3"

    if production_db.exists():
        return production_db
    return development_db


def get_user_id(conn):
    """Get the first user's ID from the database."""
    cursor = conn.cursor()
    cursor.execute("SELECT id FROM users LIMIT 1")
    result = cursor.fetchone()
    if result:
        return result[0]
    raise RuntimeError("No user found in database")


def activity_exists(conn, started_at):
    """Check if a workout with this started_at already exists."""
    cursor = conn.cursor()
    cursor.execute(
        "SELECT id FROM workouts WHERE started_at = ? AND workout_type = 1",
        (started_at,)
    )
    return cursor.fetchone() is not None


def insert_run_workout(conn, user_id, started_at, ended_at, distance_meters, duration_seconds):
    """Insert a new run workout into the database."""
    cursor = conn.cursor()
    date = started_at.date().isoformat()

    cursor.execute(
        """
        INSERT INTO workouts (
            user_id, workout_type, date, started_at, ended_at,
            distance, time_in_seconds, created_at, updated_at
        ) VALUES (?, 1, ?, ?, ?, ?, ?, ?, ?)
        """,
        (
            user_id,
            date,
            started_at.isoformat(),
            ended_at.isoformat() if ended_at else None,
            int(distance_meters),
            int(duration_seconds),
            datetime.now().isoformat(),
            datetime.now().isoformat(),
        )
    )
    conn.commit()
    return cursor.lastrowid


def parse_garmin_datetime(dt_str):
    """Parse Garmin's datetime format."""
    # Garmin returns format like "2024-01-15 08:30:00"
    if dt_str:
        try:
            return datetime.fromisoformat(dt_str.replace(" ", "T"))
        except ValueError:
            # Try alternative format
            return datetime.strptime(dt_str, "%Y-%m-%d %H:%M:%S")
    return None


def sync_garmin_activities():
    """Main sync function."""
    # Load environment variables from .env file
    env_path = Path(__file__).parent.parent / ".env"
    load_dotenv(env_path)

    username = os.getenv("GARMIN_USERNAME")
    password = os.getenv("GARMIN_PASSWORD")

    if not username or not password:
        print("Error: GARMIN_USERNAME and GARMIN_PASSWORD must be set in .env file")
        return

    print(f"Connecting to Garmin as {username}...")

    # Initialize Garmin client
    garmin = Garmin(username, password)
    garmin.login()

    print("Successfully logged in to Garmin Connect")

    # Get activities from the last 7 days
    end_date = datetime.now()
    start_date = end_date - timedelta(days=7)

    activities = garmin.get_activities_by_date(
        start_date.strftime("%Y-%m-%d"),
        end_date.strftime("%Y-%m-%d"),
        activitytype="running"
    )

    print(f"Found {len(activities)} running activities in the last 7 days")

    # Connect to database
    db_path = get_db_path()
    print(f"Using database: {db_path}")

    conn = sqlite3.connect(db_path)
    user_id = get_user_id(conn)

    imported_count = 0
    skipped_count = 0

    for activity in activities:
        # Extract activity data
        started_at_str = activity.get("startTimeLocal")
        started_at = parse_garmin_datetime(started_at_str)

        if not started_at:
            print(f"Skipping activity with no start time: {activity.get('activityId')}")
            continue

        # Check if already imported
        if activity_exists(conn, started_at.isoformat()):
            print(f"Skipping already imported activity from {started_at}")
            skipped_count += 1
            continue

        # Get activity details
        distance_meters = activity.get("distance", 0)
        duration_seconds = activity.get("duration", 0)

        # Calculate ended_at
        ended_at = started_at + timedelta(seconds=duration_seconds) if duration_seconds else None

        # Insert into database
        workout_id = insert_run_workout(
            conn, user_id, started_at, ended_at, distance_meters, duration_seconds
        )

        print(f"Imported run: {started_at} - {distance_meters/1000:.2f}km in {duration_seconds/60:.1f}min (ID: {workout_id})")
        imported_count += 1

    conn.close()

    print(f"\nSync complete: {imported_count} imported, {skipped_count} skipped")


if __name__ == "__main__":
    sync_garmin_activities()
