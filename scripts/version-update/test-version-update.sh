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
echo "=========================================="
echo "Test 3: Exclusion patterns"
echo "=========================================="
echo ""

# Create additional test directories and pom.xml files
mkdir -p "$TEST_DIR/test-module"
mkdir -p "$TEST_DIR/drools-examples"
mkdir -p "$TEST_DIR/productized"
mkdir -p "$TEST_DIR/normal-module"

# Create test pom.xml files
cat > "$TEST_DIR/test-module/pom.xml" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0">
  <modelVersion>4.0.0</modelVersion>
  
  <parent>
    <groupId>org.kie</groupId>
    <artifactId>drools-parent</artifactId>
    <version>9.104.0</version>
  </parent>

  <artifactId>test-module</artifactId>
  <version>9.104.0</version>
</project>
EOF

cat > "$TEST_DIR/drools-examples/pom.xml" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0">
  <modelVersion>4.0.0</modelVersion>
  
  <parent>
    <groupId>org.kie</groupId>
    <artifactId>drools-parent</artifactId>
    <version>9.104.0</version>
  </parent>

  <artifactId>drools-examples</artifactId>
  <version>9.104.0</version>
</project>
EOF

cat > "$TEST_DIR/productized/pom.xml" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0">
  <modelVersion>4.0.0</modelVersion>
  
  <parent>
    <groupId>org.kie</groupId>
    <artifactId>drools-parent</artifactId>
    <version>9.104.0</version>
  </parent>

  <artifactId>productized-module</artifactId>
  <version>9.104.0</version>
</project>
EOF

cat > "$TEST_DIR/normal-module/pom.xml" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0">
  <modelVersion>4.0.0</modelVersion>
  
  <parent>
    <groupId>org.kie</groupId>
    <artifactId>drools-parent</artifactId>
    <version>9.104.0</version>
  </parent>

  <artifactId>normal-module</artifactId>
  <version>9.104.0</version>
</project>
EOF

echo "Test pom.xml files created in test-module, drools-examples, productized, and normal-module directories."
echo ""

# Run the version update with exclusion patterns
echo "Running version update with exclusions: test-module/* *-examples/* productized/*"
echo ""

(
    cd "$TEST_DIR" &&
    python3 ../update-maven-versions.py 9.105.0-SNAPSHOT --exclude "test-module/*" "*-examples/*" "productized/*"
)

echo ""
echo "Verification:"
echo "============="

# Check that test-module was NOT updated
if grep -q '9.104.0' "$TEST_DIR/test-module/pom.xml"; then
    echo "✓ test-module/pom.xml NOT updated (correctly excluded by 'test-module/*')"
else
    echo "✗ FAILED: test-module/pom.xml was incorrectly updated"
    rm -rf "$TEST_DIR"
    exit 1
fi

# Check that drools-examples was NOT updated
if grep -q '9.104.0' "$TEST_DIR/drools-examples/pom.xml"; then
    echo "✓ drools-examples/pom.xml NOT updated (correctly excluded by '*-examples/*')"
else
    echo "✗ FAILED: drools-examples/pom.xml was incorrectly updated"
    rm -rf "$TEST_DIR"
    exit 1
fi

# Check that productized was NOT updated
if grep -q '9.104.0' "$TEST_DIR/productized/pom.xml"; then
    echo "✓ productized/pom.xml NOT updated (correctly excluded by 'productized/*')"
else
    echo "✗ FAILED: productized/pom.xml was incorrectly updated"
    rm -rf "$TEST_DIR"
    exit 1
fi

# Check that normal-module WAS updated (not excluded)
if grep -q '9.105.0-SNAPSHOT' "$TEST_DIR/normal-module/pom.xml"; then
    echo "✓ normal-module/pom.xml WAS updated (not excluded)"
else
    echo "✗ FAILED: normal-module/pom.xml was not updated"
    rm -rf "$TEST_DIR"
    exit 1
fi

# Check that submodule WAS updated (not excluded)
if grep -q '9.105.0-SNAPSHOT' "$TEST_DIR/submodule/pom.xml"; then
    echo "✓ submodule/pom.xml WAS updated (not excluded)"
else
    echo "✗ FAILED: submodule/pom.xml was not updated"
    rm -rf "$TEST_DIR"
    exit 1
