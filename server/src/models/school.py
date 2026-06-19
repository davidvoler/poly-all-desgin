from pydantic import BaseModel
from datetime import datetime as DateTime



class School(BaseModel):
    school_id: int | None = None
    name: str | None = None
    plan: str | None = 'free'                       # free | pro | enterprise
    school_type: str = 'private'             # public | no_charge | private
    logo_url: str | None = None
    primary_color: str = '#1E88E5'
    domain: str | None = None
    dashboard: bool = False

