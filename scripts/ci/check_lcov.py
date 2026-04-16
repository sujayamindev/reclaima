#!/usr/bin/env python3
"""Check LCOV coverage with exclusion globs and a strict threshold."""

from __future__ import annotations

import argparse
import fnmatch
import pathlib
import sys
from dataclasses import dataclass


@dataclass
class FileCoverage:
    path: str
    covered: int = 0
    total: int = 0

    @property
    def pct(self) -> float:
        if self.total == 0:
            return 100.0
        return (self.covered / self.total) * 100.0


def normalize_path(path_value: str, workspace: pathlib.Path) -> str:
    raw = path_value.strip().replace("\\", "/")
    if not raw:
        return raw

    path_obj = pathlib.Path(raw)
    if path_obj.is_absolute():
        try:
            raw = path_obj.resolve().relative_to(workspace.resolve()).as_posix()
        except ValueError:
            raw = path_obj.as_posix()

    return raw


def parse_lcov(lcov_path: pathlib.Path, workspace: pathlib.Path) -> dict[str, FileCoverage]:
    coverage: dict[str, FileCoverage] = {}
    current_file: FileCoverage | None = None

    for line in lcov_path.read_text(encoding="utf-8").splitlines():
        if line.startswith("SF:"):
            path_value = normalize_path(line[3:], workspace)
            current_file = coverage.setdefault(path_value, FileCoverage(path=path_value))
            continue

        if line.startswith("DA:") and current_file is not None:
            _, data = line.split(":", 1)
            _line_no, hits = data.split(",", 1)
            current_file.total += 1
            if int(hits) > 0:
                current_file.covered += 1
            continue

        if line == "end_of_record":
            current_file = None

    return coverage


def is_excluded(path_value: str, patterns: list[str]) -> bool:
    for pattern in patterns:
        if fnmatch.fnmatch(path_value, pattern):
            return True
    return False


def main() -> int:
    parser = argparse.ArgumentParser(description="Validate LCOV threshold with excludes.")
    parser.add_argument("lcov_path", help="Path to lcov.info file")
    parser.add_argument("--threshold", type=float, default=100.0, help="Coverage threshold")
    parser.add_argument(
        "--exclude",
        action="append",
        default=[],
        help="Glob path pattern to exclude. Can be repeated.",
    )
    parser.add_argument(
        "--workspace",
        default=".",
        help="Workspace root used for path normalization",
    )

    args = parser.parse_args()
    workspace = pathlib.Path(args.workspace)
    lcov_path = pathlib.Path(args.lcov_path)

    if not lcov_path.exists():
        print(f"ERROR: LCOV file not found: {lcov_path}")
        return 1

    parsed = parse_lcov(lcov_path, workspace)
    included = [
        item
        for item in parsed.values()
        if item.total > 0 and not is_excluded(item.path, args.exclude)
    ]

    if not included:
        print("ERROR: No source files left after applying exclusions.")
        return 1

    total_lines = sum(item.total for item in included)
    covered_lines = sum(item.covered for item in included)
    coverage_pct = (covered_lines / total_lines) * 100.0 if total_lines else 100.0

    print(f"Included files: {len(included)}")
    print(f"Covered lines: {covered_lines}")
    print(f"Total lines: {total_lines}")
    print(f"Coverage: {coverage_pct:.2f}%")
    print(f"Threshold: {args.threshold:.2f}%")

    if coverage_pct + 1e-9 < args.threshold:
        print("\nCoverage threshold not met. Files with missed lines:")
        missed = sorted((item for item in included if item.covered < item.total), key=lambda it: it.path)
        for item in missed:
            print(f"- {item.path}: {item.pct:.2f}% ({item.covered}/{item.total})")
        return 1

    print("Coverage threshold met.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
