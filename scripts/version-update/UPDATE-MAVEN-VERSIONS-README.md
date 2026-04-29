# Maven Version Update Script

## Overview

This script provides a safe and precise way to update Maven module versions across all `pom.xml` files in a project. It updates only the module's own version and parent version tags, **replacing ANY existing version** with the specified NEW_VERSION, while leaving dependency, plugin, and other version references unchanged.

## Files

- **`update-maven-versions.py`** - Main standalone Python script to update versions
- **`test-version-update.sh`** - Test script to verify the logic works correctly

## What Gets Updated

The script updates:

1. **Module version**: The `<version>` tag that appears after `<groupId>` and `<artifactId>` at the project level (in ALL pom.xml files including root)
2. **Parent version**: The `<version>` tag within the `<parent>` section (EXCEPT in the root pom.xml)

### Special Handling for Root pom.xml

The **root pom.xml** (the one in the current working directory where you run the script) receives special treatment:

- ✅ **Module version IS updated** - The project's own version is changed to the new version
- ❌ **Parent version is NOT updated** - The parent reference is left unchanged

This is a common pattern in Maven multi-module projects where the root pom.xml often references an external parent (like Spring Boot parent, corporate parent POM, or other framework parents) that should not be changed when updating the project's own version.

### Subdirectory pom.xml Files

All pom.xml files in subdirectories receive normal treatment:

- ✅ **Module version IS updated**
- ✅ **Parent version IS updated** (typically references the root pom)

## What Does NOT Get Updated

The script explicitly avoids updating versions in:

- `<dependencies>` section
- `<dependencyManagement>` section
- `<plugins>` section
- `<pluginManagement>` section
- `<properties>` section (e.g., `${project.version}` references)

## Usage

### Basic Usage

```bash
python3 update-maven-versions.py NEW_VERSION
```

### With Root Parent Update

```bash
python3 update-maven-versions.py NEW_VERSION --update-root-parent
# or using short form
python3 update-maven-versions.py NEW_VERSION --urp
```

### With Exclusion Patterns

```bash
python3 update-maven-versions.py NEW_VERSION --exclude PATTERN [PATTERN ...]
# or using short form
python3 update-maven-versions.py NEW_VERSION -e PATTERN [PATTERN ...]
```

### Combined Options

```bash
python3 update-maven-versions.py NEW_VERSION --update-root-parent --exclude "*/test/*"
# or using short forms
python3 update-maven-versions.py NEW_VERSION --urp -e "*/test/*"
```

### Examples

#### Example 1: Basic version update

```bash
python3 update-maven-versions.py 1.0.0
```

This will:
- Find all `pom.xml` files in the current directory and subdirectories
- Update module and parent versions to `1.0.0` (regardless of current version)
- Leave all dependency and plugin versions unchanged
- Display a summary of updated files

#### Example 2: Update to SNAPSHOT version

```bash
python3 update-maven-versions.py 9.105.0-SNAPSHOT
```

This will update all module and parent versions to `9.105.0-SNAPSHOT`.

#### Example 3: Update root parent version

```bash
python3 update-maven-versions.py 1.0.0 --update-root-parent
```

This will update all module and parent versions to `1.0.0`, **including** the parent version in the root pom.xml. Use this when your root pom.xml parent should be updated along with the project version.

#### Example 4: Update root parent using short flag

```bash
python3 update-maven-versions.py 1.0.0 --urp
```

Same as Example 3, but using the short form `--urp` instead of `--update-root-parent`.

#### Example 5: Exclude test directories

```bash
python3 update-maven-versions.py 1.0.0 --exclude "*/test/*"
```

This will update versions but skip any `pom.xml` files in directories containing "test" in their path.

#### Example 6: Exclude multiple patterns

```bash
python3 update-maven-versions.py 1.0.0 --exclude "*/test/*" "productized/*" "*-examples/*"
```

This will skip:
- Any files in test directories (`*/test/*`)
- Any files in the productized directory (`productized/*`)
- Any files in directories ending with `-examples` (`*-examples/*`)

#### Example 7: Using short form

```bash
python3 update-maven-versions.py 1.0.0 -e "*/test/*" "productized/*"
```

Same as Example 6, but using the short `-e` flag instead of `--exclude`.

#### Example 8: Combined options

```bash
python3 update-maven-versions.py 1.0.0 --update-root-parent --exclude "*/test/*"
```

This will update all versions to `1.0.0`, including the root pom.xml parent version, but skip any files in test directories.

### Root Parent Update Flag

The `--update-root-parent` (or `--urp`) flag controls whether the parent version in the root pom.xml is updated:

- **Default behavior (flag NOT provided)**: Root pom.xml parent version is NOT updated
  - This is the common pattern when the root pom.xml references an external parent (e.g., Spring Boot parent, corporate parent POM)
  - Only the root pom.xml module version is updated
  
- **With flag (--update-root-parent or --urp)**: Root pom.xml parent version IS updated
  - Use this when your root pom.xml parent should be updated along with the project version
  - Both module version AND parent version in root pom.xml are updated

**Note**: This flag only affects the root pom.xml. All subdirectory pom.xml files always have both module and parent versions updated regardless of this flag.

### Exclusion Patterns

The `--exclude` (or `-e`) parameter accepts glob-style wildcard patterns to skip specific `pom.xml` files:

- **Patterns are matched against relative paths** from the current working directory
- **Multiple patterns can be specified** by providing multiple arguments
- **Common wildcards:**
  - `*` - matches any characters within a path segment
  - `*/` - matches any directory
  - `**` - not needed (use `*/` for subdirectories)

**Pattern Examples:**

