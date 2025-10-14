---
title: "An Experiment in Maven to Gradle Migration"
layout: post
---

I have been using [Gradle](http://gradle.org/) recently on small-scale private / experimental code bases.
Having been in the Maven camp for some time, I have always been reticent in joining the Gradle enthusiasts wagon.
The fast pace of releases of Gradle, the stagnancy and the politics around Maven have prompted me in giving Gradle
another look over the past few months, and I have to say that it has matured in a very compelling way.

I took a chance over the summer break to experiment Gradle with the codebase of [Golo](http://golo-lang.org/).
While a single-module build is just fine, Golo has a few build requirements that do not make it
completely trivial either. We have our hacks around Maven with a Rake build frontend to simplify invocations,
which makes it a perfect candidate for a Gradle vs Maven comparison.

By the way I have to thank my friend Cédric Champeau from Gradle Inc., as I flooded him with emails
over the course of the Gradle build development. Thanks Cédric :-)

### Basics

The basics of the build are simple, with the `java` plugin we have all we need for building Golo.
It builds on top of the Maven project layout conventions (`src/main/java`, etc), so there isn't much
to do.

I got my initial `build.gradle` file by using the `gradle init` command. It picked the dependencies
correctly, and I just had to edit those a little bit:

{% highlight groovy %}
// (...)
group = 'org.eclipse.golo'
version = '3.0.0-incubation-SNAPSHOT'

sourceCompatibility = 1.8
targetCompatibility = 1.8

dependencies {

  compile 'org.ow2.asm:asm:5.0.4'
  compile 'com.beust:jcommander:1.48'
  compile 'com.github.rjeschke:txtmark:0.13'
  compile('com.googlecode.json-simple:json-simple:1.1.1') {
    exclude(module: 'junit')
  }

  testCompile 'org.ow2.asm:asm-util:5.0.4'
  testCompile 'org.ow2.asm:asm-analysis:5.0.4'
  testCompile 'org.hamcrest:hamcrest-all:1.3'
  testCompile 'org.skyscreamer:jsonassert:1.2.3'
  testCompile('org.testng:testng:6.9.4') {
    exclude(module: 'junit')
  }
}
// (...)
{% endhighlight %}

### Speeding things up

Gradle is based on Groovy, and Groovy is based on the JVM.

Starting a JVM is costly, and compiling then starting Groovy code isn't... fast to say the least.

Do yourself a favor and enable the daemon mode for all your Gradle invocations. Edit `~/.gradle/gradle.properties`:

    org.gradle.daemon=true

### The wrapper

While you can install Gradle on your machine and put it in, say, `/usr/local/bin`, the recommended
way is instead to rely on _wrapper scripts_.

These are `gradlew` and `gradlew.bat` scripts that you put in your project along with a bootstrap Jar.
The first time you invoke `./gradlew someTask`, it will fetch Gradle from the Internet.

I can't decide whether this is a good or a bad approach, but since it is idiomatic in Gradle I went
this way. You can define a `wrapper` task that specifies which version of Gradle you want, and use it
to generate / update these scripts:

{% highlight groovy %}
task wrapper(type: Wrapper) {
  gradleVersion = '2.6'
  description 'Generates the Gradle wrapper scripts'
}
{% endhighlight %}

You can then call `gradle wrapper` and put the generated files under version control.

### Where the fun begins: JavaCC / JJTree

It had been months since I contemplated doing this experiment, but the [Gradle JavaCC](https://github.com/johnmartel/javaccPlugin) was not working as I expected. I tried to fix
it myself, but my knowledge of the Gradle internals was too weak, and the plugin code is quite
involved. Another option would have been to do a custom task, but when there is a plugin, you can
avoid repeating yourself.

The good old Codehaus Maven JavaCC plugin picks up JavaCC / JJTree grammars, generates the files
and correctly avoids duplicates when you override them in your main source tree. This is common especially with
JJTree: there are some tree node classes that you want to be generated, and some for which you want to provide
an implementation of your own.

After reporting the issues, John Martel fixed the plugin. The current releases now work as expected, so
Gradle can process the Golo JJTree grammar just fine:

{% highlight groovy %}
// (...)
plugins {
  // (...)
  id 'ca.coglinc.javacc' version '2.2.2'
  id 'idea'
  id 'eclipse'
}
// (...)
sourceSets {
  main {
    java {
      srcDir compileJjtree.outputDirectory
      srcDir compileJavacc.outputDirectory
    }
  }
}

eclipseClasspath.dependsOn("compileJavacc")
// (...)
{% endhighlight %}

The `sourceSets` and `eclipseClasspath` tweaks are there to help Eclipse with the generated
source files. Given that Golo is an Eclipse project now, that is the very least we can do...

### Even funnier: when Golo needs Golo

The majority of Golo is written in Java. We have little interest (_read: time budget_) in making the Golo compiler self-hosted.
Still, there are some pieces of the runtime SDK that are written in Golo, so to compile them we need a Golo compiler.
This is a classic _chicken and egg problem_).

We solve it in Maven through a very ugly hack:

1. we build Golo in bootstrap mode, that is, we produce a Jar with just the Java parts,
2. while we bootstrap, we cannot compile Golo sources, so there is a wide range of unit tests that need to be disabled,
3. once we have a bootstrap that passes the tests, we compile a Golo Maven plugin, which is a separate sibling project,
4. the Maven plugin uses the bootstrap Jar just fine, as it only needs the compiler classes definition,
5. we rebuild the Golo Jar fully, and use the Maven plugin to compile the Golo source files.

So yes, that is dirty Maven build with an incomplete produced artifact, followed by a Maven plugin build, to get back to the first build and overwrite the artifact with a correct one.

In Gradle things are simpler: we can just create a `JavaExec` tasks, set the classpath on the project under build, and call
the Golo compiler class:

{% highlight groovy %}
ext {
  goloCliMain = 'fr.insalyon.citi.golo.cli.Main'
  goloSources = fileTree('src/main/golo').include('**/*.golo')
  goloClasses = file("$buildDir/classes/golo")
}

task goloc(type: JavaExec, dependsOn: classes) {
  main = goloCliMain
  args = ['compile', '--output', goloClasses] + goloSources
  classpath = sourceSets.main.runtimeClasspath
  inputs.files goloSources
  outputs.dir goloClasses
  description = 'Compiles Golo source files'
  group = 'Build'
}

jar.dependsOn goloc
test.dependsOn goloc
goloc.shouldRunAfter compileJava
{% endhighlight %}

Note the `inputs` and `outputs` properties: they are used by Gradle to decide whether to call the
task again or not on subsequent builds. This works for a wide range of custom tasks, so you get
generic incremental caching for free.

We also give hints to Gradle to when the `goloc` task shall run.

### Still having a bootstrap mode and tests helpers

While the Gradle build does not need a bootstrap phase, it is still useful to ditch the tests
that can fail if the compiler is under modifications.

The development of a language compiler also requires verbose inspections of what it does. The Golo
test suite has ways to be very verbose, for instance to print out intermediate representation trees or
the generated bytecode.

We had profiles for that in Maven, and with Gradle we can rely on properties:

{% highlight groovy %}
if (!project.hasProperty('bootstrap')) {
  jar.dependsOn goloc
  test.dependsOn goloc
  goloc.shouldRunAfter compileJava
  test.environment 'golo.bootstrapped', 'yes'
}

test {
  useTestNG()
  testLogging.showStandardStreams = project.hasProperty('consoleTraceTests')
  systemProperty 'golo.test.trace', project.hasProperty('traceTests') ? 'yes' : 'no'
  systemProperty 'java.awt.headless', 'true'
}
{% endhighlight %}

This means that `./gradlew test -P traceTests -P consoleTraceTests -P bootstrap` will only focus
on the Java code and print tons of information on the console while running the tests.

Believe me, it is very useful when you develop a language!

### Resources filtering

Maven users know that resource files can be _processed_ so that variables in files can be replaced
by values from the build environment.

We have a `metadata.properties` resource file which is being used by Golo to know which version
is being run:

    # Build metadata
    version=3.0.0-incubation-M1
    timestamp=15-07-27-07:26

The values are defined at build-time using simple variables.

This is trivial to activate in Maven:

{% highlight xml %}
<build>

    <resources>
      <resource>
        <directory>src/main/resources</directory>
        <filtering>true</filtering>
      </resource>
    </resources>

    <plugins>

(...)
{% endhighlight %}

It took me a while and an email to Cédric to figure out how do that in Gradle.

First I had to change from a `${version}` to a `@version@` notation in the properties file:

    version=@version@
    timestamp=@timestamp@

This is a minor change, but the build counterpart is not to my taste and the solution was hidden
somewhere in a corner of the Gradle documentation:

{% highlight groovy %}
processResources {
  filter(org.apache.tools.ant.filters.ReplaceTokens, tokens: [
    version: version,
    timestamp: versioning.info.full
  ])
}
{% endhighlight %}

Along the way I stumbled upon [this Gradle plugin that extracts Git metadata](https://github.com/nemerosa/versioning).
I used it to generate a better time stamp than a date.

While it isn't much configuration after all, it should still be more straightforward.
And I shouldn't have had to mention a class from that good old [Apache Ant](http://ant.apache.org/).

### The Zen of Asciidoctor

Generating the documentation with [Asciidoctor](http://asciidoctor.org/) is always a straightforward experience.

It's as simple as with Maven, and all I had to do was to use the obvious configuration from the instructions:

{% highlight groovy %}
asciidoctorj {
  version = '1.5.2'
}

asciidoctor {
  sourceDir 'doc'
  sources {
    include 'golo-guide.asciidoc'
  }
  backends 'html5'
}

assemble.dependsOn asciidoctor
{% endhighlight %}

Simple, clean.

### Golodocs

The generation of _Golodocs_ is similar to creating the `goloc` task:

{% highlight groovy %}
ext {
  // (...)
  goloDocs = file("$buildDir/docs/golodoc")
}

task golodoc(type: JavaExec, dependsOn: classes) {
  main = goloCliMain
  args = ['doc', '--format', 'html', '--output', goloDocs] + goloSources
  classpath = sourceSets.main.runtimeClasspath
  inputs.files goloSources
  outputs.dir goloDocs
  description = 'Generates documentation of the standard Golo modules.'
  group = 'Documentation'
}

golodoc.dependsOn goloc
{% endhighlight %}

### Generating shell scripts

Golo has a `golo` shell script, with Unix and Windows variants. It calls our command-line interface
main class, and passes a bunch of JVM configuration flags.

Golo also has a `vanilla-golo` script with no JVM tuning flags. This is useful in certain contexts
like running on a _Raspberry Pi_.

Gradle has an `application` plugin that is very similar to the [Codehaus AppAssembler Maven plugin](http://www.mojohaus.org/appassembler/appassembler-maven-plugin/).
It can help preparing a distribution with the shell scripts in `bin/`, and the Jar dependencies
in `lib/`.

Here is how we roll with Maven:

{% highlight xml %}
<plugin>
  <groupId>org.codehaus.mojo</groupId>
  <artifactId>appassembler-maven-plugin</artifactId>
  <version>${appassembler-maven-plugin.version}</version>
  <executions>
    <execution>
      <phase>package</phase>
      <goals>
        <goal>assemble</goal>
      </goals>
    </execution>
  </executions>
  <configuration>
    <repositoryName>lib</repositoryName>
    <repositoryLayout>flat</repositoryLayout>
    <licenseHeaderFile>${project.basedir}/src/main/assembly/appassembler-license-header</licenseHeaderFile>
    <programs>
      <program>
        <id>golo</id>
        <mainClass>fr.insalyon.citi.golo.cli.Main</mainClass>
        <jvmSettings>
          <initialMemorySize>256m</initialMemorySize>
          <maxMemorySize>1024M</maxMemorySize>
          <maxStackSize>1024M</maxStackSize>
          <extraArguments>
            <extraArgument>-server</extraArgument>
            <extraArgument>-XX:-TieredCompilation</extraArgument>
            <extraArgument>-XX:+AggressiveOpts</extraArgument>
          </extraArguments>
        </jvmSettings>
      </program>
      <program>
        <id>vanilla-golo</id>
        <mainClass>fr.insalyon.citi.golo.cli.Main</mainClass>
      </program>
    </programs>
  </configuration>
</plugin>
{% endhighlight %}

With Gradle things are a bit different. Once the `application` plugin has been applied, it takes a
very little amount of configuration to have a `golo` script (it uses the project name for the script
by default):

{% highlight groovy %}
mainClassName = goloCliMain
applicationDefaultJvmArgs = [
  '-Xms256m', '-Xmx1024M', '-Xss1024M', '-server', '-XX:-TieredCompilation', '-XX:+AggressiveOpts'
]
{% endhighlight %}

There is a problem, though: the plugin does not support multiple scripts, so it cannot be used
to generate the `vanilla-golo` script. The solution lies in defining a `CreateStartScripts` custom
task:

{% highlight groovy %}
task createVanillaScripts(type: CreateStartScripts) {
  outputDir = file('build/vanilla-golo')
  mainClassName = goloCliMain
  applicationName = 'vanilla-golo'
  classpath = startScripts.classpath
}

startScripts.dependsOn createVanillaScripts
{% endhighlight %}

### Assembling a distribution

The traditional way to prepare a distribution in Maven is to rely on the `assembly` plugin.

In the POM:

{% highlight xml %}
<plugin>
  <groupId>org.apache.maven.plugins</groupId>
  <artifactId>maven-assembly-plugin</artifactId>
  <version>${maven-assembly-plugin.version}</version>
  <configuration>
    <attach>false</attach>
    <descriptors>
      <descriptor>src/main/assembly/distribution.xml</descriptor>
    </descriptors>
  </configuration>
  <executions>
    <execution>
      <id>assembly-with-package</id>
      <phase>package</phase>
      <goals>
        <goal>single</goal>
      </goals>
    </execution>
  </executions>
</plugin>
{% endhighlight %}

`distribution.xml`:
{% highlight xml %}
<assembly xmlns="http://maven.apache.org/plugins/maven-assembly-plugin/assembly/1.1.0"
          xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xsi:schemaLocation="http://maven.apache.org/plugins/maven-assembly-plugin/assembly/1.1.0 http://maven.apache.org/xsd/assembly-1.1.0.xsd">
  <id>distribution</id>
  <formats>
    <format>dir</format>
    <format>zip</format>
  </formats>
  <fileSets>
    <fileSet>
      <directory>${project.basedir}</directory>
      <includes>
        <include>README*</include>
        <include>LICENSE*</include>
        <include>CONTRIB*</include>
        <include>THIRD-PARTY*</include>
        <include>notice.html</include>
        <include>epl-v10.html</include>
        <include>samples/**/*</include>
        <include>share/**/*</include>
      </includes>
      <useDefaultExcludes>true</useDefaultExcludes>
    </fileSet>
    <fileSet>
      <directory>target/generated-docs/</directory>
      <outputDirectory>/doc</outputDirectory>
      <includes>
        <include>*.html</include>
        <include>*.pdf</include>
        <include>golodoc/**</include>
      </includes>
      <useDefaultExcludes>true</useDefaultExcludes>
    </fileSet>
    <fileSet>
      <directory>target/appassembler/lib</directory>
      <outputDirectory>/lib</outputDirectory>
      <includes>
        <include>*.jar</include>
      </includes>
      <useDefaultExcludes>true</useDefaultExcludes>
    </fileSet>
    <fileSet>
      <directory>target/appassembler/bin</directory>
      <outputDirectory>/bin</outputDirectory>
      <fileMode>0755</fileMode>
      <lineEnding>unix</lineEnding>
      <includes>
        <include>golo</include>
        <include>vanilla-golo</include>
      </includes>
      <excludes>
        <exclude>*.bat</exclude>
      </excludes>
    </fileSet>
    <fileSet>
      <directory>target/appassembler/bin</directory>
      <outputDirectory>/bin</outputDirectory>
      <lineEnding>dos</lineEnding>
      <includes>
        <include>*.bat</include>
      </includes>
    </fileSet>
  </fileSets>
</assembly>
{% endhighlight %}

It's a bit XML-heavy, but it's not black magic either: you specify which archive formats you want,
and the descriptors pick files to put in.

In the Gradle land we prepare distributions in a more concise way. The `application` plugin already
defined a `main` distribution with the `bin/` and `lib/` folders. We just need to piggy-back to
bring the rest of the files:

{% highlight groovy %}
distributions {
  main {
    contents {
      from(projectDir) {
        include 'README*'
        include 'CONTRIB*'
        include 'THIRD-PARTY'
        include 'notice.html'
        include 'epl-v10.html'
      }
      into('samples') {
        from('samples') {
          include '**/*.golo'
        }
      }
      into('share') {
        from 'share'
      }
      from(asciidoctor.outputDir) {
        into 'docs'
      }
      from(golodoc) {
        into 'docs/golodoc'
      }
      from(createVanillaScripts.outputDir) {
        into 'bin'
      }
    }
  }
}
{% endhighlight %}

