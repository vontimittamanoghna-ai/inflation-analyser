from contextlib import asynccontextmanager
from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from .config import Settings
from .db import Database, DatabaseUnavailable
from .routes import router

@asynccontextmanager
async def lifespan(app):
    app.state.db = Database(Settings())
    yield
    app.state.db.close()

app = FastAPI(title="Inflation Impact Analyser",version="1.0.0",lifespan=lifespan)
app.add_middleware(CORSMiddleware,allow_origins=[Settings().frontend_origin],
                   allow_methods=["GET"],allow_headers=["Accept"],allow_credentials=False)

@app.exception_handler(DatabaseUnavailable)
def unavailable(request: Request, exc: DatabaseUnavailable):
    return JSONResponse(status_code=503,content={"detail":"Database unavailable. Check backend configuration privately."})

@app.exception_handler(Exception)
def unexpected(request: Request, exc: Exception):
    return JSONResponse(status_code=500,content={"detail":"Request could not be completed."})

app.include_router(router)
