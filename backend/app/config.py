from pydantic import SecretStr, field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict

class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")
    db_user: str = "IIA_EVAL_20261020"
    db_password: SecretStr | None = None
    db_dsn: str = "localhost:1521/XEPDB1"
    frontend_origin: str = "http://localhost:5173"

    @field_validator("db_user")
    @classmethod
    def application_user(cls, value):
        if value.upper() in {"SYS", "SYSTEM", "PDBADMIN"}:
            raise ValueError("Use a dedicated application account")
        return value
