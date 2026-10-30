"""Container health probe used by Docker HEALTHCHECK and Docker Compose.

Exits 0 when the app's /health endpoint answers HTTP 200, otherwise exits 1.
Only the standard library is used so the slim image needs no extra tools.
"""
import os
import sys
import urllib.request


def main() -> int:
    port = os.environ.get("PORT", "5000")
    url = f"http://127.0.0.1:{port}/health"
    try:
        with urllib.request.urlopen(url, timeout=3) as response:
            return 0 if response.status == 200 else 1
    except Exception:
        return 1


if __name__ == "__main__":
    sys.exit(main())