The `application` plugin already defined the `distZip` and `distTar` tasks to wrap the distribution
in archives. There is also a `installDist` task to prepare a folder with the distribution.

One of the nice things with Gradle here is that it leverages tasks such as `golodoc` or `createVanillaScripts`.
There is no need to explicitly call these tasks to prepare a distribution: they will be called if need be
when a distribution is being prepared.

### Publishing Maven artifacts

This a part of Gradle where I believe improvements would be welcome, although the new `maven-publish` plugin
bundled with Gradle is so much better than the old `maven` plugin.

Golo pushes Maven artifacts to the Eclipse repositories, and release artifacts are also pushed to
[Bintray / jCenter](https://bintray.com/golo-lang), and then synchronized to Maven Central.
There are reasons behind doing this:

* publishing to the Eclipse repositories is important for the integration with the rest of the ecosystem,
* Eclipse repositories do not push to Maven Central since it would require running proprietary Sonatype software,
* Maven Central requires GnuPG-signed artifacts, which is both unfriendly to continuous deployment environments and a false sense of security,
* Bintray can sign the artifacts with a generic key on our behalf, and later sync to central, which solves our problems nicely.

Maven Central also requires a Jar with the sources as well as a Jar with the Javadocs.
We do this in Maven with a special `release` profile:

{% highlight xml %}
<profile>
  <id>release</id>
  <build>
    <plugins>
      <plugin>
        <groupId>org.apache.maven.plugins</groupId>
        <artifactId>maven-source-plugin</artifactId>
        <version>${maven-source-plugin.version}</version>
        <executions>
          <execution>
            <id>attach-sources</id>
            <goals>
              <goal>jar-no-fork</goal>
            </goals>
          </execution>
        </executions>
      </plugin>
      <plugin>
        <groupId>org.apache.maven.plugins</groupId>
        <artifactId>maven-javadoc-plugin</artifactId>
        <version>${maven-javadoc-plugin.version}</version>
        <executions>
          <execution>
            <id>attach-javadocs</id>
            <goals>
              <goal>jar</goal>
            </goals>
          </execution>
        </executions>
      </plugin>
    </plugins>
  </build>
</profile>
{% endhighlight %}

In Gradle we need 2 tasks for that:

{% highlight groovy %}
task sourceJar(type: Jar) {
  from sourceSets.main.allJava
}

javadoc.options.addStringOption('Xdoclint:none', '-quiet')

task javadocJar (type: Jar, dependsOn: javadoc) {
  from javadoc.destinationDir
}
{% endhighlight %}

Having flexible repositories to publish to is a matter of using variables in Maven, and having
a profile to override targets:

{% highlight xml %}
  </properties>
    // (...)

    <distribution.repo.id>repo.eclipse.org</distribution.repo.id>
    <distribution.repo.url>https://repo.eclipse.org/content/repositories/golo-releases/</distribution.repo.url>
    <distribution.snapshots.id>repo.eclipse.org</distribution.snapshots.id>
    <distribution.snapshots.url>https://repo.eclipse.org/content/repositories/golo-snapshots/</distribution.snapshots.url>
  </properties>

  <distributionManagement>
    <repository>
      <id>${distribution.repo.id}</id>
      <name>Releases repository</name>
      <url>${distribution.repo.url}</url>
    </repository>
    <snapshotRepository>
      <id>${distribution.snapshots.id}</id>
      <name>Snapshots repository</name>
      <url>${distribution.snapshots.url}</url>
      <uniqueVersion>true</uniqueVersion>
    </snapshotRepository>
  </distributionManagement>

  // (...)

  <profile>
    <id>bintray</id>
    <properties>
      <distribution.repo.id>bintray</distribution.repo.id>
      <distribution.repo.url>https://api.bintray.com/maven/golo-lang/golo-lang/golo</distribution.repo.url>
    </properties>
  </profile>
{% endhighlight %}

In Gradle land we can specify how to publish artifacts with the `maven-publish` plugin as follows:

{% highlight groovy %}
publishing {
  publications {
    mavenJava(MavenPublication) {
      pom.withXml {
        asNode().children().last() + {
          resolveStrategy = Closure.DELEGATE_FIRST
          name 'Golo Programming Language (Incubation)'
          description 'Golo: a lightweight dynamic language for the JVM.'
          url 'http://golo-lang.org/'
          developers {
            developer {
              name 'Golo committers'
              email 'golo-dev@eclipse.org'
            }
          }
          licenses {
            license {
              name 'Eclipse Public License - v 1.0'
              url 'http://www.eclipse.org/legal/epl-v10.html'
              distribution 'repo'
            }
          }
          scm {
            url 'https://github.com/eclipse/golo-lang'
            connection 'scm:git:git@github.com:eclipse/golo-lang.git'
            developerConnection 'scm:git:ssh:git@github.com:eclipse/golo-lang.git'
          }
        }
      }
      from components.java
      artifact sourceJar {
        classifier 'sources'
      }
      artifact javadocJar {
        classifier 'javadoc'
      }
    }
  }
  repositories {
    // Credentials shall be stored in ~/.gradle/gradle.properties
    maven {
      url goloMavenRepoUrl
      credentials {
        username goloMavenRepoUsername
        password goloMavenRepoPassword
      }
    }
  }
}
{% endhighlight %}

There are 2 important things here:

1. the POM needs to be completed, as the plugin only fills it with correct `groupId:artifactId:version`
   plus dependencies metadata, and
2. artifacts can be attached in a similar way as doing a distribution, and by taking advantage of tasks.

I believe that the POM customization part is quite ugly there: you need to inject Groovy code to access
the nodes. The remainder of the builder syntax is fine, but having to figure out that you need to
`asNode().children().last() + { ... }` feels wrong. I would have preferred a straightforward builder DSL
here, [just like what the `gradle-nexus-plugin` does](https://github.com/bmuschko/gradle-nexus-plugin/).

The fun does not stop here: I had to write a small amount of Groovy code to pick up the correct
target repository. I am using properties to select the good target, so `./gradlew publish -PreleaseProfile=bintray`
will attempt publishing to Bintray:

{% highlight groovy %}
if (project.hasProperty('releaseProfile')) {
  switch (releaseProfile) {
    case 'eclipse':
      ext.goloMavenRepoUrl = 'https://repo.eclipse.org/content/repositories/golo-' + ((version.endsWith('-SNAPSHOT')) ? 'snapshots/' : 'releases/')
      ext.goloMavenRepoUsername = eclipseRepoUsername
      ext.goloMavenRepoPassword = eclipseRepoPassword
      break
    case 'bintray':
      ext.goloMavenRepoUrl = 'https://api.bintray.com/maven/golo-lang/golo-lang/golo'
      ext.goloMavenRepoUsername = bintrayRepoUsername
      ext.goloMavenRepoPassword = bintrayRepoPassword
      break
    default:
      throw new GradleException("Unknown release profile: $releaseProfile")
  }
} else {
  ext.goloMavenRepoUrl = "$buildDir/maven-repo"
  ext.goloMavenRepoUsername = ''
  ext.goloMavenRepoPassword = ''
}
{% endhighlight %}

Note that `eclipseRepoUsername` or `bintrayRepoUsername` are properties that need to exists
in `~/.gradle/gradle.properties`.

I did some tests and this works just fine, but I feel like Gradle could provide more help here.
Things are very straightforward in Maven, and it shouldn't be that hard to replicate the experience
in Gradle.

### So... where do we go from here?

First off I don't know if we'll switch the Golo build to Gradle. The pros and cons need to be
discussed with the project community, and we would also need IP clearance from the Eclipse
Foundation on Gradle since the wrapper scripts and Jar would be placed under version control.

I know there are lots of heated debates and commercial interests around Maven _vs_ Gradle.
In the case of Golo we have a moderately complex build. With both Maven and Gradle
some glitches have to be addressed, which required digging through incomplete documentation to find
workarounds. While the Gradle documentation is rich, it is often complicated to find what you are
really looking for, especially as due to the mixed declarative / imperative nature of Gradle there
is often more than one way to do it. Sometimes you end up reading Javadocs, trying to guess
what Groovy code offers to you. Without the help from Cédric I would have lost more time.

My previous experiences with Gradle hadn't been that good. I can see that Gradle is now becoming
much more mature to the point that Maven folks should be worried, especially when the noble
Apache Software Foundation hasn't been able to keep the community in a healthy state under
the fire of nasty politics.

My gut feeling is that Gradle does a fine job, and that a migration from Maven to Gradle would not
hurt. The build does not feel too _hack-ish_, although I certainly would love to see less code and
more declarations. I did not test much the new background live watch mode, but it is easy to
anticipate how helpful it is.

Let's open the debate!

### Appendix

#### Build times

On my modest aging MacBook Air:

`time rake special:bootstrap` (the full Maven builds):

    real	1m50.695s
    user	3m50.308s
    sys	0m15.228s

`time rake build` (just build again without cleaning):

    real	0m38.168s
    user	1m34.288s
    sys	0m6.041s

`time ./gradlew clean build` (a full Gradle build):

    real	0m40.406s
    user	0m2.231s
    sys	0m0.306s

`time ./gradlew build` (building again, daemon mode activated):

    real	0m3.456s
    user	0m1.922s
    sys	0m0.178s

#### Maven XML files

`pom.xml`

{% highlight xml%}
<?xml version="1.0" encoding="UTF-8"?>

<!--
  ~ Copyright (c) 2012-2015 Institut National des Sciences Appliquées de Lyon (INSA-Lyon)
  ~
  ~ All rights reserved. This program and the accompanying materials
  ~ are made available under the terms of the Eclipse Public License v1.0
  ~ which accompanies this distribution, and is available at
  ~ http://www.eclipse.org/legal/epl-v10.html
  -->

<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
  <modelVersion>4.0.0</modelVersion>

  <groupId>org.eclipse.golo</groupId>
  <artifactId>golo</artifactId>
  <version>3.0.0-incubation-SNAPSHOT</version>

  <packaging>jar</packaging>

  <name>Golo Programming Language (Incubation)</name>
  <description>Golo: a lightweight dynamic language for the JVM.</description>
  <url>http://golo-lang.org/</url>

  <developers>
    <developer>
      <name>Golo committers</name>
      <email>golo-dev@eclipse.org</email>
    </developer>
  </developers>

  <licenses>
    <license>
      <name>Eclipse Public License - v 1.0</name>
      <url>http://www.eclipse.org/legal/epl-v10.html</url>
      <distribution>repo</distribution>
    </license>
  </licenses>

  <scm>
    <connection>scm:git:git@github.com:eclipse/golo-lang.git</connection>
    <url>scm:git:git@github.com:eclipse/golo-lang.git</url>
    <developerConnection>scm:git:git@github.com:eclipse/golo-lang.git</developerConnection>
  </scm>

  <properties>

    <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
    <surefire.useFile>false</surefire.useFile>
    <maven.build.timestamp.format>yy-MM-dd-HH:mm</maven.build.timestamp.format>
    <build.timestamp>${maven.build.timestamp}</build.timestamp>
    <relocation.base>thirdparty</relocation.base>

    <asm.version>5.0.4</asm.version>
    <json-simple.version>1.1.1</json-simple.version>
    <jcommander.version>1.48</jcommander.version>
    <txtmark.version>0.13</txtmark.version>
    <hamcrest-all.version>1.3</hamcrest-all.version>
    <testng.version>6.9.4</testng.version>

    <javacc-maven-plugin.version>2.6</javacc-maven-plugin.version>
    <maven-assembly-plugin.version>2.4</maven-assembly-plugin.version>
    <jacoco-maven-plugin.version>0.7.2.201409121644</jacoco-maven-plugin.version>
    <appassembler-maven-plugin.version>1.8.1</appassembler-maven-plugin.version>
    <animal-sniffer-maven-plugin.version>1.11</animal-sniffer-maven-plugin.version>
    <surefire-testng.version>2.17</surefire-testng.version>
    <modernizer-maven-plugin.version>1.2.2</modernizer-maven-plugin.version>
    <maven-compiler-plugin.version>3.3</maven-compiler-plugin.version>
    <maven-surefire-plugin.version>2.17</maven-surefire-plugin.version>
    <maven-jar-plugin.version>2.5</maven-jar-plugin.version>
    <maven-bundle-plugin.version>2.5.0</maven-bundle-plugin.version>
    <maven-source-plugin.version>2.4</maven-source-plugin.version>
    <maven-javadoc-plugin.version>2.10.3</maven-javadoc-plugin.version>
    <asciidoctor-maven-plugin.version>1.5.2</asciidoctor-maven-plugin.version>
    <asciidoctorj-pdf.version>1.5.0-alpha.8</asciidoctorj-pdf.version>

    <distribution.repo.id>repo.eclipse.org</distribution.repo.id>
    <distribution.repo.url>https://repo.eclipse.org/content/repositories/golo-releases/</distribution.repo.url>
    <distribution.snapshots.id>repo.eclipse.org</distribution.snapshots.id>
    <distribution.snapshots.url>https://repo.eclipse.org/content/repositories/golo-snapshots/</distribution.snapshots.url>

  </properties>

  <distributionManagement>
    <repository>
      <id>${distribution.repo.id}</id>
      <name>Releases repository</name>
      <url>${distribution.repo.url}</url>
    </repository>
    <snapshotRepository>
      <id>${distribution.snapshots.id}</id>
      <name>Snapshots repository</name>
      <url>${distribution.snapshots.url}</url>
      <uniqueVersion>true</uniqueVersion>
    </snapshotRepository>
  </distributionManagement>

  <dependencies>

    <dependency>
      <groupId>org.ow2.asm</groupId>
      <artifactId>asm</artifactId>
      <version>${asm.version}</version>
    </dependency>

    <dependency>
      <groupId>com.googlecode.json-simple</groupId>
      <artifactId>json-simple</artifactId>
      <version>${json-simple.version}</version>
      <exclusions>
        <exclusion>
          <groupId>junit</groupId>
          <artifactId>junit</artifactId>
        </exclusion>
      </exclusions>
    </dependency>

    <dependency>
      <groupId>com.beust</groupId>
      <artifactId>jcommander</artifactId>
      <version>${jcommander.version}</version>
      <optional>true</optional>
    </dependency>

    <dependency>
      <groupId>com.github.rjeschke</groupId>
      <artifactId>txtmark</artifactId>
      <version>${txtmark.version}</version>
      <optional>true</optional>
    </dependency>

    <dependency>
      <groupId>org.ow2.asm</groupId>
      <artifactId>asm-util</artifactId>
      <version>${asm.version}</version>
      <scope>test</scope>
    </dependency>

    <dependency>
      <groupId>org.ow2.asm</groupId>
      <artifactId>asm-analysis</artifactId>
      <version>${asm.version}</version>
      <scope>test</scope>
    </dependency>

    <dependency>
      <groupId>org.hamcrest</groupId>
      <artifactId>hamcrest-all</artifactId>
      <version>${hamcrest-all.version}</version>
      <scope>test</scope>
    </dependency>

    <dependency>
      <groupId>org.skyscreamer</groupId>
      <artifactId>jsonassert</artifactId>
      <version>1.2.3</version>
      <scope>test</scope>
    </dependency>

    <dependency>
      <groupId>org.testng</groupId>
      <artifactId>testng</artifactId>
      <version>${testng.version}</version>
      <scope>test</scope>
      <exclusions>
        <exclusion>
          <groupId>junit</groupId>
          <artifactId>junit</artifactId>
        </exclusion>
      </exclusions>
    </dependency>

  </dependencies>

  <build>

    <resources>
      <resource>
        <directory>src/main/resources</directory>
        <filtering>true</filtering>
      </resource>
    </resources>

    <plugins>

      <plugin>
        <groupId>org.apache.maven.plugins</groupId>
        <artifactId>maven-compiler-plugin</artifactId>
        <version>${maven-compiler-plugin.version}</version>
        <configuration>
          <source>1.8</source>
          <target>1.8</target>
        </configuration>
      </plugin>

      <plugin>
        <groupId>org.apache.maven.plugins</groupId>
        <artifactId>maven-surefire-plugin</artifactId>
        <version>${maven-surefire-plugin.version}</version>
        <dependencies>
          <dependency>
            <groupId>org.apache.maven.surefire</groupId>
            <artifactId>surefire-testng</artifactId>
            <version>${surefire-testng.version}</version>
          </dependency>
        </dependencies>
        <configuration>
          <runOrder>random</runOrder>
          <parallel>classes</parallel>
          <perCoreThreadCount>2</perCoreThreadCount>
          <forkedProcessTimeoutInSeconds>180</forkedProcessTimeoutInSeconds>
          <systemPropertyVariables>
            <golo.test.trace>no</golo.test.trace>
            <java.awt.headless>true</java.awt.headless>
          </systemPropertyVariables>
        </configuration>
      </plugin>

      <plugin>
        <groupId>org.codehaus.mojo</groupId>
        <artifactId>javacc-maven-plugin</artifactId>
        <version>${javacc-maven-plugin.version}</version>
        <executions>
          <execution>
            <id>jjtree-javacc</id>
            <goals>
              <goal>jjtree-javacc</goal>
            </goals>
          </execution>
        </executions>
      </plugin>

      <plugin>
        <groupId>org.apache.maven.plugins</groupId>
        <artifactId>maven-jar-plugin</artifactId>
        <version>${maven-jar-plugin.version}</version>
        <configuration>
          <archive>
            <manifestFile>${project.build.outputDirectory}/META-INF/MANIFEST.MF</manifestFile>
          </archive>
        </configuration>
      </plugin>

      <plugin>
        <groupId>org.apache.felix</groupId>
        <artifactId>maven-bundle-plugin</artifactId>
        <version>${maven-bundle-plugin.version}</version>
        <extensions>true</extensions>
        <configuration>
          <instructions>
            <Bundle-RequiredExecutionEnvironment>JavaSE-1.8</Bundle-RequiredExecutionEnvironment>
          </instructions>
        </configuration>
        <executions>
          <execution>
            <id>bundle-manifest</id>
            <phase>process-classes</phase>
            <goals>
              <goal>manifest</goal>
            </goals>
          </execution>
        </executions>
      </plugin>

      <plugin>
        <groupId>org.codehaus.mojo</groupId>
        <artifactId>appassembler-maven-plugin</artifactId>
        <version>${appassembler-maven-plugin.version}</version>
        <executions>
          <execution>
            <phase>package</phase>
            <goals>
              <goal>assemble</goal>
            </goals>
          </execution>
        </executions>
        <configuration>
          <repositoryName>lib</repositoryName>
          <repositoryLayout>flat</repositoryLayout>
          <licenseHeaderFile>${project.basedir}/src/main/assembly/appassembler-license-header</licenseHeaderFile>
          <programs>
            <program>
              <id>golo</id>
              <mainClass>fr.insalyon.citi.golo.cli.Main</mainClass>
              <jvmSettings>
                <initialMemorySize>256m</initialMemorySize>
                <maxMemorySize>1024M</maxMemorySize>
                <maxStackSize>1024M</maxStackSize>
                <extraArguments>
                  <extraArgument>-server</extraArgument>
                  <extraArgument>-XX:-TieredCompilation</extraArgument>
                  <extraArgument>-XX:+AggressiveOpts</extraArgument>
                </extraArguments>
              </jvmSettings>
            </program>
            <program>
              <id>vanilla-golo</id>
              <mainClass>fr.insalyon.citi.golo.cli.Main</mainClass>
            </program>
          </programs>
        </configuration>
      </plugin>

      <plugin>
        <groupId>org.apache.maven.plugins</groupId>
        <artifactId>maven-assembly-plugin</artifactId>
        <version>${maven-assembly-plugin.version}</version>
        <configuration>
          <attach>false</attach>
          <descriptors>
            <descriptor>src/main/assembly/distribution.xml</descriptor>
          </descriptors>
        </configuration>
        <executions>
          <execution>
            <id>assembly-with-package</id>
            <phase>package</phase>
            <goals>
              <goal>single</goal>
            </goals>
          </execution>
        </executions>
      </plugin>

      <plugin>
        <groupId>org.apache.maven.plugins</groupId>
        <artifactId>maven-javadoc-plugin</artifactId>
        <version>${maven-javadoc-plugin.version}</version>
        <configuration>
          <additionalparam>-Xdoclint:none</additionalparam>
          <failOnError>false</failOnError>
        </configuration>
      </plugin>

      <plugin>
        <groupId>org.gaul</groupId>
        <artifactId>modernizer-maven-plugin</artifactId>
        <version>${modernizer-maven-plugin.version}</version>
        <configuration>
          <javaVersion>1.8</javaVersion>
          <ignorePackages>
            <ignorePackage>fr.insalyon.citi.golo.compiler.parser</ignorePackage>
          </ignorePackages>
        </configuration>
        <executions>
          <execution>
            <id>modernizer</id>
            <phase>compile</phase>
            <goals>
              <goal>modernizer</goal>
            </goals>
          </execution>
        </executions>
      </plugin>

    </plugins>
  </build>

  <profiles>

    <profile>
      <id>release</id>
      <build>
        <plugins>
          <plugin>
            <groupId>org.apache.maven.plugins</groupId>
            <artifactId>maven-source-plugin</artifactId>
            <version>${maven-source-plugin.version}</version>
            <executions>
              <execution>
                <id>attach-sources</id>
                <goals>
                  <goal>jar-no-fork</goal>
                </goals>
              </execution>
            </executions>
          </plugin>
          <plugin>
            <groupId>org.apache.maven.plugins</groupId>
            <artifactId>maven-javadoc-plugin</artifactId>
            <version>${maven-javadoc-plugin.version}</version>
            <executions>
              <execution>
                <id>attach-javadocs</id>
                <goals>
                  <goal>jar</goal>
                </goals>
              </execution>
            </executions>
          </plugin>
        </plugins>
      </build>
    </profile>

    <profile>
      <id>verbose-tests</id>
      <build>
        <plugins>
          <plugin>
            <groupId>org.apache.maven.plugins</groupId>
            <artifactId>maven-surefire-plugin</artifactId>
            <configuration>
              <systemPropertyVariables>
                <golo.test.trace>yes</golo.test.trace>
              </systemPropertyVariables>
            </configuration>
          </plugin>
        </plugins>
      </build>
    </profile>

    <!--
       This allows building Golo without building the .golo files.

       This is required in a clean-room environment, as the Maven plugin needs Golo... and Golo needs
       the plugin :-)
    -->
    <profile>
      <id>bootstrapped</id>
      <activation>
        <activeByDefault>true</activeByDefault>
      </activation>
      <build>
        <plugins>

          <plugin>
            <groupId>org.eclipse.golo</groupId>
            <artifactId>golo-maven-plugin</artifactId>
            <version>${project.version}</version>
            <executions>
              <execution>
                <id>goloc</id>
                <phase>compile</phase>
                <goals>
                  <goal>goloc</goal>
                </goals>
              </execution>
              <execution>
                <id>golodoc</id>
                <phase>prepare-package</phase>
                <goals>
                  <goal>golodoc</goal>
                </goals>
                <configuration>
                  <outputDirectory>target/generated-docs/golodoc</outputDirectory>
                </configuration>
              </execution>
            </executions>
          </plugin>

          <plugin>
            <groupId>org.apache.maven.plugins</groupId>
            <artifactId>maven-surefire-plugin</artifactId>
            <configuration>
              <environmentVariables>
                <golo.bootstrapped>yes</golo.bootstrapped>
              </environmentVariables>
            </configuration>
          </plugin>

        </plugins>
      </build>
    </profile>

    <profile>
      <id>test-coverage</id>
      <build>
        <plugins>
          <plugin>
            <groupId>org.jacoco</groupId>
            <artifactId>jacoco-maven-plugin</artifactId>
            <version>${jacoco-maven-plugin.version}</version>
            <executions>
              <execution>
                <goals>
                  <goal>prepare-agent</goal>
                </goals>
              </execution>
              <execution>
                <id>report</id>
                <phase>test</phase>
                <goals>
                  <goal>report</goal>
                </goals>
              </execution>
            </executions>
          </plugin>
          <plugin>
            <groupId>org.apache.maven.plugins</groupId>
            <artifactId>maven-surefire-plugin</artifactId>
            <configuration>
              <environmentVariables>
                <golo.bootstrapped>yes</golo.bootstrapped>
              </environmentVariables>
            </configuration>
          </plugin>
        </plugins>
      </build>
    </profile>

    <profile>
      <id>build-documentation</id>
      <activation>
        <activeByDefault>true</activeByDefault>
      </activation>
      <build>
        <plugins>
          <plugin>
            <groupId>org.asciidoctor</groupId>
            <artifactId>asciidoctor-maven-plugin</artifactId>
            <version>${asciidoctor-maven-plugin.version}</version>
            <dependencies>
              <dependency>
                <groupId>org.asciidoctor</groupId>
                <artifactId>asciidoctorj-pdf</artifactId>
                <version>${asciidoctorj-pdf.version}</version>
              </dependency>
            </dependencies>
            <configuration>
              <sourceDirectory>doc</sourceDirectory>
              <sourceDocumentName>golo-guide.asciidoc</sourceDocumentName>
              <embedAssets>true</embedAssets>
            </configuration>
            <executions>
              <execution>
                <id>asciidoc-html</id>
                <phase>prepare-package</phase>
                <goals>
                  <goal>process-asciidoc</goal>
                </goals>
                <configuration>
                  <backend>html5</backend>
                  <sourceHighlighter>prettify</sourceHighlighter>
                </configuration>
              </execution>
            </executions>
          </plugin>
        </plugins>
      </build>
    </profile>

    <profile>
      <id>build-pdf-documentation</id>
      <build>
        <plugins>
          <plugin>
            <groupId>org.asciidoctor</groupId>
            <artifactId>asciidoctor-maven-plugin</artifactId>
            <version>${asciidoctor-maven-plugin.version}</version>
            <dependencies>
              <dependency>
                <groupId>org.asciidoctor</groupId>
                <artifactId>asciidoctorj-pdf</artifactId>
                <version>${asciidoctorj-pdf.version}</version>
              </dependency>
            </dependencies>
            <configuration>
              <sourceDirectory>doc</sourceDirectory>
              <sourceDocumentName>golo-guide.asciidoc</sourceDocumentName>
              <embedAssets>true</embedAssets>
            </configuration>
            <executions>
              <execution>
                <id>asciidoc-pdf</id>
                <phase>prepare-package</phase>
                <goals>
                  <goal>process-asciidoc</goal>
                </goals>
                <configuration>
                  <backend>pdf</backend>
                  <sourceHighlighter>coderay</sourceHighlighter>
                  <attributes>
                    <pagenums/>
                    <toc/>
                    <idprefix/>
                    <idseparator>-</idseparator>
                  </attributes>
                </configuration>
              </execution>
            </executions>
          </plugin>
        </plugins>
      </build>
    </profile>

    <profile>
      <id>bintray</id>
      <properties>
        <distribution.repo.id>bintray</distribution.repo.id>
        <distribution.repo.url>https://api.bintray.com/maven/golo-lang/golo-lang/golo</distribution.repo.url>
      </properties>
    </profile>

  </profiles>

</project>
{% endhighlight %}

`distribution.xml`

{% highlight xml %}
<!--
  ~ Copyright (c) 2012-2015 Institut National des Sciences Appliquées de Lyon (INSA-Lyon)
  ~
  ~ All rights reserved. This program and the accompanying materials
  ~ are made available under the terms of the Eclipse Public License v1.0
  ~ which accompanies this distribution, and is available at
  ~ http://www.eclipse.org/legal/epl-v10.html
  -->

<assembly xmlns="http://maven.apache.org/plugins/maven-assembly-plugin/assembly/1.1.0"
          xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xsi:schemaLocation="http://maven.apache.org/plugins/maven-assembly-plugin/assembly/1.1.0 http://maven.apache.org/xsd/assembly-1.1.0.xsd">
  <id>distribution</id>
  <formats>
    <format>dir</format>
    <format>zip</format>
  </formats>
  <fileSets>
    <fileSet>
      <directory>${project.basedir}</directory>
      <includes>
        <include>README*</include>
        <include>LICENSE*</include>
        <include>CONTRIB*</include>
        <include>THIRD-PARTY*</include>
        <include>notice.html</include>
        <include>epl-v10.html</include>
        <include>samples/**/*</include>
        <include>share/**/*</include>
      </includes>
      <useDefaultExcludes>true</useDefaultExcludes>
    </fileSet>
    <fileSet>
      <directory>target/generated-docs/</directory>
      <outputDirectory>/doc</outputDirectory>
      <includes>
        <include>*.html</include>
        <include>*.pdf</include>
        <include>golodoc/**</include>
      </includes>
      <useDefaultExcludes>true</useDefaultExcludes>
    </fileSet>
    <fileSet>
      <directory>target/appassembler/lib</directory>
      <outputDirectory>/lib</outputDirectory>
      <includes>
        <include>*.jar</include>
      </includes>
      <useDefaultExcludes>true</useDefaultExcludes>
    </fileSet>
    <fileSet>
      <directory>target/appassembler/bin</directory>
      <outputDirectory>/bin</outputDirectory>
      <fileMode>0755</fileMode>
      <lineEnding>unix</lineEnding>
      <includes>
        <include>golo</include>
        <include>vanilla-golo</include>
      </includes>
      <excludes>
        <exclude>*.bat</exclude>
      </excludes>
    </fileSet>
    <fileSet>
      <directory>target/appassembler/bin</directory>
      <outputDirectory>/bin</outputDirectory>
      <lineEnding>dos</lineEnding>
      <includes>
        <include>*.bat</include>
      </includes>
    </fileSet>
  </fileSets>
</assembly>
{% endhighlight %}

`golo-maven-plugin/pom.xml`, since we need to compile Golo with... Golo!

{% highlight xml %}
<?xml version="1.0" encoding="UTF-8"?>

<!--
  ~ Copyright (c) 2012-2015 Institut National des Sciences Appliquées de Lyon (INSA-Lyon)
  ~
  ~ All rights reserved. This program and the accompanying materials
  ~ are made available under the terms of the Eclipse Public License v1.0
  ~ which accompanies this distribution, and is available at
  ~ http://www.eclipse.org/legal/epl-v10.html
  -->

<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
  <modelVersion>4.0.0</modelVersion>

  <groupId>org.eclipse.golo</groupId>
  <artifactId>golo-maven-plugin</artifactId>
  <version>3.0.0-incubation-SNAPSHOT</version>

  <packaging>maven-plugin</packaging>

  <name>Golo Maven Plugin (Incubation)</name>
  <description>Golo Maven Plugin.</description>
  <url>http://golo-lang.org/</url>

  <developers>
    <developer>
      <name>Golo committers</name>
      <email>golo-dev@eclipse.org</email>
    </developer>
  </developers>

  <licenses>
    <license>
      <name>Eclipse Public License - v 1.0</name>
      <url>http://www.eclipse.org/legal/epl-v10.html</url>
      <distribution>repo</distribution>
    </license>
  </licenses>

  <scm>
    <connection>scm:git:git@github.com:eclipse/golo-lang.git</connection>
    <url>scm:git:git@github.com:eclipse/golo-lang.git</url>
    <developerConnection>scm:git:git@github.com:eclipse/golo-lang.git</developerConnection>
  </scm>

  <properties>

    <txtmark.version>0.13</txtmark.version>

    <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
    <surefire.useFile>false</surefire.useFile>

    <maven-compiler-plugin.version>3.3</maven-compiler-plugin.version>
    <maven-plugin-api.version>3.0.5</maven-plugin-api.version>
    <maven-plugin-plugin.version>3.2</maven-plugin-plugin.version>
    <maven-javadoc-plugin.version>2.10.3</maven-javadoc-plugin.version>
    <maven-source-plugin.version>2.4</maven-source-plugin.version>

    <distribution.repo.id>repo.eclipse.org</distribution.repo.id>
    <distribution.repo.url>https://repo.eclipse.org/content/repositories/golo-releases/</distribution.repo.url>
    <distribution.snapshots.id>repo.eclipse.org</distribution.snapshots.id>
    <distribution.snapshots.url>https://repo.eclipse.org/content/repositories/golo-snapshots/</distribution.snapshots.url>

  </properties>

  <distributionManagement>
    <repository>
      <id>${distribution.repo.id}</id>
      <name>Releases repository</name>
      <url>${distribution.repo.url}</url>
    </repository>
    <snapshotRepository>
      <id>${distribution.snapshots.id}</id>
      <name>Snapshots repository</name>
      <url>${distribution.snapshots.url}</url>
      <uniqueVersion>true</uniqueVersion>
    </snapshotRepository>
  </distributionManagement>

  <dependencies>

    <dependency>
      <groupId>org.apache.maven</groupId>
      <artifactId>maven-plugin-api</artifactId>
      <version>${maven-plugin-api.version}</version>
    </dependency>

    <dependency>
      <groupId>org.eclipse.golo</groupId>
      <artifactId>golo</artifactId>
      <version>${project.version}</version>
    </dependency>

    <dependency>
      <groupId>com.github.rjeschke</groupId>
      <artifactId>txtmark</artifactId>
      <version>${txtmark.version}</version>
    </dependency>

  </dependencies>

  <build>

    <plugins>

      <plugin>
        <groupId>org.apache.maven.plugins</groupId>
        <artifactId>maven-compiler-plugin</artifactId>
        <version>${maven-compiler-plugin.version}</version>
        <configuration>
          <source>1.8</source>
          <target>1.8</target>
        </configuration>
      </plugin>

      <plugin>
        <groupId>org.apache.maven.plugins</groupId>
        <artifactId>maven-plugin-plugin</artifactId>
        <version>${maven-plugin-plugin.version}</version>
        <configuration>
          <extractors>
            <extractor>java</extractor>
          </extractors>
        </configuration>
      </plugin>

      <plugin>
        <groupId>org.apache.maven.plugins</groupId>
        <artifactId>maven-javadoc-plugin</artifactId>
        <version>${maven-javadoc-plugin.version}</version>
        <configuration>
          <additionalparam>-Xdoclint:none</additionalparam>
          <failOnError>false</failOnError>
        </configuration>
      </plugin>

    </plugins>
  </build>

  <profiles>
    <profile>
      <id>release</id>
      <build>
        <plugins>
          <plugin>
            <groupId>org.apache.maven.plugins</groupId>
            <artifactId>maven-source-plugin</artifactId>
            <version>${maven-source-plugin.version}</version>
            <executions>
              <execution>
                <id>attach-sources</id>
                <goals>
                  <goal>jar-no-fork</goal>
                </goals>
              </execution>
            </executions>
          </plugin>
          <plugin>
            <groupId>org.apache.maven.plugins</groupId>
            <artifactId>maven-javadoc-plugin</artifactId>
            <version>${maven-javadoc-plugin.version}</version>
            <executions>
              <execution>
                <id>attach-javadocs</id>
                <goals>
                  <goal>jar</goal>
                </goals>
              </execution>
            </executions>
          </plugin>
        </plugins>
      </build>
    </profile>
    <profile>
      <id>bintray</id>
      <properties>
        <distribution.repo.id>bintray</distribution.repo.id>
        <distribution.repo.url>https://api.bintray.com/maven/golo-lang/golo-lang/golo-maven-plugin</distribution.repo.url>
      </properties>
    </profile>
  </profiles>

</project>
{% endhighlight %}

#### Gradle files

`build.gradle`

{% highlight groovy %}
/*
 * Copyright (c) 2012-2015 Institut National des Sciences Appliquées de Lyon (INSA-Lyon)
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 */

plugins {
  id 'java'
  id 'ca.coglinc.javacc' version '2.2.2'
  id 'org.asciidoctor.convert' version '1.5.2'
  id 'net.nemerosa.versioning' version '1.5.0'
  id 'jacoco'
  id 'application'
  id 'maven-publish'
  id 'eclipse'
  id 'idea'
}

repositories {
  jcenter()
}

ext {
  goloCliMain = 'fr.insalyon.citi.golo.cli.Main'
  goloSources = fileTree('src/main/golo').include('**/*.golo')
  goloClasses = file("$buildDir/classes/golo")
  goloDocs = file("$buildDir/docs/golodoc")
}

group = 'org.eclipse.golo'
version = '3.0.0-incubation-SNAPSHOT'

sourceCompatibility = 1.8
targetCompatibility = 1.8

apply from: 'gradle/repo-detection.gradle'

sourceSets {
  main {
    java {
      srcDir compileJjtree.outputDirectory
      srcDir compileJavacc.outputDirectory
    }
    output.dir goloClasses
  }
  test {
     runtimeClasspath += files(goloClasses)
   }
}

dependencies {

  compile 'org.ow2.asm:asm:5.0.4'
  compile 'com.beust:jcommander:1.48'
  compile 'com.github.rjeschke:txtmark:0.13'
  compile('com.googlecode.json-simple:json-simple:1.1.1') {
    exclude(module: 'junit')
  }

  testCompile 'org.ow2.asm:asm-util:5.0.4'
  testCompile 'org.ow2.asm:asm-analysis:5.0.4'
  testCompile 'org.hamcrest:hamcrest-all:1.3'
  testCompile 'org.skyscreamer:jsonassert:1.2.3'
  testCompile('org.testng:testng:6.9.4') {
    exclude(module: 'junit')
  }
}

eclipse {
  project {
    name = 'golo-lang'
  }
}

eclipseClasspath.dependsOn("compileJavacc")

task goloc(type: JavaExec, dependsOn: classes) {
  main = goloCliMain
  args = ['compile', '--output', goloClasses] + goloSources
  classpath = sourceSets.main.runtimeClasspath
  inputs.files goloSources
  outputs.dir goloClasses
  description = 'Compiles Golo source files.'
  group = 'Build'
}

if (!project.hasProperty('bootstrap')) {
  jar.dependsOn goloc
  test.dependsOn goloc
  goloc.shouldRunAfter compileJava
  test.environment 'golo.bootstrapped', 'yes'
}

test {
  useTestNG()
  testLogging.showStandardStreams = project.hasProperty('consoleTraceTests')
  systemProperty 'golo.test.trace', project.hasProperty('traceTests') ? 'yes' : 'no'
  systemProperty 'java.awt.headless', 'true'
}

processResources {
  filter(org.apache.tools.ant.filters.ReplaceTokens, tokens: [
    version: version,
    timestamp: versioning.info.full
  ])
}

asciidoctorj {
  version = '1.5.2'
}

asciidoctor {
  sourceDir 'doc'
  sources {
    include 'golo-guide.asciidoc'
  }
  backends 'html5'
}

assemble.dependsOn asciidoctor

task golodoc(type: JavaExec, dependsOn: classes) {
  main = goloCliMain
  args = ['doc', '--format', 'html', '--output', goloDocs] + goloSources
  classpath = sourceSets.main.runtimeClasspath
  inputs.files goloSources
  outputs.dir goloDocs
  description = 'Generates documentation of the standard Golo modules.'
  group = 'Documentation'
}

golodoc.dependsOn goloc

task createVanillaScripts(type: CreateStartScripts) {
  outputDir = file('build/vanilla-golo')
  mainClassName = goloCliMain
  applicationName = 'vanilla-golo'
  classpath = startScripts.classpath
}

mainClassName = goloCliMain
applicationDefaultJvmArgs = [
  '-Xms256m', '-Xmx1024M', '-Xss1024M', '-server', '-XX:-TieredCompilation', '-XX:+AggressiveOpts'
]

startScripts.dependsOn createVanillaScripts

distributions {
  main {
    contents {
      from(projectDir) {
        include 'README*'
        include 'CONTRIB*'
        include 'THIRD-PARTY'
        include 'notice.html'
        include 'epl-v10.html'
      }
      into('samples') {
        from('samples') {
          include '**/*.golo'
        }
      }
      into('share') {
        from 'share'
      }
      from(asciidoctor.outputDir) {
        into 'docs'
      }
      from(golodoc) {
        into 'docs/golodoc'
      }
      from(createVanillaScripts.outputDir) {
        into 'bin'
      }
    }
  }
}

publishing {
  publications {
    mavenJava(MavenPublication) {
      pom.withXml {
        asNode().children().last() + {
          resolveStrategy = Closure.DELEGATE_FIRST
          name 'Golo Programming Language (Incubation)'
          description 'Golo: a lightweight dynamic language for the JVM.'
          url 'http://golo-lang.org/'
          developers {
            developer {
              name 'Golo committers'
              email 'golo-dev@eclipse.org'
            }
          }
          licenses {
            license {
              name 'Eclipse Public License - v 1.0'
              url 'http://www.eclipse.org/legal/epl-v10.html'
              distribution 'repo'
            }
          }
          scm {
            url 'https://github.com/eclipse/golo-lang'
            connection 'scm:git:git@github.com:eclipse/golo-lang.git'
            developerConnection 'scm:git:ssh:git@github.com:eclipse/golo-lang.git'
          }
        }
      }
      from components.java
      artifact sourceJar {
        classifier 'sources'
      }
      artifact javadocJar {
        classifier 'javadoc'
      }
    }
  }
  repositories {
    // Credentials shall be stored in ~/.gradle/gradle.properties
    maven {
      url goloMavenRepoUrl
      credentials {
        username goloMavenRepoUsername
        password goloMavenRepoPassword
      }
    }
  }
}

task sourceJar(type: Jar) {
  from sourceSets.main.allJava
}

javadoc.options.addStringOption('Xdoclint:none', '-quiet')

task javadocJar (type: Jar, dependsOn: javadoc) {
  from javadoc.destinationDir
}

task wrapper(type: Wrapper) {
  gradleVersion = '2.6'
  description 'Generates the Gradle wrapper scripts.'
}
{% endhighlight %}

`settings.gradle`

{% highlight groovy %}
/*
 * Copyright (c) 2012-2015 Institut National des Sciences Appliquées de Lyon (INSA-Lyon)
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 */

rootProject.name = 'golo'
{% endhighlight %}

`gradle/repo-detection.gradle`

{% highlight groovy %}
/*
 * Copyright (c) 2012-2015 Institut National des Sciences Appliquées de Lyon (INSA-Lyon)
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 */

if (project.hasProperty('releaseProfile')) {
  switch (releaseProfile) {
    case 'eclipse':
      ext.goloMavenRepoUrl = 'https://repo.eclipse.org/content/repositories/golo-' + ((version.endsWith('-SNAPSHOT')) ? 'snapshots/' : 'releases/')
      ext.goloMavenRepoUsername = eclipseRepoUsername
      ext.goloMavenRepoPassword = eclipseRepoPassword
      break
    case 'bintray':
      ext.goloMavenRepoUrl = 'https://api.bintray.com/maven/golo-lang/golo-lang/golo'
      ext.goloMavenRepoUsername = bintrayRepoUsername
      ext.goloMavenRepoPassword = bintrayRepoPassword
      break
    default:
      throw new GradleException("Unknown release profile: $releaseProfile")
  }
} else {
  ext.goloMavenRepoUrl = "$buildDir/maven-repo"
  ext.goloMavenRepoUsername = ''
  ext.goloMavenRepoPassword = ''
}
{% endhighlight %}
