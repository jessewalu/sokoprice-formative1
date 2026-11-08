"""Tests for the container health probe (scripts/healthcheck.py)."""
import importlib.util
import threading
from http.server import BaseHTTPRequestHandler, HTTPServer
from pathlib import Path

SCRIPT = Path(__file__).resolve().parent.parent / "scripts" / "healthcheck.py"


def load_probe():
    spec = importlib.util.spec_from_file_location("healthcheck", SCRIPT)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def serve(status):
    class Handler(BaseHTTPRequestHandler):
        def do_GET(self):
            self.send_response(status)
            self.end_headers()

        def log_message(self, *args):
            pass

    server = HTTPServer(("127.0.0.1", 0), Handler)
    threading.Thread(target=server.serve_forever, daemon=True).start()
    return server


def test_probe_passes_when_health_returns_200(monkeypatch):
    server = serve(200)
    monkeypatch.setenv("PORT", str(server.server_port))
    try:
        assert load_probe().main() == 0
    finally:
        server.shutdown()


def test_probe_fails_when_health_returns_500(monkeypatch):
    server = serve(500)
    monkeypatch.setenv("PORT", str(server.server_port))
    try:
        assert load_probe().main() == 1
    finally:
        server.shutdown()


def test_probe_fails_when_nothing_is_listening(monkeypatch):
    server = serve(200)
    port = server.server_port
    server.shutdown()
    server.server_close()
    monkeypatch.setenv("PORT", str(port))
    assert load_probe().main() == 1
