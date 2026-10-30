"""Optional PostgreSQL request log for SokoPrice.

Each USSD request's menu path (for example "1*3") is stored with a timestamp so
the team can see which crops farmers ask about most. No phone numbers or other
personal data are stored (privacy by design).

The database is OPTIONAL: when DATABASE_URL is not set, every method is a safe
no-op. Database problems never break the USSD service; they are only logged.
"""
import logging
import os

try:
    import psycopg
except ImportError:  # pragma: no cover - psycopg is listed in requirements.txt
    psycopg = None

logger = logging.getLogger(__name__)

CREATE_TABLE_SQL = """
CREATE TABLE IF NOT EXISTS ussd_requests (
    id         BIGSERIAL PRIMARY KEY,
    menu_path  TEXT        NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
)
"""


class RequestLog:
    """Records USSD requests in PostgreSQL when a database URL is configured."""

    def __init__(self, dsn=None):
        self.dsn = dsn or None
        self._table_ready = False
        if self.enabled:
            self._ensure_table()

    @classmethod
    def from_env(cls):
        """Build a RequestLog from the DATABASE_URL environment variable."""
        return cls(os.getenv("DATABASE_URL"))

    @property
    def enabled(self):
        return bool(self.dsn) and psycopg is not None

    def _connect(self):
        return psycopg.connect(self.dsn, connect_timeout=3)

    def _ensure_table(self):
        """Create the table if needed. Retried on later calls if the DB was down."""
        if self._table_ready:
            return True
        try:
            with self._connect() as conn:
                conn.execute(CREATE_TABLE_SQL)
            self._table_ready = True
        except psycopg.Error as exc:
            logger.warning("Request log database unavailable: %s", exc)
        return self._table_ready

    def record(self, menu_path):
        """Store one request. Returns True if saved, False otherwise."""
        if not self.enabled or not self._ensure_table():
            return False
        try:
            with self._connect() as conn:
                conn.execute(
                    "INSERT INTO ussd_requests (menu_path) VALUES (%s)",
                    (menu_path or "",),
                )
            return True
        except psycopg.Error as exc:
            logger.warning("Could not record USSD request: %s", exc)
            return False

    def count(self):
        """Number of stored requests, or None if the database is off/unreachable."""
        if not self.enabled or not self._ensure_table():
            return None
        try:
            with self._connect() as conn:
                row = conn.execute("SELECT count(*) FROM ussd_requests").fetchone()
            return int(row[0])
        except psycopg.Error as exc:
            logger.warning("Could not count USSD requests: %s", exc)
            return None

    def stats(self):
        """Summary used by GET /api/stats."""
        if not self.enabled:
            return {"database": "disabled", "ussd_requests": None}
        total = self.count()
        status = "connected" if total is not None else "unavailable"
        return {"database": status, "ussd_requests": total}
