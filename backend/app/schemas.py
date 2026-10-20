from datetime import date
from pydantic import BaseModel

class Health(BaseModel):
    status: str

class Category(BaseModel):
    category_id: int
    category_name: str
    description: str | None

class Location(BaseModel):
    location: str

class Observation(BaseModel):
    observed_date: date
    price: float
    source: str

class Latest(BaseModel):
    product_id: int
    category_id: int
    category_name: str
    product_name: str
    unit: str
    brand: str
    active_status: str
    location: str
    observed_date: date
    price: float
    source: str
    change_pct: float | None
    comparison_date: date
    history: list[Observation]
