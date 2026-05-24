from pydantic import BaseModel

class Results(BaseModel):
    user_id: int 
    lang: str
    lesson_id: int | None = 0
    module_id: int| None = 0
    course_id: int | None = 0
    exercise_id: int| None = 0
    sentence_id: int | None = 0
    word1: str| None = ''
    word2: str| None = ''
    word3: str| None = ''
    answer_delay_ms: str| None = 0
    attempts: int| None = 0
    correct: bool| None = False
    correct_ratio: float| None = 0.0
    incorrect_count: float| None = 0.0
    




class UserStats(BaseModel):
    user_id: int
    lang: str
    lessons: int
    words: int
    sentences: int
    exercises: int = 0

class UserData(BaseModel):
    user_id: int
    language: str
    to_lang: str


class PasswordLoginRequest(BaseModel):
    """Payload for POST /api/v1/auth/login_with_password — sign-up-or-
    sign-in flow used by the learner app for local testing. If the
    email is new, the server creates the user with the given password;
    if it already exists, the server verifies the password and returns
    401 on mismatch."""
    email: str
    password: str


class UserAuth0Request(BaseModel):
    """Payload for POST /api/v1/auth/get_or_create_user.

    The client passes the Auth0-issued ID token; the server verifies
    it against the tenant JWKS and pulls the verified `email`, `name`,
    `sub` claims rather than trusting client-supplied values. The
    plain `email`/`name`/`sub` fields are optional — useful for the
    local-dev `--auth=local` shortcut where there's no Auth0 in play."""
    # Verified path: the Auth0 ID token. When present, server-extracted
    # claims override any locally supplied fields.
    id_token: str | None = None
    # Unverified fallback for the dev path. Server uses these when no
    # id_token is supplied AND the route is configured to allow it.
    email: str | None = None
    name: str | None = None
    sub: str | None = None


class UserPref(BaseModel):
    """Return shape for the auth routes — combines the bare user row
    with the most-recent Preference so the home page can paint without
    a second round-trip. `preference` is null for a brand-new user who
    hasn't picked a course yet."""
    user_id: int
    email: str
    name: str
    preference: dict | None = None
