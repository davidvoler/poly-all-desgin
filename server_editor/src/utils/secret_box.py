"""Encrypts secrets, such as AI API keys, before they are stored in Postgres.

The master keys come from the environment, never the database:

    AI_KEYS_MASTER_KEY_V1=<64 hex chars>   # python -c "import os;print(os.urandom(32).hex())"
    AI_KEYS_MASTER_KEY_V2=...              # add a new version to rotate

New secrets use the highest version. Older versions stay readable until
scripts/rotate_ai_keys.py re-encrypts their rows.
"""
import os
import re

from cryptography.exceptions import InvalidTag
from cryptography.hazmat.primitives.ciphers.aead import AESGCM

_ENV = re.compile(r"^AI_KEYS_MASTER_KEY_V(\d+)$")
_NONCE_SIZE = 12


class SecretBoxError(Exception):
    pass


def _master_keys() -> dict[int, bytes]:
    keys = {}
    for name, value in os.environ.items():
        match = _ENV.match(name)
        if not match or not value:
            continue
        try:
            key = bytes.fromhex(value.strip())
        except ValueError:
            raise SecretBoxError(f"{name} is not hex")
        if len(key) != 32:
            raise SecretBoxError(f"{name} must be 32 bytes (64 hex characters)")
        keys[int(match.group(1))] = key
    return keys


def current_version() -> int:
    keys = _master_keys()
    if not keys:
        raise SecretBoxError("No AI_KEYS_MASTER_KEY_V1 is set, so API keys cannot be stored")
    return max(keys)


def encrypt(secret: str, context: str) -> tuple[bytes, int]:
    """Returns the ciphertext and the master key version that made it.
    [context] binds the ciphertext to its row: it only decrypts with the same one."""
    version = current_version()
    nonce = os.urandom(_NONCE_SIZE)
    sealed = AESGCM(_master_keys()[version]).encrypt(nonce, secret.encode(), context.encode())
    return nonce + sealed, version


def decrypt(blob: bytes, version: int, context: str) -> str:
    key = _master_keys().get(version)
    if key is None:
        raise SecretBoxError(f"AI_KEYS_MASTER_KEY_V{version} is not set")
    try:
        return AESGCM(key).decrypt(
            blob[:_NONCE_SIZE], blob[_NONCE_SIZE:], context.encode()).decode()
    except InvalidTag:
        raise SecretBoxError("The secret does not decrypt: wrong master key or row")
