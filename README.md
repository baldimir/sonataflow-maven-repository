# SonataFlow Maven Repository

This repository serves as a GitHub Packages-based Maven repository for SonataFlow artifacts. It contains built Maven artifacts (JARs, source JARs, and other standard Maven artifacts) from the SonataFlow ecosystem.

## Purpose

This repository provides a centralized location for accessing SonataFlow Maven artifacts that may not be available in Maven Central or require specific versions. The artifacts are automatically built and deployed via GitHub Actions workflows.

## Using as a Maven Repository

### Configuration

#### 1. Configure Maven Settings

Add the following to your `~/.m2/settings.xml` file:

```xml
<settings xmlns="http://maven.apache.org/SETTINGS/1.0.0"
          xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xsi:schemaLocation="http://maven.apache.org/SETTINGS/1.0.0
                      http://maven.apache.org/xsd/settings-1.0.0.xsd">
  
  <profiles>
    <profile>
      <id>github-sonataflow</id>
      <repositories>
        <repository>
          <id>github-sonataflow</id>
          <url>https://maven.pkg.github.com/kubesmarts/sonataflow-maven-repository</url>
          <snapshots>
            <enabled>true</enabled>
          </snapshots>
        </repository>
      </repositories>
    </profile>
  </profiles>

  <activeProfiles>
    <activeProfile>github-sonataflow</activeProfile>
  </activeProfiles>
</settings>
```

#### 2. Use in Your Project

Once configured, you can add SonataFlow dependencies to your `pom.xml`:

```xml
<dependencies>
  <dependency>
    <groupId>groupIdOfTheDependency</groupId>
    <artifactId>artifactIdOfTheDependency</artifactId>
    <version>YOUR_DESIRED_VERSION</version>
  </dependency>
  <!-- Add other SonataFlow dependencies as needed -->
</dependencies>
```

### Alternative: Project-Level Configuration

You can also configure the repository directly in your project's `pom.xml`:

```xml
<repositories>
  <repository>
    <id>github-sonataflow</id>
    <url>https://maven.pkg.github.com/kubesmarts/sonataflow-maven-repository</url>
    <snapshots>
      <enabled>true</enabled>
    </snapshots>
  </repository>
</repositories>
```

## Available Artifacts

To browse available packages, visit: https://github.com/kubesmarts/sonataflow-maven-repository/packages

## Building and Deploying

Artifacts are built and deployed automatically using GitHub Actions. 

For more information about the build process, see the [workflow configuration](.github/workflows/build-and-deploy-artifacts.yml).

## Troubleshooting

### Dependency Not Found

If Maven cannot find a dependency:
- Verify the artifact exists in the [packages list](https://github.com/kubesmarts/sonataflow-maven-repository/packages)
- Check that the version number is correct
- Ensure the repository is properly configured in your `settings.xml` or your project

## License

The artifacts in this repository are subject to their respective project licenses. Please refer to the individual project repositories for license information.