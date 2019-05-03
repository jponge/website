---
title: "Java Coding With Style"
layout: post
---

What few may realize is that we are extremely lucky with the tooling quality in the Java world.

This note summarizes my current recommendations for coding in Java with style.

## IDEs and text editors

There is no better way to ignite a troll than discussing the merits of an IDE or a text editor.

First off: doing Java development without an IDE is just absurd. IDEs are not text editors. They
understand your code. They can refactor your code. They can perform some kinds of static analysis.
They can run your tests. They can just load your project definition from an independent build system
like Maven.

I sometimes bump into die-hard folks that claim to be more productive in Java with Vim rather than
with an IDE. Coding in Vim is not bad, especially if you master it, but rejecting IDEs in 2013 is
stupid, especially in the Java world where tooling is exceptionally polished. Long is gone the days
of JBuilder or other constraining IDEs. Most justifications for not using an IDE were more often
than not a severe form of blind conservatism in disguise, not even counting the desire to feel superior
just because a tool like Vim requires some mastery.

In terms of IDEs I strongly recommend [IntelliJ IDEA](http://www.jetbrains.com/idea/). The community
version is more than enough for Java SE and Android development. You may equally opt for
[Netbeans](http://netbeans.org). Every release of Netbeans brings it on par with IDEA, and sometimes
even slightly ahead.

Do not use [Eclipse](http://www.eclipse.org/) unless you absolutely have to, or muscle memory is too
hard to reboot. I have been an Eclipse plugin developer a few years ago and actually enjoyed it.
However what Eclipse has become does not appeal to me anymore. The competition (IDEA, Netbeans) is
simply too far ahead, and healthy.

For anything else knowing a good text editor or two is a necessity. I recommend [Vim](http://www.vim.org)
as it works everywhere you go. The learning curve is steep, but it pays off in the long run.
On Mac OS X I also enjoy [TextMate](https://github.com/textmate/textmate) very much. I bought a license
in 2008 and never regretted it. TextMate 2 is opensource, hence there is no reason not to go
for it.

Last but not least: do not use Emacs unless you actually want to hurt your hands, or you have
a fascination for Richard Stallman.

## Loving Maven

Ah... [Maven](http://maven.apache.org/)!

Yes I know, Maven is a common source of jokes and troll in the Java world. It downloads the
Internet, anything that you need to customize requires writing a plugin or using the ugly
[AntRun plugin](http://maven.apache.org/plugins/maven-antrun-plugin/), and... XML hurts.

**Yet, despite all of this, I love Maven, and I am no masochist.**

To me, Maven is all about:

* giving structure to your project,
* having excellent tool support (IDEs, continuous integration servers, ...),
* a high probability that a plugin exists for whatever you need.

Again, XML hurts, but I don't touch my POMs that often. Once a POM is in place, most edits will be
about adding a new plugin once in a while and updating versions. The decoupling between the *"what"*
and the *"how"* in Maven is useful for most projects.

[Gradle](http://www.gradle.org) is an interesting alternative to Maven, just like
[Apache BuildR](http://buildr.apache.org/). In most cases I would still recommend going the Maven route
until both mature. Of the two, Gradle has the most potential. They embrace a declarative-style,
convention-based build definition that is the strength of Maven, while allowing the definition of
custom tasks without the need for systematically writing external plugins.

We used Apache BuildR in [JooFlux](https://github.com/dynamid/jooflux) because we had a need for
*many* custom tasks. We looked at Gradle initially, but it had issues with Java 7 on Mac OS X. This
is a very specific kind of project, though.

In most cases I always found it both simpler and more structuring to bend a project into the Maven
conventions rather than fighting those.

## Continuous testing with Infinitest

Fellow [OSSGTP](http://www.ossgtp.org) member [David Gageot](https://twitter.com/dgageot)
maintains an awesome tool called [Infinitest](http://infinitest.github.com).

It comes in the form of a plugin for Eclipse (damn!) or IDEA (yeah!) that automatically launches tests
whenever you save a file. It intelligently guesses which tests have been impacted and launches them again
on changes, giving you instant feedback.

I rarely launch tests from my IDE and prefer going to the terminal console to launch `mvn test`. It
is somehow faster for me to simply switch applications. I also have less friction navigating through
console outputs in a terminal application rather than in a view of my IDE. Maybe I am just strange.

I strongly recommend installing Infinitest. You will be surprised to see how incredibly useful the
tool can be!

## Wrapping Rake around Maven

[Rake](http://rake.rubyforge.org) is a build tool written in Ruby. It defines tasks just like
a `Makefile`, except that it comes in the form of a nice Ruby domain-specific language.

I use Rake for anything that does not fit into Maven. Ruby launches fast, and Rake just does what it
is supposed to do with lots of elegance.

It is sometimes the case that I need to type long Maven commands, especially to launch a specific
test case with extra verbosity. In such cases, I use Rake to launch Maven, giving me a range of
easy-to-remember tasks such as:

    $ rake -T
    rake all                      # Build a complete distribution (packages + documentation)
    rake build                    # Build and install
    rake clean                    # Clean
    rake doc                      # Build the documentation
    rake rebuild                  # Clean, build and install
    rake run:golo[arguments]      # Run golo
    rake run:goloc[arguments]     # Run goloc
    rake run:gologolo[arguments]  # Run gologolo
    rake test:all                 # Run all tests
    rake test:bytecode            # Bytecode compilation output tests (verbose)
    rake test:parser              # Parser tests (verbose)
    rake test:run                 # Samples running tests (verbose)
    rake test:visitors            # IR tests (verbose)

As an example, the definition of the `test:run` task wraps Maven as follows:

{% highlight ruby %}
desc "Samples running tests (verbose)"
task :run do
  sh "mvn test -Dtest=CompileAndRunTest -P verbose-tests"
end
{% endhighlight %}

The combination of Rake and Maven works great for me, and I encourage you to give it a try.

## AsciiDoc

My final recommendation for coding with style is to use [AsciiDoc](http://asciidoc.org) for your
documentation.

It uses a simple text syntax that lets you organize the many chapters of your documentation.
AsciiDoc outputs either direct HTML with nice themes, or converts to XML DocBook. From there
you can then generate HTML, chunked HTML, PDF, ePub, ...

I was initially skeptic with AsciiDoc and thought about using Markdown. Having tried both, 
AsciiDoc just scales better for large documents, while Markdown excels at smaller documents.

I suggest looking at [some slides by Dan Allen from Red Hat](http://mojavelinux.github.com/decks/)
as they make a strong case for AsciiDoc. Bonus: his slides were made using AsciiDoc!

XML DocBook is just a nightmare. I don't know how can somebody decently write anything with such
a complicated XML format. AsciiDoc allows you to write documentation in a humane syntax, and then
let it be converted to DocBook.

If you absolutely want to tie documentation generation with your Maven builds, you can imagine
a Rake build for your documentation that outputs DocBook XML to the location expected by a
Maven DocBook plugin. Again, best of both worlds!

## Conclusion

I hope that those recommendations will be useful to others.

While they work great for me, I understand that not everyone will agree with this. Your mileage varies
depending on your own tastes and work context.

Feel free to get in touch!

