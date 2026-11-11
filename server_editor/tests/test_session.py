import time

import pytest
from jose import jwt

from utils import session

SECRET = "s" * 40


@pytest.fixture(autouse=True)
def secret(monkeypatch):
    monkeypatch.setenv("EDITOR_SESSION_SECRET", SECRET)


def test_token_names_the_user_and_school():
    assert session.read_token(session.create_token(5, 1)) == (5, 1)


def test_edited_token_is_rejected():
    header, payload, signature = session.create_token(5, 1).split(".")
    other_payload = session.create_token(7, 1).split(".")[1]
    with pytest.raises(session.SessionError):
        session.read_token(f"{header}.{other_payload}.{signature}")


def test_token_signed_with_another_secret_is_rejected(monkeypatch):
    token = session.create_token(5, 1)
    monkeypatch.setenv("EDITOR_SESSION_SECRET", "t" * 40)
    with pytest.raises(session.SessionError):
        session.read_token(token)


def test_expired_token_is_rejected():
    token = jwt.encode({"sub": "5", "school_id": 1, "typ": "editor_session",
                        "iat": 0, "exp": int(time.time()) - 1}, SECRET, algorithm="HS256")
    with pytest.raises(session.SessionError):
        session.read_token(token)


def test_other_jwt_types_are_rejected():
    token = jwt.encode({"sub": "5", "school_id": 1, "exp": int(time.time()) + 60},
                       SECRET, algorithm="HS256")
    with pytest.raises(session.SessionError):
        session.read_token(token)


def test_short_or_missing_secret_is_an_error(monkeypatch):
    monkeypatch.setenv("EDITOR_SESSION_SECRET", "short")
    with pytest.raises(session.SessionError):
        session.create_token(5, 1)
