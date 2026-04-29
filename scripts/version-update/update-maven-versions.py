#!/usr/bin/env python3

"""Update Maven module and parent versions across pom.xml files.

This script updates only:
1. The module's own <version> tag after the project-level <groupId> and <artifactId>
2. The <version> tag inside the <parent> section (EXCEPT for root pom.xml)

Special handling for root pom.xml:
- The root pom.xml (in the current working directory) will have its module version updated
- BUT its parent version will NOT be updated (common pattern for external parent POMs)

For all other pom.xml files in subdirectories:
- Both module version AND parent version are updated

It replaces ANY existing version with the specified NEW_VERSION.

It intentionally does not modify versions in dependencies, dependencyManagement,
plugins, or pluginManagement sections.
"""

from __future__ import annotations

import argparse
import fnmatch
import os
import re
import sys
from pathlib import Path
from tempfile import NamedTemporaryFile


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Update Maven module and parent versions across all pom.xml files "
            "under the current directory. Replaces ANY existing version with NEW_VERSION."
        )
    )
    parser.add_argument("new_version", help="New version to set")
    parser.add_argument(
        "-e",
        "--exclude",
        nargs="*",
        default=[],
        metavar="PATTERN",
        help=(
            "Exclude pom.xml files matching these glob patterns. "
            "Patterns are matched against relative paths from the current directory. "
            "Examples: '*/test/*', 'productized/*', '*-examples/*'"
        ),
    )
    parser.add_argument(
        "--update-root-parent",
        "--urp",
        action="store_true",
        help=(
            "Enable updating parent version in root pom.xml. "
            "By default, root pom.xml parent version is NOT updated (common for external parents)."
        ),
    )
    return parser.parse_args()


def validate_args(new_version: str) -> None:
    if not new_version.strip():
        raise ValueError("NEW_VERSION must not be empty")


def is_excluded(path: Path, root: Path, exclude_patterns: list[str]) -> bool:
    """Check if a path matches any exclusion pattern.
    
    Args:
        path: The file path to check
        root: The root directory (for computing relative path)
        exclude_patterns: List of glob patterns to match against
        
    Returns:
        True if the path matches any exclusion pattern, False otherwise
    """
    if not exclude_patterns:
        return False
    
    # Get relative path from root for pattern matching
    try:
        relative_path = path.relative_to(root)
    except ValueError:
        # Path is not relative to root, don't exclude
        return False
    
    # Convert to string with forward slashes for consistent pattern matching
    relative_path_str = str(relative_path).replace(os.sep, "/")
    
    # Check against each pattern
    for pattern in exclude_patterns:
        if fnmatch.fnmatch(relative_path_str, pattern):
            return True
    
    return False


def find_pom_files(root: Path, exclude_patterns: list[str] | None = None) -> list[Path]:
    """Find all pom.xml files, excluding those matching exclusion patterns.
    
    Args:
        root: Root directory to search from
        exclude_patterns: Optional list of glob patterns to exclude
        
    Returns:
        Sorted list of pom.xml file paths
    """
    if exclude_patterns is None:
        exclude_patterns = []
    
    all_poms = (path for path in root.rglob("pom.xml") if path.is_file())
    filtered_poms = [
        path for path in all_poms
        if not is_excluded(path, root, exclude_patterns)
    ]
    return sorted(filtered_poms)


