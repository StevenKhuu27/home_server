FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

# ffmpeg is required by yt-dlp to merge separate video/audio streams.
# Apt version pins for ffmpeg are not stable across debian point releases, so
# we accept the unpinned warning here rather than break the build on rebuild.
# hadolint ignore=DL3008
RUN apt-get update \
    && apt-get install -y --no-install-recommends ffmpeg \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy requirements first so the pip layer is cached when only app code changes.
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app.py ./
COPY templates ./templates

# Run as an unprivileged user.
RUN useradd --create-home --shell /usr/sbin/nologin app \
    && mkdir -p /app/downloads \
    && chown -R app:app /app
USER app

EXPOSE 8001

CMD ["python", "app.py"]
