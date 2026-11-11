"""Re-encrypts the stored AI API keys with the newest master key.

To rotate: add AI_KEYS_MASTER_KEY_V<n+1> next to the current one, restart the
editor server and worker, run this script, then remove the old master key once
it reports no rows left on it.

    cd server_editor/src && python -m scripts.rotate_ai_keys
"""
import asyncio

from utils import secret_box
from utils.api_keys import _context
from utils.db import get_query_results, run_query


async def rotate() -> None:
    version = secret_box.current_version()
    rows = await get_query_results(
        "SELECT api_key_id, school, user_id, provider, ciphertext, key_version"
        " FROM secrets.ai_api_key WHERE key_version <> %(version)s",
        {"version": version},
    )
    failed = 0
    for r in rows:
        context = _context(r["school"], r["user_id"], r["provider"])
        try:
            key = secret_box.decrypt(bytes(r["ciphertext"]), r["key_version"], context)
        except secret_box.SecretBoxError as e:
            failed += 1
            print(f"Skipped key {r['api_key_id']}: {e}")
            continue
        ciphertext, new_version = secret_box.encrypt(key, context)
        await run_query(
            "UPDATE secrets.ai_api_key SET ciphertext = %(c)s, key_version = %(v)s"
            " WHERE api_key_id = %(id)s",
            {"c": ciphertext, "v": new_version, "id": r["api_key_id"]},
        )
    print(f"Re-encrypted {len(rows) - failed} keys with master key v{version}; {failed} skipped.")


if __name__ == "__main__":
    asyncio.run(rotate())