def update_pom_content(content: str, new_version: str, is_root_pom: bool = False, update_root_parent: bool = False) -> tuple[str, int]:
    lines = content.splitlines(keepends=True)

    changes_made = 0
    in_parent = False
    in_dependencies = False
    in_dependency_mgmt = False
    in_plugins = False
    in_plugin_mgmt = False
    in_build = False
    in_project = False
    module_version_updated = False

    result_lines: list[str] = []

    for line in lines:
        original_line = line

        # Track when we enter/exit the <project> tag
        if "<project" in line:
            in_project = True
        elif "</project>" in line:
            in_project = False

        # Track when we enter/exit <parent> section
        if "<parent>" in line:
            in_parent = True
        elif "</parent>" in line:
            in_parent = False

        # Track when we enter/exit sections where we should NOT update versions
        if "<dependencies>" in line:
            in_dependencies = True
        elif "</dependencies>" in line:
            in_dependencies = False

        if "<dependencyManagement>" in line:
            in_dependency_mgmt = True
        elif "</dependencyManagement>" in line:
            in_dependency_mgmt = False

        if "<plugins>" in line:
            in_plugins = True
        elif "</plugins>" in line:
            in_plugins = False

        if "<pluginManagement>" in line:
            in_plugin_mgmt = True
        elif "</pluginManagement>" in line:
            in_plugin_mgmt = False

        if "<build>" in line:
            in_build = True
        elif "</build>" in line:
            in_build = False

        # Update parent version - replace ANY version
        # Skip for root pom.xml UNLESS update_root_parent flag is True
        if in_parent and "<version>" in line and (not is_root_pom or update_root_parent):
            # Extract the version value and replace it, preserving formatting
            match = re.search(r'<version>([^<]+)</version>', line)
            if match:
                old_version_value = match.group(1)
                line = line.replace(f"<version>{old_version_value}</version>",
                                   f"<version>{new_version}</version>")
                if line != original_line:
                    changes_made += 1
        # Update module version - the first <version> tag directly inside <project>
        # that is NOT in parent, dependencies, dependencyManagement, plugins, pluginManagement, or build
        elif (
            in_project
            and not module_version_updated
            and not in_parent
            and not in_dependencies
            and not in_dependency_mgmt
            and not in_plugins
            and not in_plugin_mgmt
            and not in_build
            and "<version>" in line
        ):
            # Extract the version value and replace it, preserving formatting
            match = re.search(r'<version>([^<]+)</version>', line)
            if match:
                old_version_value = match.group(1)
                line = line.replace(f"<version>{old_version_value}</version>",
                                   f"<version>{new_version}</version>")
                if line != original_line:
                    changes_made += 1
                    module_version_updated = True

        result_lines.append(line)

    return "".join(result_lines), changes_made


def update_pom_file(path: Path, new_version: str, root_dir: Path, update_root_parent: bool = False) -> int:
    # Check if this is the root pom.xml (in the same directory as where script is executed)
    is_root_pom = path.parent == root_dir
    
    original_content = path.read_text(encoding="utf-8")
    updated_content, changes_made = update_pom_content(original_content, new_version, is_root_pom, update_root_parent)

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
    
    # Find all pom.xml files first (before filtering)
    all_pom_files = sorted(path for path in root.rglob("pom.xml") if path.is_file())
    
    # Apply exclusion patterns
    pom_files = find_pom_files(root, args.exclude)
    
    # Calculate excluded files
    excluded_files = len(all_pom_files) - len(pom_files)

    if not pom_files and not all_pom_files:
        print("No pom.xml files found.")
        return 1

    print(f"Updating Maven versions to {args.new_version}")
    if args.exclude:
        print(f"Exclusion patterns: {', '.join(args.exclude)}")
    print("==================================================")
    
    # Show excluded files if any
    if excluded_files > 0:
        print(f"\nSkipping {excluded_files} excluded file(s):")
        for pom_file in all_pom_files:
            if is_excluded(pom_file, root, args.exclude):
                relative_path = pom_file.relative_to(root)
                print(f"  ⊘ Skipped: {relative_path} (matches exclusion pattern)")
        print()

    if not pom_files:
        print("No pom.xml files to update after applying exclusions.")
        return 0

    total_files = 0
    updated_files = 0

    for pom_file in pom_files:
        total_files += 1
        try:
            changes_made = update_pom_file(pom_file, args.new_version, root, args.update_root_parent)
        except OSError as exc:
            print(f"✗ Failed: {pom_file} ({exc})", file=sys.stderr)
            return 1

        if changes_made > 0:
            updated_files += 1
            # Add note if this is the root pom.xml
            if pom_file.parent == root:
                if args.update_root_parent:
                    print(f"✓ Updated: {pom_file} (root pom - parent version UPDATED)")
                else:
                    print(f"✓ Updated: {pom_file} (root pom - parent version NOT updated)")
            else:
                print(f"✓ Updated: {pom_file}")

    print("==================================================")
    print("Summary:")
    print(f"  Total pom.xml files found: {len(all_pom_files)}")
    if excluded_files > 0:
        print(f"  Excluded files: {excluded_files}")
    print(f"  Processed files: {total_files}")
    print(f"  Updated files: {updated_files}")
    print(f"  Unchanged files: {total_files - updated_files}")
    print("")
    print(f"Version update complete → {args.new_version}")

    return 0


if __name__ == "__main__":
    sys.exit(main())

# Made with Bob
