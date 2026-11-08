"""Container health probe used by Docker HEALTHCHECK and Docker Compose.

Exits 0 when the app's /health endpoint answers HTTP 200, otherwise exits 1.
Only the standard library is used so the slim image needs no extra tools.
http.client is used (not urllib) because it can only speak plain HTTP to the
host we give it, so it can never be redirected to a file:// or other scheme.
"""
import http.client
import os
import sys


def main() -> int:
    port = int(os.environ.get("PORT", "5000"))
    try:
        connection = http.client.HTTPConnection("127.0.0.1", port, timeout=3)
        try:
            connection.request("GET", "/health")
            return 0 if connection.getresponse().status == 200 else 1
        finally:
            connection.close()
    except Exception:
        return 1


if __name__ == "__main__":
    sys.exit(main())
