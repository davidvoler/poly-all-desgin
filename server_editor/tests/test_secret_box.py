import os

import pytest

from utils import secret_box

KEY_1 = "11" * 32
KEY_2 = "22" * 32


@pytest.fixture(autouse=True)
def master_keys(monkeypatch):
    for name in list(os.environ):
        if name.startswith("AI_KEYS_MASTER_KEY_V"):
            monkeypatch.delenv(name)
    monkeypatch.setenv("AI_KEYS_MASTER_KEY_V1", KEY_1)


def test_round_trip_without_the_plain_key_in_the_ciphertext():
    blob, version = secret_box.encrypt("sk-secret-1234", "ctx")
    assert version == 1
    assert b"sk-secret" not in blob
    assert secret_box.decrypt(blob, version, "ctx") == "sk-secret-1234"


def test_same_key_encrypts_differently_each_time():
    assert secret_box.encrypt("k" * 10, "ctx")[0] != secret_box.encrypt("k" * 10, "ctx")[0]


def test_ciphertext_moved_to_another_row_does_not_decrypt():
    blob, version = secret_box.encrypt("sk-secret", "ai_api_key:school-a::gemini")
    with pytest.raises(secret_box.SecretBoxError):
        secret_box.decrypt(blob, version, "ai_api_key:school-b::gemini")


def test_new_secrets_use_the_newest_master_key_and_old_ones_still_decrypt(monkeypatch):
    old, v1 = secret_box.encrypt("old", "ctx")
    monkeypatch.setenv("AI_KEYS_MASTER_KEY_V2", KEY_2)
    new, v2 = secret_box.encrypt("new", "ctx")
    assert (v1, v2) == (1, 2)
    assert secret_box.decrypt(old, v1, "ctx") == "old"
    assert secret_box.decrypt(new, v2, "ctx") == "new"


def test_without_master_key_secrets_are_plain_text(monkeypatch):
    blob, _ = secret_box.encrypt("x" * 8, "ctx")
    monkeypatch.delenv("AI_KEYS_MASTER_KEY_V1")
    plain, version = secret_box.encrypt("sk-plain-1234", "ctx")
    assert (plain, version) == (b"sk-plain-1234", secret_box.PLAIN_TEXT_VERSION)
    assert secret_box.decrypt(plain, version, "ctx") == "sk-plain-1234"
    # Keys encrypted earlier still need their master key.
    with pytest.raises(secret_box.SecretBoxError):
        secret_box.decrypt(blob, 1, "ctx")


def test_plain_text_rows_stay_readable_after_adding_a_master_key(monkeypatch):
    monkeypatch.delenv("AI_KEYS_MASTER_KEY_V1")
    plain, version = secret_box.encrypt("sk-plain", "ctx")
    monkeypatch.setenv("AI_KEYS_MASTER_KEY_V1", KEY_1)
    assert secret_box.decrypt(plain, version, "ctx") == "sk-plain"
    assert secret_box.encrypt("sk-new-key", "ctx")[1] == 1


def test_master_key_must_be_32_bytes(monkeypatch):
    monkeypatch.setenv("AI_KEYS_MASTER_KEY_V1", "abcd")
    with pytest.raises(secret_box.SecretBoxError):
        secret_box.encrypt("x" * 8, "ctx")
