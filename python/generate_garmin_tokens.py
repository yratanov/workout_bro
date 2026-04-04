#!/usr/bin/python3
"""
Login to Garmin Connect once and save tokens locally.
Run this from your local machine (not the server) to avoid rate limits.
Tokens are saved to storage/garmin_tokens/ and can be uploaded to prod.
"""

import os
import sys

from garminconnect import Garmin

TOKEN_DIR = os.path.join(os.path.dirname(__file__), "..", "storage", "garmin_tokens")


def main():
    if len(sys.argv) < 3:
        print(f"Usage: {sys.argv[0]} <username> <password>")
        sys.exit(1)

    username = sys.argv[1]
    password = sys.argv[2]

    print(f"Logging in as {username}...")
    garmin = Garmin(username, password)
    garmin.login()

    os.makedirs(TOKEN_DIR, exist_ok=True)
    garmin.garth.dump(TOKEN_DIR)
    print(f"Tokens saved to {TOKEN_DIR}/")
    print("oauth1_token.json and oauth2_token.json created.")
    print()
    print("Now upload to prod:")
    print(f"  scp -P $DEPLOY_SERVER_PORT {TOKEN_DIR}/oauth*.json $DEPLOY_SERVER_IP:$DEPLOY_REMOTE_PATH/storage/garmin_tokens/")


if __name__ == "__main__":
    main()
