"""Focused unit tests for pure helper functions and derived settings values."""

from datetime import datetime, timezone

from app.api.v1.warranties import (
    _to_optional_datetime,
    _to_optional_int,
    _to_optional_str,
)
from app.core.config import settings
from app.services.notification_service import _is_quiet_hour


def test_warranty_optional_type_helpers() -> None:
    now = datetime.now(timezone.utc)

    assert _to_optional_str("Laptop") == "Laptop"
    assert _to_optional_str(123) is None

    assert _to_optional_int(24) == 24
    assert _to_optional_int("24") is None

    assert _to_optional_datetime(now) is now
    assert _to_optional_datetime("2026-01-01") is None


def test_is_quiet_hour_for_standard_window() -> None:
    assert _is_quiet_hour(hour=9, start=9, end=17)
    assert _is_quiet_hour(hour=16, start=9, end=17)
    assert not _is_quiet_hour(hour=17, start=9, end=17)


def test_is_quiet_hour_for_overnight_window() -> None:
    assert _is_quiet_hour(hour=23, start=22, end=8)
    assert _is_quiet_hour(hour=2, start=22, end=8)
    assert not _is_quiet_hour(hour=12, start=22, end=8)


def test_settings_derived_values() -> None:
    assert settings.max_file_size_bytes == settings.MAX_FILE_SIZE_MB * 1024 * 1024
    assert "image/jpeg" in settings.allowed_file_types_list
    assert "image/png" in settings.allowed_file_types_list