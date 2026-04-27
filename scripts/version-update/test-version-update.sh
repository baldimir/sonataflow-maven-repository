#!/bin/bash

# Test script to verify the version update logic works correctly
# This creates test pom.xml files and verifies the updates
# Now tests with single argument (NEW_VERSION only)

echo "=========================================="
echo "Test 1: Subdirectory pom.xml (normal behavior)"
echo "=========================================="
echo ""

# Create a test directory
TEST_DIR="test-version-update-temp"
mkdir -p "$TEST_DIR/submodule"

# Create a test pom.xml in subdirectory with various version tags
cat > "$TEST_DIR/submodule/pom.xml" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0">
  <modelVersion>4.0.0</modelVersion>
  
  <parent>
    <groupId>org.kie</groupId>
    <artifactId>drools-build-parent</artifactId>
    <version>9.104.0</version>
  </parent>

  <groupId>org.kie</groupId>
  <artifactId>kie-dmn-core</artifactId>
  <version>9.104.0</version>
  <packaging>jar</packaging>

  <name>KIE :: Decision Model Notation :: Core</name>

  <properties>
    <java.module.name>org.kie.dmn.core</java.module.name>
  </properties>

  <dependencyManagement>
    <dependencies>
      <dependency>
        <groupId>org.drools</groupId>
        <artifactId>drools-bom</artifactId>
        <version>9.104.0</version>
        <type>pom</type>
        <scope>import</scope>
      </dependency>
    </dependencies>
  </dependencyManagement>

  <dependencies>
    <dependency>
      <groupId>org.kie</groupId>
      <artifactId>kie-dmn-api</artifactId>
      <version>9.104.0</version>
    </dependency>
  </dependencies>

  <build>
    <plugins>
      <plugin>
        <groupId>org.apache.maven.plugins</groupId>
        <artifactId>maven-compiler-plugin</artifactId>
        <version>3.11.0</version>
      </plugin>
    </plugins>
  </build>
</project>
EOF

echo "Subdirectory pom.xml created."
echo ""
echo "Original content:"
echo "=================="
cat "$TEST_DIR/submodule/pom.xml"
echo ""
echo "=================="
echo ""

# Run the version update using the Python script
echo "Running version update to: 9.105.0-SNAPSHOT"
echo ""

(
    cd "$TEST_DIR" &&
    python3 ../update-maven-versions.py 9.105.0-SNAPSHOT
)

echo "Updated content:"
echo "=================="
cat "$TEST_DIR/submodule/pom.xml"
echo ""
echo "=================="
echo ""

# Verify the results
echo "Verification:"
echo "============="

# Check parent version was updated
if grep -A 3 '<parent>' "$TEST_DIR/submodule/pom.xml" | grep -q '9.105.0-SNAPSHOT'; then
    echo "✓ Parent version updated correctly"
else
    echo "✗ FAILED: Parent version not updated"
    rm -rf "$TEST_DIR"
    exit 1
fi

# Check module version was updated
if grep -A 1 '<artifactId>kie-dmn-core</artifactId>' "$TEST_DIR/submodule/pom.xml" | grep -q '9.105.0-SNAPSHOT'; then
    echo "✓ Module version updated correctly"
else
    echo "✗ FAILED: Module version not updated"
    rm -rf "$TEST_DIR"
    exit 1
fi

# Check dependency version was NOT updated
if grep -A 1 '<artifactId>kie-dmn-api</artifactId>' "$TEST_DIR/submodule/pom.xml" | grep -q '9.104.0'; then
    echo "✓ Dependency version NOT updated (correct)"
else
    echo "✗ FAILED: Dependency version was incorrectly updated"
    rm -rf "$TEST_DIR"
    exit 1
fi

# Check dependencyManagement version was NOT updated
if grep -A 1 '<artifactId>drools-bom</artifactId>' "$TEST_DIR/submodule/pom.xml" | grep -q '9.104.0'; then
    echo "✓ DependencyManagement version NOT updated (correct)"
else
    echo "✗ FAILED: DependencyManagement version was incorrectly updated"
    rm -rf "$TEST_DIR"
    exit 1
fi

# Check plugin version was NOT updated
if grep -A 1 '<artifactId>maven-compiler-plugin</artifactId>' "$TEST_DIR/submodule/pom.xml" | grep -q '3.11.0'; then
    echo "✓ Plugin version NOT updated (correct)"
else
    echo "✗ FAILED: Plugin version was incorrectly updated"
    rm -rf "$TEST_DIR"
    exit 1
fi

echo ""
echo "=========================================="
echo "Test 2: Root pom.xml (special behavior)"
echo "=========================================="
echo ""

# Create a root pom.xml with external parent
cat > "$TEST_DIR/pom.xml" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0">
  <modelVersion>4.0.0</modelVersion>
  
  <parent>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-parent</artifactId>
    <version>3.2.0</version>
  </parent>

  <groupId>org.kie</groupId>
  <artifactId>drools-parent</artifactId>
  <version>9.104.0</version>
  <packaging>pom</packaging>

  <name>Drools :: Parent</name>

  <modules>
    <module>submodule</module>
  </modules>
</project>
EOF

echo "Root pom.xml created."
echo ""
echo "Original content:"
echo "=================="
cat "$TEST_DIR/pom.xml"
echo ""
echo "=================="
echo ""

# Run the version update again
echo "Running version update to: 9.105.0-SNAPSHOT"
echo ""

(
    cd "$TEST_DIR" &&
    python3 ../update-maven-versions.py 9.105.0-SNAPSHOT
)

echo "Updated content:"
echo "=================="
cat "$TEST_DIR/pom.xml"
echo ""
echo "=================="
echo ""

# Verify the results for root pom.xml
echo "Verification:"
echo "============="

# Check parent version was NOT updated (root pom.xml special case)
if grep -A 3 '<parent>' "$TEST_DIR/pom.xml" | grep -q '3.2.0'; then
    echo "✓ Root pom.xml parent version NOT updated (correct - external parent)"
else
    echo "✗ FAILED: Root pom.xml parent version was incorrectly updated"
    rm -rf "$TEST_DIR"
    exit 1
fi

# Check module version WAS updated
if grep -A 1 '<artifactId>drools-parent</artifactId>' "$TEST_DIR/pom.xml" | grep -q '9.105.0-SNAPSHOT'; then
    echo "✓ Root pom.xml module version updated correctly"
else
    echo "✗ FAILED: Root pom.xml module version not updated"
    rm -rf "$TEST_DIR"
    exit 1
fi

echo ""
echo "============="
echo "All tests passed! ✓"
echo ""

# Cleanup
rm -rf "$TEST_DIR"
echo "Test directory cleaned up."

# Made with Bob
