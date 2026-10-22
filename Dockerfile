FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

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