fi

# Check that root pom.xml WAS updated (not excluded)
if grep -A 1 '<artifactId>drools-parent</artifactId>' "$TEST_DIR/pom.xml" | grep -q '9.105.0-SNAPSHOT'; then
    echo "✓ Root pom.xml WAS updated (not excluded)"
else
    echo "✗ FAILED: Root pom.xml was not updated"
    rm -rf "$TEST_DIR"
    exit 1
fi

echo ""
echo "=========================================="
echo "Test 4: Build section version exclusion"
echo "=========================================="
echo ""

# Create a test pom.xml with version tags in <build> section
mkdir -p "$TEST_DIR/build-test"
cat > "$TEST_DIR/build-test/pom.xml" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0">
  <modelVersion>4.0.0</modelVersion>
  
  <parent>
    <groupId>org.kie</groupId>
    <artifactId>drools-parent</artifactId>
    <version>9.104.0</version>
  </parent>

  <groupId>org.kie</groupId>
  <artifactId>build-test-module</artifactId>
  <version>9.104.0</version>
  <packaging>jar</packaging>

  <name>Build Test Module</name>

  <build>
    <plugins>
      <plugin>
        <groupId>org.apache.maven.plugins</groupId>
        <artifactId>maven-compiler-plugin</artifactId>
        <version>3.11.0</version>
        <configuration>
          <source>11</source>
          <target>11</target>
        </configuration>
      </plugin>
      <plugin>
        <groupId>org.apache.maven.plugins</groupId>
        <artifactId>maven-surefire-plugin</artifactId>
        <version>3.0.0</version>
      </plugin>
    </plugins>
    <extensions>
      <extension>
        <groupId>org.apache.maven.wagon</groupId>
        <artifactId>wagon-ssh</artifactId>
        <version>3.5.2</version>
      </extension>
    </extensions>
  </build>
</project>
EOF

echo "Build test pom.xml created."
echo ""
echo "Original content:"
echo "=================="
cat "$TEST_DIR/build-test/pom.xml"
echo ""
echo "=================="
echo ""

# Run the version update
echo "Running version update to: 9.105.0-SNAPSHOT"
echo ""

(
    cd "$TEST_DIR" &&
    python3 ../update-maven-versions.py 9.105.0-SNAPSHOT
)

echo ""
echo "Updated content:"
echo "=================="
cat "$TEST_DIR/build-test/pom.xml"
echo ""
echo "=================="
echo ""

# Verify the results
echo "Verification:"
echo "============="

# Check parent version was updated
if grep -A 3 '<parent>' "$TEST_DIR/build-test/pom.xml" | grep -q '9.105.0-SNAPSHOT'; then
    echo "✓ Parent version updated correctly"
else
    echo "✗ FAILED: Parent version not updated"
    rm -rf "$TEST_DIR"
    exit 1
fi

# Check module version was updated
if grep -A 1 '<artifactId>build-test-module</artifactId>' "$TEST_DIR/build-test/pom.xml" | grep -q '9.105.0-SNAPSHOT'; then
    echo "✓ Module version updated correctly"
else
    echo "✗ FAILED: Module version not updated"
    rm -rf "$TEST_DIR"
    exit 1
fi

# Check maven-compiler-plugin version was NOT updated (inside <build>)
if grep -A 1 '<artifactId>maven-compiler-plugin</artifactId>' "$TEST_DIR/build-test/pom.xml" | grep -q '3.11.0'; then
    echo "✓ Plugin version in <build> NOT updated (correct)"
else
    echo "✗ FAILED: Plugin version in <build> was incorrectly updated"
    rm -rf "$TEST_DIR"
    exit 1
fi

# Check maven-surefire-plugin version was NOT updated (inside <build>)
if grep -A 1 '<artifactId>maven-surefire-plugin</artifactId>' "$TEST_DIR/build-test/pom.xml" | grep -q '3.0.0'; then
    echo "✓ Surefire plugin version in <build> NOT updated (correct)"
else
    echo "✗ FAILED: Surefire plugin version in <build> was incorrectly updated"
    rm -rf "$TEST_DIR"
    exit 1
fi

