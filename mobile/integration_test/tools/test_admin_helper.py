"""Local Firebase Admin helper for E2E tests.

This is NOT part of the app or the backend API. It is a throwaway HTTP service
that runs on the host machine for the duration of an E2E run, reachable from the
Android emulator at http://10.0.2.2:<port>. It uses the Firebase Admin SDK (the
same `firebase-service-account.json` the backend uses) to do two things a Dart
test on the device cannot:

  1. Mark a freshly signed-up account's email as verified, so the app's
     verify-email screen (which polls `user.reload()` every 3s) proceeds.
  2. Delete the test account as a safety net, so an aborted run still leaves the
     Firebase project clean.

Endpoints:
  GET  /health                      -> {"status": "ok"}
  POST /verify-email {"email": ...} -> marks email_verified=True
  POST /delete-user  {"email": ...} -> deletes the user (idempotent)
  GET  /user-exists?email=...       -> {"exists": bool}

Run:
  FIREBASE_SERVICE_ACCOUNT=/path/to/firebase-service-account.json \
  python test_admin_helper.py --port 8765
"""

import argparse
import os

import firebase_admin
from firebase_admin import auth, credentials
from flask import Flask, jsonify, request

app = Flask(__name__)


def _init_firebase() -> None:
    """Initialize the Admin SDK from the service-account JSON."""
    if firebase_admin._apps:
        return
    sa_path = os.environ.get("FIREBASE_SERVICE_ACCOUNT")
    if not sa_path or not os.path.isfile(sa_path):
        raise RuntimeError(
            "Set FIREBASE_SERVICE_ACCOUNT to the path of firebase-service-account.json "
            f"(got: {sa_path!r})"
        )
    firebase_admin.initialize_app(credentials.Certificate(sa_path))


def _get_email(payload: dict) -> str:
    email = (payload or {}).get("email", "").strip()
    if not email:
        raise ValueError("Missing 'email' in request body")
    return email


@app.get("/health")
def health():
    return jsonify(status="ok")


@app.post("/verify-email")
def verify_email():
    email = _get_email(request.get_json(silent=True))
    user = auth.get_user_by_email(email)
    auth.update_user(user.uid, email_verified=True)
    return jsonify(verified=True, uid=user.uid)


@app.post("/delete-user")
def delete_user():
    email = _get_email(request.get_json(silent=True))
    try:
        user = auth.get_user_by_email(email)
    except auth.UserNotFoundError:
        return jsonify(deleted=False, reason="not_found")
    auth.delete_user(user.uid)
    return jsonify(deleted=True, uid=user.uid)


@app.post("/custom-token")
def custom_token():
    """Return a Firebase custom token for the given email (bypasses reCAPTCHA)."""
    email = _get_email(request.get_json(silent=True))
    user = auth.get_user_by_email(email)
    token_bytes = auth.create_custom_token(user.uid)
    return jsonify(token=token_bytes.decode("utf-8"), uid=user.uid)


@app.get("/user-exists")
def user_exists():
    email = (request.args.get("email") or "").strip()
    if not email:
        return jsonify(error="Missing 'email' query parameter"), 400
    try:
        auth.get_user_by_email(email)
        return jsonify(exists=True)
    except auth.UserNotFoundError:
        return jsonify(exists=False)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="E2E Firebase Admin helper")
    parser.add_argument("--port", type=int, default=8765)
    parser.add_argument("--host", default="0.0.0.0")
    parser.add_argument(
        "--auth-emulator-host",
        default="",
        help="Route Firebase Admin SDK auth calls to this emulator (e.g. 127.0.0.1:9099)",
    )
    args = parser.parse_args()

    # Must be set BEFORE firebase_admin.initialize_app so the SDK picks it up.
    if args.auth_emulator_host:
        os.environ["FIREBASE_AUTH_EMULATOR_HOST"] = args.auth_emulator_host

    _init_firebase()
    # threaded=True so the device can call while a request is in flight.
    app.run(host=args.host, port=args.port, threaded=True)
