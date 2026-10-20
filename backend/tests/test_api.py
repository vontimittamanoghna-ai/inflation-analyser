import pytest
from fastapi.testclient import TestClient
from app.main import app
from app.routes import database
from app.db import DatabaseUnavailable
from app.config import Settings

class Fake:
    def __init__(self): self.calls=[]
    def query(self,sql,binds=None):
        self.calls.append((sql,binds))
        if 'FROM category' in sql: return [{"category_id":1,"category_name":"Food","description":None}]
        if 'DISTINCT location' in sql: return [{"location":"Bengaluru"}]
        return []

@pytest.fixture
def client():
    db=Fake()
    app.dependency_overrides[database]=lambda:db
    with TestClient(app,raise_server_exceptions=False) as c: yield c,db
    app.dependency_overrides.clear()

@pytest.mark.parametrize('path',['/api/health','/api/health/db','/api/categories','/api/locations','/api/prices/latest?location=Bengaluru','/api/prices/history?product_id=1&location=Bengaluru'])
def test_endpoints(client,path): assert client[0].get(path).status_code==200

@pytest.mark.parametrize('query',['limit=501','product_id=-1','date_from=bad','date_from=2026-09-01&date_to=2026-01-01','location=','location=%20'])
def test_validation(client,query):
    assert client[0].get('/api/prices/history?product_id=1&location=Bengaluru&'+query).status_code==422

def test_bound_search(client):
    c,db=client
    text="' OR 1=1 --"
    assert c.get('/api/prices/latest',params={"location":"Bengaluru","search":text}).status_code==200
    sql,binds=db.calls[0]
    assert text not in sql and binds['search']==text

def test_safe_failure(client):
    def fail(): raise DatabaseUnavailable()
    app.dependency_overrides[database]=fail
    r=client[0].get('/api/health/db')
    assert r.status_code==503 and 'ORA-' not in r.text

def test_missing_credentials():
    with TestClient(app) as c:
        assert c.get('/api/health').status_code==200
        assert c.get('/api/health/db').status_code==503

def test_admin_rejected():
    with pytest.raises(ValueError): Settings(db_user='SYS')

def test_cors(client):
    c,_=client
    assert c.get('/api/health',headers={'Origin':'http://localhost:5173'}).headers['access-control-allow-origin']=='http://localhost:5173'
    assert 'access-control-allow-origin' not in c.get('/api/health',headers={'Origin':'https://untrusted.example'}).headers

def test_populated_latest_response(client):
    c,db=client
    def query(sql,binds=None):
        if 'FROM v_latest_prices' in sql:
            return [dict(product_id=7,category_id=2,category_name='Food',product_name='Rice',unit='1 kg',
                         brand='Generic',active_status='Y',location='Chennai',observed_date='2026-09-01',
                         price=56.7,source='SYNTHETIC',comparison_date='2026-06-01',change_pct=None)]
        return [dict(observed_date='2026-09-01',price=56.7,source='SYNTHETIC')]
    db.query=query
    r=c.get('/api/prices/latest?location=Chennai')
    assert r.status_code==200
    assert r.json()[0]['change_pct'] is None
    assert r.json()[0]['history'][0]['observed_date']=='2026-09-01'

def test_inclusive_date_binds(client):
    c,db=client
    assert c.get('/api/prices/history?product_id=7&location=Chennai&date_from=2026-01-01&date_to=2026-09-01').status_code==200
    sql,binds=db.calls[0]
    assert binds['product_id']==7 and binds['location']=='Chennai'
    assert binds['date_to'].hour==0
    assert 'observed_date<=:date_to' in sql