# Check wagon-ssh extension version was NOT updated (inside <build>)
if grep -A 1 '<artifactId>wagon-ssh</artifactId>' "$TEST_DIR/build-test/pom.xml" | grep -q '3.5.2'; then
    echo "✓ Extension version in <build> NOT updated (correct)"
else
    echo "✗ FAILED: Extension version in <build> was incorrectly updated"
    rm -rf "$TEST_DIR"
    exit 1
fi

echo ""
echo "=========================================="
echo "Test 5: Root pom.xml with --update-root-parent flag"
echo "=========================================="
echo ""

# Create a fresh test directory for this test
TEST_DIR_5="test-version-update-temp-5"
mkdir -p "$TEST_DIR_5"

# Create a root pom.xml with external parent
cat > "$TEST_DIR_5/pom.xml" << 'EOF'
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
</project>
EOF

echo "Root pom.xml created for --update-root-parent test."
echo ""
echo "Original content:"
echo "=================="
cat "$TEST_DIR_5/pom.xml"
echo ""
echo "=================="
echo ""

# Run the version update WITH --update-root-parent flag
echo "Running version update to: 9.105.0-SNAPSHOT --update-root-parent"
echo ""

(
    cd "$TEST_DIR_5" &&
    python3 ../update-maven-versions.py 9.105.0-SNAPSHOT --update-root-parent
)

echo ""
echo "Updated content:"
echo "=================="
cat "$TEST_DIR_5/pom.xml"
echo ""
echo "=================="
echo ""

# Verify the results for root pom.xml with flag
echo "Verification:"
echo "============="

# Check parent version WAS updated (flag enabled)
if grep -A 3 '<parent>' "$TEST_DIR_5/pom.xml" | grep -q '9.105.0-SNAPSHOT'; then
    echo "✓ Root pom.xml parent version UPDATED (correct - flag enabled)"
else
    echo "✗ FAILED: Root pom.xml parent version was not updated with --update-root-parent flag"
    rm -rf "$TEST_DIR_5"
    exit 1
fi

# Check module version WAS updated
if grep -A 1 '<artifactId>drools-parent</artifactId>' "$TEST_DIR_5/pom.xml" | grep -q '9.105.0-SNAPSHOT'; then
    echo "✓ Root pom.xml module version updated correctly"
else
    echo "✗ FAILED: Root pom.xml module version not updated"
    rm -rf "$TEST_DIR_5"
    exit 1
fi

echo ""
echo "=========================================="
echo "Test 6: Root pom.xml with --urp short flag"
echo "=========================================="
echo ""

# Create another fresh test directory for short flag test
TEST_DIR_6="test-version-update-temp-6"
mkdir -p "$TEST_DIR_6"

# Create a root pom.xml with external parent
cat > "$TEST_DIR_6/pom.xml" << 'EOF'
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
</project>
EOF

echo "Root pom.xml created for --urp short flag test."
echo ""

# Run the version update WITH --urp short flag
echo "Running version update to: 9.106.0-SNAPSHOT --urp"
echo ""

(
    cd "$TEST_DIR_6" &&
    python3 ../update-maven-versions.py 9.106.0-SNAPSHOT --urp
)

echo ""
echo "Verification:"
echo "============="

# Check parent version WAS updated (short flag enabled)
if grep -A 3 '<parent>' "$TEST_DIR_6/pom.xml" | grep -q '9.106.0-SNAPSHOT'; then
    echo "✓ Root pom.xml parent version UPDATED (correct - --urp flag enabled)"
else
    echo "✗ FAILED: Root pom.xml parent version was not updated with --urp flag"
    rm -rf "$TEST_DIR_6"
    exit 1
fi

# Check module version WAS updated
if grep -A 1 '<artifactId>drools-parent</artifactId>' "$TEST_DIR_6/pom.xml" | grep -q '9.106.0-SNAPSHOT'; then
    echo "✓ Root pom.xml module version updated correctly"
else
    echo "✗ FAILED: Root pom.xml module version not updated"
    rm -rf "$TEST_DIR_6"
    exit 1
fi

echo ""
echo "============="
echo "All tests passed! ✓"
echo ""

# Cleanup
rm -rf "$TEST_DIR"
rm -rf "$TEST_DIR_5"
rm -rf "$TEST_DIR_6"
echo "Test directories cleaned up."

# Made with Bob
