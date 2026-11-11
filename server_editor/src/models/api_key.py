from datetime import datetime
from enum import Enum

from pydantic import BaseModel, Field, SecretStr


class ApiKeyScope(Enum):
    SCHOOL = "school"  # shared by the school's users; stored with user_id NULL
    USER = "user"  # the user's own key, used before the school's


class ApiKeyInfo(BaseModel):
    """A stored key as the API shows it: never the key itself."""
    provider: str
    scope: ApiKeyScope
    last4: str
    updated_at: datetime


class ApiKeySave(BaseModel):
    provider: str
    scope: ApiKeyScope
    # SecretStr keeps the key out of logs and reprs, such as a printed request.
    api_key: SecretStr = Field(..., min_length=8, max_length=512)
