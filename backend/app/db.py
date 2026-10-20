from threading import Lock
import oracledb

class DatabaseUnavailable(Exception):
    pass

class Database:
    """Lazy bounded Thin-mode pool; failed startup does not disable liveness."""
    def __init__(self, settings):
        self.settings = settings
        self.pool = None
        self.lock = Lock()

    def query(self, sql, binds=None):
        try:
            with self.lock:
                if self.pool is None:
                    if not self.settings.db_password:
                        raise DatabaseUnavailable()
                    self.pool = oracledb.create_pool(
                        user=self.settings.db_user,
                        password=self.settings.db_password.get_secret_value(),
                        dsn=self.settings.db_dsn, min=0, max=4, increment=1,
                        getmode=oracledb.POOL_GETMODE_TIMEDWAIT, wait_timeout=3000,
                        tcp_connect_timeout=5)
            with self.pool.acquire() as connection:
                connection.call_timeout = 10000
                with connection.cursor() as cursor:
                    cursor.execute("SET TRANSACTION READ ONLY")
                    cursor.execute(sql, binds or {})
                    columns = [c[0].lower() for c in cursor.description]
                    return [dict(zip(columns, row)) for row in cursor.fetchall()]
        except oracledb.Error:
            raise DatabaseUnavailable() from None

    def close(self):
        if self.pool:
            self.pool.close(force=True)
