"""Tiny Flask app that clips a section of a YouTube video using yt-dlp.

Each request:
  1. Validates the URL and HH:MM:SS / MM:SS time strings.
  2. Invokes yt-dlp with --download-sections to grab only the requested span.
  3. Streams the resulting mp4 back to the client and deletes it.
"""

import os
import re
import subprocess
import tempfile

from flask import Flask, jsonify, render_template, request, send_file

app = Flask(__name__, template_folder="templates", static_folder="static")

DOWNLOADS_DIR = "/app/downloads"
os.makedirs(DOWNLOADS_DIR, exist_ok=True)

# yt-dlp accepts http(s) URLs; reject anything else so we never pass a
# user-controlled string that looks like a flag (e.g. "--exec ...").
URL_PATTERN = re.compile(r"^https?://[^\s]+$")
TIME_PATTERN = re.compile(r"^(?:\d{1,2}:)?\d{1,2}:\d{2}$")


def _validate(url: str | None, start: str | None, end: str | None) -> str | None:
    if not url or not start or not end:
        return "url, start_time and end_time are required"
    if not URL_PATTERN.match(url):
        return "url must be a http(s) URL"
    if not (TIME_PATTERN.match(start) and TIME_PATTERN.match(end)):
        return "start_time and end_time must be MM:SS or HH:MM:SS"
    return None


@app.route("/")
def index():
    return render_template("index.html")


@app.route("/download", methods=["POST"])
def download():
    data = request.get_json(silent=True) or {}
    url = data.get("url")
    start_time = data.get("start_time")
    end_time = data.get("end_time")

    err = _validate(url, start_time, end_time)
    if err:
        return jsonify({"error": err}), 400

    # Use a unique temp file so concurrent requests don't collide.
    with tempfile.NamedTemporaryFile(
        dir=DOWNLOADS_DIR, prefix="clip_", suffix=".mp4", delete=False
    ) as tmp:
        output_path = tmp.name

    try:
        subprocess.run(
            [
                "yt-dlp",
                url,
                "-f", "bv*[ext=mp4]+ba[ext=m4a]/b[ext=mp4]",
                "--download-sections", f"*{start_time}-{end_time}",
                "-o", output_path,
                "--merge-output-format", "mp4",
            ],
            check=True,
        )
    except subprocess.CalledProcessError as exc:
        # Clean up the empty placeholder file before returning the error.
        _try_remove(output_path)
        return jsonify({"error": f"yt-dlp failed: {exc}"}), 500

    response = send_file(
        output_path,
        as_attachment=True,
        download_name=os.path.basename(output_path),
    )
    # call_on_close fires after the response body has finished streaming, so
    # the temp file is only removed once the client has the bytes.
    response.call_on_close(lambda: _try_remove(output_path))
    return response


def _try_remove(path: str) -> None:
    try:
        os.remove(path)
    except FileNotFoundError:
        pass


if __name__ == "__main__":
    # Bind to all interfaces; Traefik handles ingress at the edge.
    app.run(host="0.0.0.0", port=8001)
