from unittest.mock import MagicMock,patch
import pytest
import oracledb
from app.db import Database,DatabaseUnavailable
from app.config import Settings

def test_pool_uses_readonly_and_releases_cursor_and_connection():
    pool=MagicMock()
    connection=pool.acquire.return_value.__enter__.return_value
    cursor=connection.cursor.return_value.__enter__.return_value
    cursor.description=[('PRICE',)]
    cursor.fetchall.return_value=[(54,)]
    with patch('app.db.oracledb.create_pool',return_value=pool) as create:
        db=Database(Settings(db_password='test-only-not-a-real-credential'))
        assert db.query('SELECT price FROM price_history WHERE product_id=:id',{'id':1})==[{'price':54}]
        assert create.call_args.kwargs['max']==4
        assert cursor.execute.call_args_list[0].args==('SET TRANSACTION READ ONLY',)
        assert connection.cursor.return_value.__exit__.called
        assert pool.acquire.return_value.__exit__.called
        db.close()
        pool.close.assert_called_once_with(force=True)

def test_driver_error_is_sanitized():
    with patch('app.db.oracledb.create_pool',side_effect=oracledb.DatabaseError('private error text')):
        with pytest.raises(DatabaseUnavailable) as error:
            Database(Settings(db_password='test-only-not-a-real-credential')).query('SELECT 1 FROM dual')
        assert 'private' not in str(error.value)
