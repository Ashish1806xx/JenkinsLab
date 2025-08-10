from flask import Flask
import os

app = Flask(__name__)

@app.get("/health")
def health():
    return {"status": "ok"}

@app.get("/")
def index():
    return "Hello from CI/CD!"

if __name__ == "__main__":
    # For local dev only; in the container we use Gunicorn (see Dockerfile CMD).
    # Use default host (127.0.0.1) so SAST is happy.
    port = int(os.environ.get("PORT", "8080"))
    app.run(port=port)
