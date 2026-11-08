"""Entry point: python run.py (local development only).

In production the app is started by gunicorn (see the Dockerfile), not by this
block. For local development the built-in server listens on the loopback
address only, so it is not reachable from other computers. Set HOST=0.0.0.0
yourself if you really need that.
"""
import os

from app import create_app

app = create_app()

if __name__ == "__main__":
    app.run(host=os.getenv("HOST", "127.0.0.1"), port=int(os.getenv("PORT", "5000")))