| Pattern | Matches | Example Files |
|---------|---------|---------------|
| `*/test/*` | Any file in a directory named "test" | `module/test/pom.xml`, `core/test/integration/pom.xml` |
| `productized/*` | Any file directly under "productized" | `productized/pom.xml`, `productized/module/pom.xml` |
| `*-examples/*` | Any file in directories ending with "-examples" | `drools-examples/pom.xml`, `kie-examples/submodule/pom.xml` |
| `test-*/*` | Any file in directories starting with "test-" | `test-utils/pom.xml`, `test-integration/pom.xml` |

**When a file is excluded:**
- It will be listed in the "Skipping excluded file(s)" section
- It will not be processed or modified
- The summary will show the count of excluded files

### Running Tests

Before using the script on your project, you can verify it works correctly:

```bash
./test-version-update.sh
```

This creates test `pom.xml` files, runs the update logic, and verifies that:
- Parent version is updated ✓
- Module version is updated ✓
- Dependency versions are NOT updated ✓
- DependencyManagement versions are NOT updated ✓
- Plugin versions are NOT updated ✓
- Exclusion patterns work correctly ✓
- Root parent update flag works correctly ✓

## Examples

### Example 1: Root pom.xml (External Parent)

#### Before

```xml
<project>
  <parent>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-parent</artifactId>
    <version>3.2.0</version>  <!-- External parent -->
  </parent>

  <groupId>org.kie</groupId>
  <artifactId>drools-parent</artifactId>
  <version>9.104.0</version>
  <packaging>pom</packaging>
</project>
```

#### After Running: `python3 update-maven-versions.py 9.105.0-SNAPSHOT`

```xml
<project>
  <parent>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-parent</artifactId>
    <version>3.2.0</version>  <!-- NOT CHANGED - external parent preserved -->
  </parent>

  <groupId>org.kie</groupId>
  <artifactId>drools-parent</artifactId>
  <version>9.105.0-SNAPSHOT</version>  <!-- UPDATED -->
  <packaging>pom</packaging>
</project>
```

### Example 2: Subdirectory pom.xml (Normal Behavior)

#### Before

```xml
<project>
  <parent>
    <groupId>org.kie</groupId>
    <artifactId>drools-parent</artifactId>
    <version>9.104.0</version>
  </parent>

  <groupId>org.kie</groupId>
  <artifactId>kie-dmn-core</artifactId>
  <version>9.104.0</version>

  <dependencies>
    <dependency>
      <groupId>org.kie</groupId>
      <artifactId>kie-dmn-api</artifactId>
      <version>9.104.0</version>
    </dependency>
  </dependencies>
</project>
```

#### After Running: `python3 update-maven-versions.py 9.105.0-SNAPSHOT`

```xml
<project>
  <parent>
    <groupId>org.kie</groupId>
    <artifactId>drools-parent</artifactId>
    <version>9.105.0-SNAPSHOT</version>  <!-- UPDATED -->
  </parent>

  <groupId>org.kie</groupId>
  <artifactId>kie-dmn-core</artifactId>
  <version>9.105.0-SNAPSHOT</version>  <!-- UPDATED -->

  <dependencies>
    <dependency>
      <groupId>org.kie</groupId>
      <artifactId>kie-dmn-api</artifactId>
      <version>9.104.0</version>  <!-- NOT CHANGED -->
    </dependency>
  </dependencies>
</project>
```

## Requirements

- **Python 3**: Required to run the standalone update script
- **Bash**: Only needed for the test script

## How It Works

The Python script parses each `pom.xml` file line by line and tracks the XML structure:

1. **Detects root pom.xml**: Identifies if the pom.xml is in the current working directory (root level)
2. **Tracks context**: Maintains state about which XML section it's currently in (parent, dependencies, etc.)
3. **Identifies module version**: Finds the `<version>` tag that appears after `<artifactId>` at the project level
4. **Identifies parent version**: Finds the `<version>` tag within the `<parent>` section
5. **Applies special logic for root**: Skips parent version update for root pom.xml only
6. **Skips excluded sections**: Ignores version tags in dependencies, plugins, and other sections
7. **Replaces ANY version**: Uses regex to extract and replace ANY existing version value with the NEW_VERSION in the identified locations

## Safety Features

- **Backup recommended**: Always commit your changes to git before running the script
- **Review changes**: Review the "Updated files" list to see what changed
- **Context-aware**: Only updates versions in module and parent sections, not in dependencies or plugins
- **Flexible**: Works regardless of the current version value

## Troubleshooting

### Script reports "0 updated files"

This means no `pom.xml` files have module or parent version tags to update. Possible reasons:
- Files don't have a `<version>` tag (they might inherit from parent)
- Files have the version in a different location (e.g., only in properties)
- All files are excluded by exclusion patterns

### Some files not updated

Check if those files:
- Don't have a `<version>` tag (they inherit from parent)
- Have the version in a different location (e.g., only in properties)
- Are in excluded sections (dependencies, plugins, etc.)
- Match an exclusion pattern (check the "Skipping excluded file(s)" section in output)

### Exclusion pattern not working

Make sure:
- Patterns use forward slashes (`/`) even on Windows
- Patterns are relative to the current working directory
- Wildcards are used correctly (e.g., `*/test/*` not `**/test/**`)
- Pattern is quoted to prevent shell expansion: `"*/test/*"`

### Want to see what will change?

Run the test script first to see the exact behavior:
```bash
./test-version-update.sh
```

This will test basic functionality and exclusion patterns.

## Platform Compatibility

- ✅ macOS (tested)
- ✅ Linux
- ✅ Windows (WSL or Git Bash with Python 3)

The solution uses Python 3 for cross-platform compatibility, avoiding issues with different versions of `awk` and `sed` on different operating systems.

## License

This script is provided as-is for use in the Drools project.