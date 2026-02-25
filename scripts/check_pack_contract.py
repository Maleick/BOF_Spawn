#!/usr/bin/env python3
"""Validate BOF pack/parse contract ordering between CNA and BOF source."""

from __future__ import annotations

import argparse
import re
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import List, Optional


@dataclass
class ParseField:
    position: int
    field: str
    kind: str
    source: str
    line: int


def read_text(path: Path) -> str:
    try:
        return path.read_text(encoding="utf-8")
    except OSError as exc:
        raise RuntimeError(f"unable to read {path}: {exc}") from exc


def extract_cna_schema(text: str, path: Path) -> str:
    match = re.search(r'bof_pack\s*\(\s*[^,]+,\s*"([^"]+)"', text, flags=re.MULTILINE)
    if not match:
        raise RuntimeError(f"no bof_pack schema found in {path}")
    return match.group(1).strip()


def extract_go_function(text: str, path: Path) -> tuple[int, str]:
    start = re.search(r'^\s*void\s+go\s*\(', text, flags=re.MULTILINE)
    if not start:
        raise RuntimeError(f"unable to find go() in {path}")

    index = start.start()
    line_no = text[:index].count("\n") + 1
    brace_start = text.find("{", index)
    if brace_start == -1:
        raise RuntimeError(f"unable to find opening brace for go() in {path}")

    depth = 0
    for pos in range(brace_start, len(text)):
        char = text[pos]
        if char == "{":
            depth += 1
        elif char == "}":
            depth -= 1
            if depth == 0:
                return line_no, text[index : pos + 1]

    raise RuntimeError(f"unterminated go() body in {path}")


def infer_extract_kind(var_name: str, len_name: str) -> str:
    if "shellcode" in var_name.lower() or "shellcode" in len_name.lower():
        return "b"
    return "Z"


def extract_bof_sequence(go_text: str, go_start_line: int) -> List[ParseField]:
    extract_re = re.compile(
        r'^\s*([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(?:\([^)]*\)\s*)?BeaconDataExtract\(\s*&parser\s*,\s*&([A-Za-z_][A-Za-z0-9_]*)\s*\)\s*;'
    )
    int_re = re.compile(r'^\s*([A-Za-z_][A-Za-z0-9_]*)\s*=\s*BeaconDataInt\(\s*&parser\s*\)\s*;')

    fields: List[ParseField] = []
    for offset, line in enumerate(go_text.splitlines(), start=0):
        line_number = go_start_line + offset

        extract_match = extract_re.search(line)
        if extract_match:
            var_name = extract_match.group(1)
            len_name = extract_match.group(2)
            fields.append(
                ParseField(
                    position=len(fields) + 1,
                    field=var_name,
                    kind=infer_extract_kind(var_name, len_name),
                    source="BeaconDataExtract",
                    line=line_number,
                )
            )
            continue

        int_match = int_re.search(line)
        if int_match:
            var_name = int_match.group(1)
            fields.append(
                ParseField(
                    position=len(fields) + 1,
                    field=var_name,
                    kind="i",
                    source="BeaconDataInt",
                    line=line_number,
                )
            )

    if not fields:
        raise RuntimeError("no parser extraction sequence found in go()")

    return fields


def compare_schema(cna_schema: str, bof_fields: List[ParseField]) -> List[str]:
    mismatches: List[str] = []
    bof_schema = "".join(field.kind for field in bof_fields)
    max_len = max(len(cna_schema), len(bof_schema))

    for idx in range(max_len):
        pos = idx + 1
        expected: Optional[str] = cna_schema[idx] if idx < len(cna_schema) else None
        actual: Optional[str] = bof_schema[idx] if idx < len(bof_schema) else None
        if expected == actual:
            continue

        field = bof_fields[idx].field if idx < len(bof_fields) else "<missing>"
        line = bof_fields[idx].line if idx < len(bof_fields) else -1
        mismatches.append(
            f"position {pos}: expected {expected or '<none>'}, got {actual or '<none>'} (field={field}, line={line})"
        )

    return mismatches


def main() -> int:
    parser = argparse.ArgumentParser(description="Check CNA/BOF packing contract.")
    parser.add_argument("--cna", required=True, help="Path to BOF_spawn.cna")
    parser.add_argument("--bof", required=True, help="Path to Src/Bof.c")
    args = parser.parse_args()

    cna_path = Path(args.cna)
    bof_path = Path(args.bof)

    try:
        cna_text = read_text(cna_path)
        bof_text = read_text(bof_path)
        cna_schema = extract_cna_schema(cna_text, cna_path)
        go_line, go_text = extract_go_function(bof_text, bof_path)
        bof_fields = extract_bof_sequence(go_text, go_line)
        mismatches = compare_schema(cna_schema, bof_fields)
    except RuntimeError as exc:
        print(f"[FAIL] {exc}", file=sys.stderr)
        return 1

    bof_schema = "".join(field.kind for field in bof_fields)
    if mismatches:
        print("[FAIL] CNA/BOF contract drift detected")
        print(f"[FAIL] CNA schema: {cna_schema}")
        print(f"[FAIL] BOF schema: {bof_schema}")
        for mismatch in mismatches:
            print(f"[FAIL] {mismatch}")
        return 1

    print("[PASS] CNA packing schema matches BOF parser extraction order/types")
    print(f"[PASS] schema: {cna_schema} ({len(cna_schema)} fields)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
