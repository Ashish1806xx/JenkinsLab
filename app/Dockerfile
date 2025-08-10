FROM python:3.12-slim
ENV PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1
WORKDIR /app

# Copy requirements first for better layer caching
COPY requirements.txt .

# Apply Debian security updates and update Python tooling
RUN apt-get update && apt-get -y upgrade && rm -rf /var/lib/apt/lists/* \
    && pip install --no-cache-dir --upgrade pip setuptools wheel \
    && pip install --no-cache-dir -r requirements.txt

# Copy the app
COPY . .
EXPOSE 8080
CMD ["gunicorn","--bind","0.0.0.0:8080","main:app"]
