"""Tests for the optional PostgreSQL request log and the /api/stats endpoint.

Unit tests use a fake connection (no database needed). The integration test at
the bottom runs against a real PostgreSQL server when TEST_DATABASE_URL is set
(the CI pipeline does this) and is skipped otherwise.
"""
import os

import psycopg
import pytest

from app import create_app
from app import db as db_module
from app.db import RequestLog


class FakeConnection:
    """Minimal stand-in for a psycopg connection."""

    def __init__(self, calls, count=3):
        self.calls = calls
        self.count = count

    def __enter__(self):
        return self

    def __exit__(self, *exc_info):
        return False

    def execute(self, sql, params=None):
        self.calls.append((" ".join(sql.split()), params))
        return self

    def fetchone(self):
        return (self.count,)


@pytest.fixture
def fake_db(monkeypatch):
    calls = []
    monkeypatch.setattr(db_module.psycopg, "connect", lambda *a, **k: FakeConnection(calls))
    return calls


def test_disabled_without_database_url():
    log = RequestLog(None)
    assert log.enabled is False
    assert log.record("1*3") is False
    assert log.count() is None
    assert log.stats() == {"database": "disabled", "ussd_requests": None}


def test_from_env_reads_database_url(monkeypatch):
    monkeypatch.delenv("DATABASE_URL", raising=False)
    assert RequestLog.from_env().enabled is False


def test_record_inserts_menu_path(fake_db):
    log = RequestLog("postgresql://user:pw@db:5432/soko")
    assert log.record("1*3") is True
    insert = [call for call in fake_db if call[0].startswith("INSERT")]
    assert insert == [("INSERT INTO ussd_requests (menu_path) VALUES (%s)", ("1*3",))]


def test_stats_reports_connected_with_count(fake_db):
    log = RequestLog("postgresql://user:pw@db:5432/soko")
    assert log.stats() == {"database": "connected", "ussd_requests": 3}


def test_database_down_never_raises(monkeypatch):
    def refuse(*args, **kwargs):
        raise psycopg.OperationalError("database is down")

    monkeypatch.setattr(db_module.psycopg, "connect", refuse)
    log = RequestLog("postgresql://user:pw@db:5432/soko")
    assert log.record("1*3") is False
    assert log.count() is None
    assert log.stats() == {"database": "unavailable", "ussd_requests": None}


def test_table_creation_is_retried_after_outage(monkeypatch):
    calls = []
    state = {"up": False}

    def flaky(*args, **kwargs):
        if not state["up"]:
            raise psycopg.OperationalError("not ready yet")
        return FakeConnection(calls)

    monkeypatch.setattr(db_module.psycopg, "connect", flaky)
    log = RequestLog("postgresql://user:pw@db:5432/soko")
    assert log.record("1") is False
    state["up"] = True
    assert log.record("1") is True


def test_stats_endpoint_without_database():
    client = create_app(request_log=RequestLog(None)).test_client()
    response = client.get("/api/stats")
    assert response.status_code == 200
    assert response.json == {"database": "disabled", "ussd_requests": None}


def test_ussd_request_is_logged(fake_db):
    log = RequestLog("postgresql://user:pw@db:5432/soko")
    client = create_app(request_log=log).test_client()
    response = client.post("/ussd", data={"text": "1*3"})
    assert response.status_code == 200
    assert any(call[1] == ("1*3",) for call in fake_db)


@pytest.mark.skipif(
    not os.getenv("TEST_DATABASE_URL"),
    reason="TEST_DATABASE_URL not set (real PostgreSQL integration test)",
)
def test_real_postgres_round_trip():
    log = RequestLog(os.environ["TEST_DATABASE_URL"])
    before = log.count()
    client = create_app(request_log=log).test_client()

    assert client.post("/ussd", data={"text": "2*1"}).status_code == 200

    assert log.count() == before + 1
    body = client.get("/api/stats").json
    assert body["database"] == "connected"
    assert body["ussd_requests"] == before + 1
