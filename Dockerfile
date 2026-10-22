FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

<<<<<<< HEAD
WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt \
    && groupadd --system --gid 10001 app \
    && useradd --system --uid 10001 --gid app --no-create-home app

COPY app/ ./app/
COPY data/ ./data/

USER app
EXPOSE 5000

CMD ["python", "-m", "flask", "--app", "app:create_app()", "run", "--host=0.0.0.0", "--port=5000"]
=======
WORKDIR /srv

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app ./app
COPY data ./data
COPY run.py .

# Run as a non-root user (security best practice)
RUN useradd --create-home appuser
USER appuser

EXPOSE 5000
CMD ["gunicorn", "--bind", "0.0.0.0:5000", "run:app"]
>>>>>>> 4cf6e5b5af1dc8039d3ff53052c51f073dfad52a
