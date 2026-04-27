#!/usr/bin/env python3

"""Update Maven module and parent versions across pom.xml files.

This script updates only:
1. The module's own <version> tag after the project-level <groupId> and <artifactId>
2. The <version> tag inside the <parent> section

It replaces ANY existing version with the specified NEW_VERSION.

It intentionally does not modify versions in dependencies, dependencyManagement,
plugins, or pluginManagement sections.
"""

from __future__ import annotations

import argparse
import os
import sys
from pathlib import Path
from tempfile import NamedTemporaryFile


RESET_TAGS = (
    "<properties>",
    "<modules>",
    "<build>",
    "<profiles>",
    "<name>",
    "<description>",
    "<packaging>",
)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Update Maven module and parent versions across all pom.xml files "
            "under the current directory. Replaces ANY existing version with NEW_VERSION."
        )
    )
    parser.add_argument("new_version", help="New version to set")
    return parser.parse_args()


def validate_args(new_version: str) -> None:
    if not new_version.strip():
        raise ValueError("NEW_VERSION must not be empty")


def find_pom_files(root: Path) -> list[Path]:
    return sorted(path for path in root.rglob("pom.xml") if path.is_file())


def update_pom_content(content: str, new_version: str) -> tuple[str, int]:
    lines = content.splitlines(keepends=True)

    changes_made = 0
    in_parent = False
    in_dependencies = False
    in_dependency_mgmt = False
    in_plugins = False
    in_plugin_mgmt = False
    after_project_artifact_id = False
    project_level = 0

    result_lines: list[str] = []

    for line in lines:
        original_line = line

        if "<parent>" in line:
            in_parent = True
        elif "</parent>" in line:
            in_parent = False

        if "<project" in line:
            project_level += 1

        if not in_parent and project_level > 0 and "<artifactId>" in line:
            after_project_artifact_id = True

        if "<dependencies>" in line:
            in_dependencies = True
            after_project_artifact_id = False
        elif "</dependencies>" in line:
            in_dependencies = False

        if "<dependencyManagement>" in line:
            in_dependency_mgmt = True
            after_project_artifact_id = False
        elif "</dependencyManagement>" in line:
            in_dependency_mgmt = False

        if "<plugins>" in line:
            in_plugins = True
            after_project_artifact_id = False
        elif "</plugins>" in line:
            in_plugins = False

        if "<pluginManagement>" in line:
            in_plugin_mgmt = True
            after_project_artifact_id = False
        elif "</pluginManagement>" in line:
            in_plugin_mgmt = False

        if any(tag in line for tag in RESET_TAGS):
            after_project_artifact_id = False

        # Update parent version - replace ANY version
        if in_parent and "<version>" in line:
            # Extract the version value and replace it, preserving formatting
            import re
            match = re.search(r'<version>([^<]+)</version>', line)
            if match:
                old_version_value = match.group(1)
                line = line.replace(f"<version>{old_version_value}</version>",
                                   f"<version>{new_version}</version>")
                if line != original_line:
                    changes_made += 1
        # Update module version - replace ANY version
        elif (
            after_project_artifact_id
            and not in_dependencies
            and not in_dependency_mgmt
            and not in_plugins
            and not in_plugin_mgmt
            and "<version>" in line
        ):
            # Extract the version value and replace it, preserving formatting
            import re
            match = re.search(r'<version>([^<]+)</version>', line)
            if match:
                old_version_value = match.group(1)
                line = line.replace(f"<version>{old_version_value}</version>",
                                   f"<version>{new_version}</version>")
                if line != original_line:
                    changes_made += 1
            after_project_artifact_id = False

        result_lines.append(line)

    return "".join(result_lines), changes_made


def update_pom_file(path: Path, new_version: str) -> int:
    original_content = path.read_text(encoding="utf-8")
    updated_content, changes_made = update_pom_content(original_content, new_version)

    if changes_made == 0:
        return 0

    with NamedTemporaryFile(
        mode="w",
        encoding="utf-8",
        delete=False,
        dir=path.parent,
        prefix=f"{path.name}.",
        suffix=".tmp",
    ) as temp_file:
        temp_file.write(updated_content)
        temp_path = Path(temp_file.name)

    os.replace(temp_path, path)
    return changes_made


def main() -> int:
    args = parse_args()

    try:
        validate_args(args.new_version)
    except ValueError as exc:
        print(f"Error: {exc}", file=sys.stderr)
        return 2

    root = Path.cwd()
    pom_files = find_pom_files(root)

    if not pom_files:
        print("No pom.xml files found.")
        return 1

    print(f"Updating Maven versions to {args.new_version}")
    print("==================================================")

    total_files = 0
    updated_files = 0

    for pom_file in pom_files:
        total_files += 1
        try:
            changes_made = update_pom_file(pom_file, args.new_version)
        except OSError as exc:
            print(f"✗ Failed: {pom_file} ({exc})", file=sys.stderr)
            return 1

        if changes_made > 0:
            updated_files += 1
            print(f"✓ Updated: {pom_file}")

    print("==================================================")
    print("Summary:")
    print(f"  Total pom.xml files: {total_files}")
    print(f"  Updated files: {updated_files}")
    print(f"  Unchanged files: {total_files - updated_files}")
    print("")
    print(f"Version update complete → {args.new_version}")

    return 0


if __name__ == "__main__":
    sys.exit(main())

# Made with Bob
