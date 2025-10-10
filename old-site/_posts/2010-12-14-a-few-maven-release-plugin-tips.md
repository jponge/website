---
title: A Few Maven Release Plugin Tips
layout: post
---

The [Maven Release plugin](http://maven.apache.org/plugins/maven-release-plugin/) can’t be ignored if you have some Maven-managed projects. If everything is well set-up, releasing a new version of your project is breeze… but if not then you will most probably hate that plugin.

We have [a straightforward release process for IzPack](http://docs.codehaus.org/display/IZPACK/Releasing+IzPack) that has the advantage of being fully automated as we specify the release version and subsequent development version as part of the Maven invocation. If you don’t do that, Maven will ask you for those versions. By all means you want to automate everything!

Starting from IzPack 5.0.0-beta5, the process works just right… but I’ve had to make some tweaks. Here are a few things I had to do and that may be useful in your own builds too!

## Dealing with a DVCS

If you use a centralized version control system such as Subversion, the release plugin will happily tag the remote repository. That’s fine, but if you are using a distributed SCM such as Git or Mercurial, you will quickly hate the default behavior which:

1. makes local commits to upgrade the versions,
2. makes a local tag for the new version,
3. pushes all the changes upstream... !!!

This behavior is awful, as it forces you into a model where you always have an upstream repository. Even if this is your case like most projets do, you are likely to have issues in Maven launching your “DVCS push” command. You will most probably prefer to do it by yourself, which is an extra advantage if you run into an issue at the later stages of the release process, because you can always undo your commits locally.

Here is how to make the release plugin behave as one would expect with a DVCS:

{% highlight xml %}
<plugin>
    <groupId>org.apache.maven.plugins</groupId>
    <artifactId>maven-release-plugin</artifactId>
    <configuration>
        <localCheckout>true</localCheckout>
        <pushChanges>false</pushChanges>
    </configuration>
</plugin>
{% endhighlight %}

## Don’t deploy a website

As long as you have specified a distribution management in your POM, the release plugin will deploy both your compiled artifacts and the generated website. Maven-generated websites are mainly useful for reports. The problem is that the remote server may disconnect you will you are running the tests or uploading artifacts on a submodule of your project, which will result in the build failing.

The solution is to force it not to deploy the website. Just upload the artifacts as part of the build, and latter run a “mvn site:deploy” if you like.

{% highlight xml %}
<plugin>
    <groupId>org.apache.maven.plugins</groupId>
    <artifactId>maven-release-plugin</artifactId>
    <configuration>
        <localCheckout>true</localCheckout>
        <pushChanges>false</pushChanges>
        <goals>deploy</goals>
    </configuration>
</plugin>
{% endhighlight %}

## Deal with signed artifacts requirements

Requirements for having your artifacts pushed to Maven central have changed. Everything now has to be signed with GnuPG. If you read the plugin documentation, you will most probably do like in the examples and attach the plugin to the “verify” phase. This doesn’t work as some artifacts are generated or modified in the later phases, resulting in missing and invalid signatures.

At first I tried to attach it to the “package” phase, until I figured out that assemblies are being handled later than “package”. Because those assemblies are uploaded as well, I had missing signatures, resulting in the Codehaus Nexus repository preventing me from doing a release.

The solution is to attach the plugin to the “install” phase, and only when releases are being made:

{% highlight xml %}
<profile>
    <id>release-sign-artifacts</id>
    <activation>
        <property>
            <name>performRelease</name>
            <value>true</value>
        </property>
    </activation>
    <build>
        <plugins>
            <plugin>
                <groupId>org.apache.maven.plugins</groupId>
                <artifactId>maven-gpg-plugin</artifactId>
                <version>1.1</version>
                <executions>
                    <execution>
                        <phase>install</phase>
                        <goals>
                            <goal>sign</goal>
                        </goals>
                    </execution>
                </executions>
            </plugin>
        </plugins>
    </build>
</profile>
{% endhighlight %}

I hope this can be useful to some of you!
