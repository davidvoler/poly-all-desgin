#!/usr/bin/env python3
"""Add or update a learner-app user with a bcrypt-hashed password.

Why this exists
---------------
The /api/v1/auth/login_with_password route is sign-up-or-sign-in: the
first hit for a new email creates the row. That's fine for testing
through the UI, but a CLI is friendlier when you need to seed a known
account (CI fixtures, demo data, "reset a forgotten password without
hitting the UI"). Hashes use the same bcrypt-12 cost as the server so
hashes created here are interchangeable with ones written by the route.

Usage
-----
Inside the running server container (recommended — picks up the same
POSTGRES_* env vars as the server):

    docker exec -it server python scripts/add_user.py demo@local.dev changeme
    docker exec -it server python scripts/add_user.py alice@example.com s3cret

From the host (if you've mapped postgres to 127.0.0.1:5432 as
docker-compose.yaml does):

    POSTGRES_HOST=127.0.0.1 python server/src/scripts/add_user.py \\
        demo@local.dev changeme

Behaviour
---------
* Email lookup is case-insensitive.
* Existing email → updates `password_hash` only. Other columns left
  alone so the row's `first_login` / `school` / etc. stay intact.
* New email     → INSERTs with email + email_hash + password_hash.
                  email_hash matches the algorithm used by the auth
                  route (sha256 of the lowercased email, truncated to
                  64 chars).
* Prints the resulting user_id so callers can pipe it to other tools.
"""
from __future__ import annotations

import argparse
import hashlib
import os
import sys

import bcrypt
import psycopg

# When this runs inside the server container, /app is on the import
# path and `utils.db` is the canonical source for the connection
# string (it reads POSTGRES_USER/PASSWORD/HOST/PORT/DB from the env).
# When run on the host, fall back to env-only resolution so the script
# is still usable without a checkout-aware PYTHONPATH.
sys.path.insert(0, "/app")
try:
    from utils.db import get_pg_connection_string  # type: ignore
except ImportError:  # pragma: no cover — host-fallback path
    def get_pg_connection_string() -> str:
        return (
            f"postgresql://{os.getenv('POSTGRES_USER', 'polyglots')}:"
            f"{os.getenv('POSTGRES_PASSWORD', 'polyglots')}@"
            f"{os.getenv('POSTGRES_HOST', 'localhost')}:"
            f"{os.getenv('POSTGRES_PORT', '5432')}/"
            f"{os.getenv('POSTGRES_DB', 'polyglots')}"
        )


def hash_password(plain: str) -> str:
    """Match the server's hasher exactly: bcrypt 12 rounds, input
    truncated to bcrypt's 72-byte hard limit."""
    pw = plain.encode("utf-8")[:72]
    return bcrypt.hashpw(pw, bcrypt.gensalt(rounds=12)).decode("ascii")


def email_hash_of(email: str) -> str:
    return hashlib.sha256(email.encode("utf-8")).hexdigest()[:64]


def upsert_user(email: str, password: str) -> tuple[int, str]:
    """Returns (user_id, 'created' | 'updated')."""
    conn_str = get_pg_connection_string()
    pw_hash = hash_password(password)
    with psycopg.connect(conn_str, autocommit=True) as conn:
        with conn.cursor() as cur:
            cur.execute(
                "SELECT user_id FROM user_data.users "
                "WHERE LOWER(email) = %s LIMIT 1",
                (email,),
            )
            row = cur.fetchone()
            if row:
                user_id = int(row[0])
                cur.execute(
                    "UPDATE user_data.users SET password_hash = %s "
                    "WHERE user_id = %s",
                    (pw_hash, user_id),
                )
                return user_id, "updated"
            cur.execute(
                """
                INSERT INTO user_data.users
                    (email, email_hash, password_hash)
                VALUES (%s, %s, %s)
                RETURNING user_id
                """,
                (email, email_hash_of(email), pw_hash),
            )
            new_row = cur.fetchone()
            if not new_row:
                raise RuntimeError("INSERT did not return a user_id")
            return int(new_row[0]), "created"


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Add or update a learner-app user with a bcrypt-hashed "
                    "password.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__,
    )
    parser.add_argument("email", help="User's email (case-insensitive).")
    parser.add_argument("password", help="Plaintext password to hash + store.")
    args = parser.parse_args()

    email = args.email.strip().lower()
    if not email or not args.password:
        print("error: email and password are required", file=sys.stderr)
        return 2

    user_id, action = upsert_user(email, args.password)
    print(f"{action} user_id={user_id} email={email}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
