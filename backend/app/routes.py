from datetime import date, datetime, time
from typing import Annotated
from fastapi import APIRouter, Depends, HTTPException, Query, Request
from .schemas import Health, Category, Location, Latest, Observation
from .service import Service

router = APIRouter(prefix="/api")

def database(request: Request):
    return request.app.state.db

DB = Annotated[object, Depends(database)]
Text = Annotated[str, Query(min_length=1, max_length=100, pattern=r"^\S(?:.*\S)?$")]

@router.get("/health", response_model=Health)
def health():
    return {"status": "ok"}

@router.get("/health/db", response_model=Health)
def readiness(db: DB):
    db.query("SELECT 1 AS ready FROM dual")
    return {"status": "ready"}

@router.get("/categories", response_model=list[Category])
def categories(db: DB):
    return db.query("SELECT category_id,category_name,description FROM category ORDER BY category_name FETCH FIRST 100 ROWS ONLY")

@router.get("/locations", response_model=list[Location])
def locations(db: DB):
    return db.query("SELECT DISTINCT location FROM price_history ORDER BY location FETCH FIRST 100 ROWS ONLY")

@router.get("/prices/latest", response_model=list[Latest], description="Synthetic demo prices. Exact three-calendar-month change; null when baseline is missing. History is the latest nine dated observations, not necessarily nine months.")
def latest(db: DB, location: Text, category_id: int | None = Query(None,gt=0),
           product_id: int | None = Query(None,gt=0),search: str | None = Query(None,max_length=100),
           limit: int = Query(50,ge=1,le=100),offset: int = Query(0,ge=0,le=10000)):
    return Service(db).latest(location=location,category_id=category_id,product_id=product_id,
                              search=search,limit=limit,offset=offset)

@router.get("/prices/history", response_model=list[Observation], description="Inclusive dates; returns most recent limited observations in ascending date order.")
def history(db: DB, location: Text, product_id: int = Query(...,gt=0),
            date_from: date | None = None,date_to: date | None = None,
            limit: int = Query(100,ge=1,le=500)):
    if date_from and date_to and date_from>date_to:
        raise HTTPException(422,"date_from must be on or before date_to")
    return Service(db).history(product_id=product_id,location=location,
        date_from=datetime.combine(date_from,time.min) if date_from else None,
        date_to=datetime.combine(date_to,time.min) if date_to else None,limit=limit)
