---
title: "Publishing from Gradle to Maven Central with GitHub Actions"
layout: post
---

# Publishing from Gradle to Maven Central with GitHub Actions

With my friends [Yannick](https://twitter.com/yannick_loiseau) and [Philippe](https://twitter.com/k33g_org) we have decided to re-ignite the development of [Eclipse Golo](https://golo-lang.org). We are converging towards a 3.4.0 release after 2 years of hiatus, and we are doing contributions at our own (leisure) pace.

This has been a great occasion to re-consider how releases would be published.

💡 You can get all the source code and automation [from the Eclipse Golo project on GitHub.](https://github.com/eclipse/golo-lang)

## 🚀 Automate all the things!

Golo needs to publish 2 types of release artifacts:

1. a distribution zip archive of Golo with the libraries, documentation, execution scripts, samples, etc
2. regular jar archives to be published on Maven Central.

### How we did before

Golo used to be released using a fairly manual process:

1. I would bump the version,
2. I would create a Git tag
3. I would run `./gradlew publish` to upload to Bintray, with my credentials for the Gradle build being safely stored in `~/.gradle/gradle.properties` on my computer
4. Bintray would sign all artifacts to meet the Maven Central requirements
5. I would publish the files on Bintray
6. I would push to Maven Central from Bintray using the synchronisation feature.

This is clearly a manual process where empowering somebody else like Yannick who's the project co-leader is harder than it should be.

### The new CI/CD process

With the new process that I recently put in place the whole deployment happens in GitHub Actions.

1. Pull-requests are being built just like you would expect, and the distribution is attached to the workflow run. This gives us cheap nightly builds of Golo.
2. Each push to the `master` branch triggers a deployment to Sonatype OSS. Depending on the version defined in the Gradle build file then this will be a snapshots publication or a full release to Maven Central.
3. Pushing a tag (e.g., `milestone/3.4.0-M4`, `release/3.4.0`) creates a (draft) GitHub release, and the corresponding distribution archive is attached to the release for general availability consumption. The draft is manually made public after some release notes text is added.

This means that now any trusted committer can bump the version, create a tag and push to GitHub, and the GitHub Actions workflow will figure out what to do.

The biggest challenge here compared to the previous process is that we need the workflow to be able to sign artifacts with a GnuPG key, and it needs to have the credentials to publish to Sonatype OSS.

Let's dive into how we publish to Maven Central from GitHub Actions, and using Gradle.

## 🏗️ Publishing with Gradle

Publishing with Gradle to Maven Central is well-documented.

First define the following plugins:

```kotlin
plugins {

  // (...)

  `java-library`
  `maven-publish`
  signing
}
```

Next you have to create *publications* and define *repositories* so Gradle knows *what* files to publish, and *where*:

```kotlin
publishing {

  publications {
    create<MavenPublication>("main") {
      artifactId = "golo"
      from(components["java"])
      pom {
        name.set("Eclipse Golo Programming Language")
        description.set("Eclipse Golo: a lightweight dynamic language for the JVM.")
        url.set("https://golo-lang.org")
        inceptionYear.set("2012")
        developers {
          developer {
            name.set("Golo committers")
            email.set("golo-dev@eclipse.org")
          }
        }
        licenses {
          license {
            name.set("Eclipse Public License - v 2.0")
            url.set("https://www.eclipse.org/org/documents/epl-2.0/EPL-2.0.html")
            distribution.set("repo")
          }
        }
        scm {
          url.set("https://github.com/eclipse/golo-lang")
          connection.set("scm:git:git@github.com:eclipse/golo-lang.git")
          developerConnection.set("scm:git:ssh:git@github.com:eclipse/golo-lang.git")
        }
      }
    }
  }

  repositories {

    maven {
      name = "CameraReady"
      url = uri("$buildDir/repos/camera-ready")
    }

    maven {
      name = "SonatypeOSS"
      credentials {
        username = if (project.hasProperty("ossrhUsername")) (project.property("ossrhUsername") as String) else "N/A"
        password = if (project.hasProperty("ossrhPassword")) (project.property("ossrhPassword") as String) else "N/A"
      }

      val releasesRepoUrl = "https://oss.sonatype.org/service/local/staging/deploy/maven2/"
      val snapshotsRepoUrl = "https://oss.sonatype.org/content/repositories/snapshots/"
      url = uri(if (isReleaseVersion) releasesRepoUrl else snapshotsRepoUrl)
    }
  }
}
```

Here we define a publication called `main`, and use some Gradle embedded domain-specific language to customise the Maven `pom.xml` generation.

We also define 2 repositories:

1. `CameraReady` is for checking locally what the generated publication looks like, and
2. `SonatypeOSS` points to the actual Sonatype OSS repositories.

We get the Sonatype OSS credentials from project properties `ossrhUsername` and `ossrhPassword` but ensure we use a bogus `"N/A"` value so people can still build the project even if they don't have these properties defined.

We also use a boolean value `isReleaseVersion` which is defined as:

```kotlin
val isReleaseVersion = !version.toString().endsWith("SNAPSHOT")
```

This allows us to point to the correct Sonatype OSS repository.

We also need to instruct Gradle to sign the publication artifacts:

```kotlin
signing {
  useGpgCmd()
  sign(publishing.publications["main"])
}
```

To check what the published artifacts would look like run:

```bash
$ ./gradlew publishAllPublicationsToCameraReadyRepository
```

then check the files tree:

```bash
$ exa --tree build/repos/camera-ready
build/repos/camera-ready
└── org
   └── eclipse
      └── golo
         └── golo
            ├── 3.4.0-SNAPSHOT
            │  ├── golo-3.4.0-20201218.172135-1-javadoc.jar
            │  ├── golo-3.4.0-20201218.172135-1-javadoc.jar.asc
            │  ├── golo-3.4.0-20201218.172135-1-javadoc.jar.asc.md5
            │  ├── golo-3.4.0-20201218.172135-1-javadoc.jar.asc.sha1
            │  ├── golo-3.4.0-20201218.172135-1-javadoc.jar.asc.sha256
            │  ├── golo-3.4.0-20201218.172135-1-javadoc.jar.asc.sha512
            │  ├── golo-3.4.0-20201218.172135-1-javadoc.jar.md5
            │  ├── golo-3.4.0-20201218.172135-1-javadoc.jar.sha1
            │  ├── golo-3.4.0-20201218.172135-1-javadoc.jar.sha256
            │  ├── golo-3.4.0-20201218.172135-1-javadoc.jar.sha512
            │  ├── golo-3.4.0-20201218.172135-1-sources.jar
            │  ├── golo-3.4.0-20201218.172135-1-sources.jar.asc
            │  ├── golo-3.4.0-20201218.172135-1-sources.jar.asc.md5
            │  ├── golo-3.4.0-20201218.172135-1-sources.jar.asc.sha1
            │  ├── golo-3.4.0-20201218.172135-1-sources.jar.asc.sha256
            │  ├── golo-3.4.0-20201218.172135-1-sources.jar.asc.sha512
            │  ├── golo-3.4.0-20201218.172135-1-sources.jar.md5
            │  ├── golo-3.4.0-20201218.172135-1-sources.jar.sha1
            │  ├── golo-3.4.0-20201218.172135-1-sources.jar.sha256
            │  ├── golo-3.4.0-20201218.172135-1-sources.jar.sha512
            │  ├── golo-3.4.0-20201218.172135-1.jar
            │  ├── golo-3.4.0-20201218.172135-1.jar.asc
            │  ├── golo-3.4.0-20201218.172135-1.jar.asc.md5
            │  ├── golo-3.4.0-20201218.172135-1.jar.asc.sha1
            │  ├── golo-3.4.0-20201218.172135-1.jar.asc.sha256
            │  ├── golo-3.4.0-20201218.172135-1.jar.asc.sha512
            │  ├── golo-3.4.0-20201218.172135-1.jar.md5
            │  ├── golo-3.4.0-20201218.172135-1.jar.sha1
            │  ├── golo-3.4.0-20201218.172135-1.jar.sha256
            │  ├── golo-3.4.0-20201218.172135-1.jar.sha512
            │  ├── golo-3.4.0-20201218.172135-1.module
            │  ├── golo-3.4.0-20201218.172135-1.module.asc
            │  ├── golo-3.4.0-20201218.172135-1.module.asc.md5
            │  ├── golo-3.4.0-20201218.172135-1.module.asc.sha1
            │  ├── golo-3.4.0-20201218.172135-1.module.asc.sha256
            │  ├── golo-3.4.0-20201218.172135-1.module.asc.sha512
            │  ├── golo-3.4.0-20201218.172135-1.module.md5
            │  ├── golo-3.4.0-20201218.172135-1.module.sha1
            │  ├── golo-3.4.0-20201218.172135-1.module.sha256
            │  ├── golo-3.4.0-20201218.172135-1.module.sha512
            │  ├── golo-3.4.0-20201218.172135-1.pom
            │  ├── golo-3.4.0-20201218.172135-1.pom.asc
            │  ├── golo-3.4.0-20201218.172135-1.pom.asc.md5
            │  ├── golo-3.4.0-20201218.172135-1.pom.asc.sha1
            │  ├── golo-3.4.0-20201218.172135-1.pom.asc.sha256
            │  ├── golo-3.4.0-20201218.172135-1.pom.asc.sha512
            │  ├── golo-3.4.0-20201218.172135-1.pom.md5
            │  ├── golo-3.4.0-20201218.172135-1.pom.sha1
            │  ├── golo-3.4.0-20201218.172135-1.pom.sha256
            │  ├── golo-3.4.0-20201218.172135-1.pom.sha512
            │  ├── maven-metadata.xml
            │  ├── maven-metadata.xml.md5
            │  ├── maven-metadata.xml.sha1
            │  ├── maven-metadata.xml.sha256
            │  └── maven-metadata.xml.sha512
            ├── maven-metadata.xml
            ├── maven-metadata.xml.md5
            ├── maven-metadata.xml.sha1
            ├── maven-metadata.xml.sha256
            └── maven-metadata.xml.sha512
```

## 🔐 Generate files that will be decrypted in your CI/CD workflow

### Generate a key for signing artifacts

The first thing is to create a GnuPG signing key:

```bash
$ gpg --gen-key
```

You will be asked for a name and email, choose whatever is relevant for your project. In the case of Golo the key that I created is for `Eclipse Golo developers` with the email of the development mailing-list: `golo-dev@eclipse.org`. Also make sure to note the passphrase for signing, we'll need it in a minute.

Maven Central checks that artifacts are being signed, and the key needs to be available from one of the popular key servers.

To do that get the fingerprint of your (public) key, then publish it:

```bash
$ gpg --fingerprint golo-dev@eclipse.org
$ gpg --keyserver http://keys.gnupg.net --send-keys FINGERPRINT
```

where `FINGERPRINT` is... the fingerprint 😉

Now export the secret key to a file called `golo-dev-sign.asc`:

```bash
$ gpg --export-secret-key -a golo-dev@eclipse.org > golo-dev-sign.asc
```

🚨 This private key will be used for signing, so make sure you don't accidentally leak it. Make especially sure you don't commit it!

### Prepare a custom Gradle properties file

Gradle looks for `gradle.properties` files in various places. If you have that file in your root project folder then it will be used to pass configuration to the build file.

Fill this file with relevant data:

```
ossrhUsername=YOUR_LOGIN
ossrhPassword=YOUR_PASSWORD

signing.gnupg.keyName=FINGERPRINT
signing.gnupg.passphrase=PASSPHRASE
```

where:

- `YOUR_LOGIN` / `YOUR_PASSWORD` are from your Sonatype OSS account, and
- `FINGERPRINT` / `PASSPHRASE` are for the GnuPG key that you created above.

🚨 Again be careful not to leak this file because it contains credentials!

### Encrypt all the things!

So we have both `gradle.properties` and `golo-dev-sign.asc` that contain sensitive data. We want these files to be available only while the CI/CD workflow is running, so they will be stored encrypted in the Git repository.

To do that, let's define some arbitrarily complex password and store it temporarily in the `GPG_SECRET` environment variable. GnuPG offers [AES 256](https://en.wikipedia.org/wiki/Advanced_Encryption_Standard) symmetric encryption:

```bash
$ gpg --cipher-algo AES256 --symmetric --batch --yes --passphrase="${GPG_SECRET}" --output .build/golo-dev-sign.asc.gpg golo-dev-sign.asc
$ gpg --cipher-algo AES256 --symmetric --batch --yes --passphrase="${GPG_SECRET}" --output .build/gradle.properties.gpg gradle.properties
```

We now have `.build/golo-dev-sign.asc.gpg` and `.build/gradle.properties.gpg` that can be safely stored in Git. Sure anyone in the world can have these files, but without the password all they can do is a brute force attempt against AES 256 encrypted files.

## ✨ GitHub Actions in Action

### Publishing script

To publish artifacts we need to run the Gradle `publish` task. However we need Gradle to know about the credentials first, so the encrypted files have to be decrypted.

Here is the `.build/deploy.sh` script that we have for that purpose:

```bash
#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

function cleanup {
    echo "🧹 Cleanup..."
    rm -f gradle.properties golo-dev-sign.asc
}

trap cleanup SIGINT SIGTERM ERR EXIT

echo "🚀 Preparing to deploy..."

echo "🔑 Decrypting files..."

gpg --quiet --batch --yes --decrypt --passphrase="${GPG_SECRET}" \
    --output golo-dev-sign.asc .build/golo-dev-sign.asc.gpg

gpg --quiet --batch --yes --decrypt --passphrase="${GPG_SECRET}" \
    --output gradle.properties .build/gradle.properties.gpg

gpg --fast-import --no-tty --batch --yes golo-dev-sign.asc

echo "📦 Publishing..."

./gradlew publish

echo "✅ Done!"
```

This script assumes that the `GPG_SECRET` environment variable holds the password for the AES 256 encrypted files, then moves them to the project root folder.

Note that for what it's worth the script defines a trap to always remove the decrypted files.

### GitHub Actions workflow

Now comes the final piece of the puzzle: the workflow definition.

There are many ways one can write such workflow. In the case of Golo I opted to go with a single workflow and a single job to do everything, but do not take it as the golden solution. You may want to have separate jobs, separate workflows, etc. It all depends on your project requirements and what you want to automate.

The full workflow is as follows.

{% highlight yaml %}
{% raw %}
name: Continuous integration and deployment

on:
  push:
    branches:
      - master
    tags:
      - 'milestone/*'
      - 'release/*'
  pull_request:
    branches:
      - master

jobs:
  pipeline:
    runs-on: ubuntu-latest
    steps:

    - name: Checkout
      uses: actions/checkout@v2

    - name: Set up JDK 1.8
      uses: actions/setup-java@v1
      with:
        java-version: 1.8

    - name: Cache Gradle packages
      uses: actions/cache@v2
      with:
        path: ~/.gradle/caches
        key: ${{ runner.os }}-gradle-${{ hashFiles('**/*.gradle') }}
        restore-keys: ${{ runner.os }}-gradle

    - name: Grant execute permission for gradlew
      run: chmod +x gradlew

    - name: Build with Gradle
      run: ./gradlew build

    - name: Copy build distribution
      run: cp build/distributions/*.zip golo-distribution.zip

    - name: Attach build distribution from this build
      uses: actions/upload-artifact@v2
      with:
        name: Golo distribution from this build
        path: ./golo-distribution.zip

    # Only pushes to master trigger a publication to Sonatype OSS
    - name: Deploy
      if: github.ref == 'refs/heads/master'
      run: .build/deploy.sh
      env:
        GPG_SECRET: ${{ secrets.GPG_SECRET }}

    # Only pushes of tags trigger a release creation
    - name: Create the release
      id: create_release
      if: startsWith(github.ref, 'refs/tags/')
      uses: actions/create-release@v1
      env:
        GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
      with:
        tag_name: ${{ github.ref }}
        release_name: Release ${{ github.ref }}
        draft: true
        prerelease: startsWith(github.ref, 'refs/tags/milestone/')
    - name: Attach build distribution to the release
      if: startsWith(github.ref, 'refs/tags/')
      uses: actions/upload-release-asset@v1
      env:
        GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
      with:
        upload_url: ${{ steps.create_release.outputs.upload_url }}
        asset_path: ./golo-distribution.zip
        asset_name: golo-distribution.zip
        asset_content_type: application/zip
{% endraw %}
{% endhighlight %}

The workflow only requires that you define a secret called `GPG_SECRET` in your GitHub project (or organisation) settings. This secret is the golden key to everything else, since the 2 encrypted files contain your credentials for signing artifacts and uploading them to Sonatype OSS.

This workflow is linear with many steps being conditional depending on what trigger the run.

The first steps are always run: we setup Java, we checkout and build the project, and attach the distribution archive to the GitHub action run.

Golo uses a convention where release tags are prefixed with `milestone/` and `release/`. We consequently can test when a GitHub release has to be created because a tag has been pushed (`if: startsWith(github.ref, 'refs/tags/')`) and when it shall be marked as a release or a pre-release (`prerelease: startsWith(github.ref, 'refs/tags/milestone/')`).

Note that the GitHub release is created as a draft here because we prefer to make it live manually from the GitHub interface, but you may just directly publish it. You can also define some text / release notes using the `actions/create-release` action, possibly generated from a script of yours.

The deployment step is only enabled for pushes to the `master` branch (`if: github.ref == 'refs/heads/master'`) that call the `.build/deploy.sh`shell script from above.

## 💭 Concluding remarks

This workflow works well for a project like Golo. Again you can have a more complex workflow if that suits your needs better, or you may want to trigger workflow from other events. This is really up to you.

### Security considerations

At the time of the writing AES 256 is considered *safe* if you have a complex and long password.

Please keep in mind that you are still uploading your credentials to someone else's computers!

Your credentials are encrypted in a public Git repository, and they will be decrypted while the deployment script runs.

It is a very good idea to periodically update the encryption password, and rotate the passwords in the encrypted files.

### Cleaning the build attachments

The workflow above attaches a distribution of Golo to each build.

This is great because nightly builds are available as a distribution one can download from the corresponding workflow runs. Still, you don't want to hit quotas and pollute servers with everything you've built, so you can use another GitHub Action workflow like this one for cleaning old artifacts:

```yaml
# Copied from https://poweruser.blog/storage-housekeeping-on-github-actions-e2997b5b23d1

name: 'Nightly artifacts cleanup (> 14 days)'
on:
  schedule:
    - cron: '0 4 * * *' # every night at 4 am UTC

jobs:
  delete-artifacts:
    runs-on: ubuntu-latest
    steps:
      - uses: kolpav/purge-artifacts-action@v1
        with:
          token: ${{ secrets.GITHUB_TOKEN }}
          expire-in: 14days
```

### What we did not cover: the website

So far this workflow does not publish an updated website.

This is left for future work 😇