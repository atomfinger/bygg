#!/usr/bin/env python3
"""
Verify (or update) that version constraints in packages/core/src/bygg/catalog.gleam
match the canonical constraints in scripts/seed/gleam.toml.

Usage:
  python3 scripts/sync_versions.py --check   # report mismatches, exit 1 if any
  python3 scripts/sync_versions.py --update  # write catalog.gleam with corrected constraints
"""
import argparse
import re
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).parent.parent
SEED_TOML = REPO_ROOT / "scripts" / "seed" / "gleam.toml"
CATALOG_GLEAM = REPO_ROOT / "packages" / "core" / "src" / "bygg" / "catalog.gleam"


def parse_seed_constraints(toml_path: Path) -> dict[str, str]:
    """Extract package -> constraint from [dependencies] and [dev_dependencies] sections."""
    constraints = {}
    in_deps = False
    for line in toml_path.read_text().splitlines():
        stripped = line.strip()
        if stripped in ("[dependencies]", "[dev_dependencies]"):
            in_deps = True
            continue
        if stripped.startswith("[") and stripped.endswith("]"):
            in_deps = False
            continue
        if in_deps and "=" in stripped and not stripped.startswith("#"):
            parts = stripped.split("=", 1)
            name = parts[0].strip()
            value = parts[1].strip().strip('"')
            constraints[name] = value
    return constraints


def parse_catalog_constraints(gleam_path: Path) -> dict[str, tuple[str, int]]:
    """Extract hex_name -> (constraint, line_number) from catalog.gleam."""
    pattern = re.compile(r'default_constraint:\s*"([^"]+)"')
    hex_name_pattern = re.compile(r'hex_name:\s*"([^"]+)"')

    constraints = {}
    lines = gleam_path.read_text().splitlines()

    i = 0
    while i < len(lines):
        hex_match = hex_name_pattern.search(lines[i])
        if hex_match:
            hex_name = hex_match.group(1)
            # Look for default_constraint in the next ~5 lines
            for j in range(i, min(i + 10, len(lines))):
                dc_match = pattern.search(lines[j])
                if dc_match:
                    if hex_name not in constraints:
                        constraints[hex_name] = (dc_match.group(1), j + 1)
                    break
        i += 1
    return constraints


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true")
    parser.add_argument("--update", action="store_true")
    args = parser.parse_args()

    if not args.check and not args.update:
        parser.print_help()
        sys.exit(1)

    seed = parse_seed_constraints(SEED_TOML)
    catalog = parse_catalog_constraints(CATALOG_GLEAM)

    mismatches = []
    for hex_name, seed_constraint in seed.items():
        if hex_name in catalog:
            catalog_constraint, lineno = catalog[hex_name]
            if catalog_constraint != seed_constraint:
                mismatches.append((hex_name, seed_constraint, catalog_constraint, lineno))

    if not mismatches:
        print("✓ All version constraints in catalog.gleam match scripts/seed/gleam.toml")
        return

    if args.check:
        print("✗ Version constraint mismatches found:\n")
        for hex_name, seed_c, cat_c, lineno in mismatches:
            print(f"  {hex_name}")
            print(f"    seed:    {seed_c}")
            print(f"    catalog: {cat_c}  (line {lineno})")
            print()
        print("Run `mise run sync-versions --update` to apply seed constraints to catalog.gleam")
        sys.exit(1)

    if args.update:
        content = CATALOG_GLEAM.read_text()
        for hex_name, seed_c, cat_c, _ in mismatches:
            content = content.replace(
                f'default_constraint: "{cat_c}"',
                f'default_constraint: "{seed_c}"',
                1,
            )
        CATALOG_GLEAM.write_text(content)
        print(f"Updated {len(mismatches)} constraint(s) in catalog.gleam:")
        for hex_name, seed_c, cat_c, _ in mismatches:
            print(f"  {hex_name}: {cat_c!r} → {seed_c!r}")


if __name__ == "__main__":
    main()
