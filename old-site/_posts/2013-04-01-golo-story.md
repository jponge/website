---
title: "Golo Story"
layout: post
---

So... I started writing this while in the train to Lyon going back from the [Devoxx France 2013 conference](http://www.devoxx.fr/) held in Paris.

The fact that this note got eventually published on April 1st is of course *pure coincidence*.

What a week it has been! As you probably know by now, I demoed and released my latest creation: the [Golo programming language](http://golo-lang.org/).

Before this release there are many months of work behind, and I thought that it could be a good idea to share the story behind Golo with you.

## How it started

I started working on Golo in July 2012. I initially did not intend to make a *real* language as I was instead looking into playing further with `invokedynamic`.

My colleague Fred Le Mouel and I had started a research project the year before around the idea of taking advantage of `invokedynamic` to provide a JVM agent for dynamic aspect-oriented programming. [Here was born JooFlux](https://github.com/dynamid/jooflux), a research project for which there is still so much to be done.

We were all fresh on the things around the JVM. At that time we did not knew much about how a modern adaptive virtual machine such as HotSpot worked. We learned about inline-caches, deoptimization, bytecode weaving and more generally about all of those black magic patterns and practices. For somebody like myself who had a background in enterprise middleware design, I can tell how exciting yet scary learning such low-level stuff was.

But it was worth the pain.

I had never written a language before, and we were only using a limited set of the possibilities of `invokedynamic` in JooFlux, so the natural next step was to play with writting a dynamic language.

## But why, oh why?

Basically there are 2 justifications for a computer scientist like myself to devote so much time on creating a new language while there are already so many (good!) ones on the JVM.

First off, I am working in a [small team](http://dynamid.citi-lab.fr/) whose focus is around dynamic middleware and applications. As such, I am developing my research expertise on everything that sits between a dynamic application and its runtime environment.

While we now know how to hack into existing compiled applications as we did in JooFlux to inject efficient AOP, we also frequently would love to play with language extensions. Some languages such as Ruby or Groovy provide excellent extension points, but it is more than often the case that the scope of a language semantics goes well beyond the scope that we would like to keep it into. The code bases of such projects tend to be quite large, too. It is very much possible to use such languages, but there are many cases where having a tiny language would be a better fit in a research context.

A language with a small codebase, a small runtime, ... the kind of language where a student working on a 4 months project won't spend 3 of them just understanding how it works. The learning curve is indeed very steep for anybody new to programming languages design and implementations, and students clearly fall into that category.

Another good justification for making a new language is simply that **the only way to develop an expertise into an area is simply to make all possible mistakes you can do**.

Being myself new to virtual machines and dynamic languages implementation, the best thing that I could do was to jump in hands-on.

## So... what's next?

Golo is made to be simple to use, simple to hack.

It works *fast* on the JVM. It is very lightweight and easy to embed in existing apps.

It is a good learning example of how `invokedynamic` can be used to create small and efficient runtimes for dynamic languages.

As a research group, we now have a basis to work on, and to experiment extensions and ideas with. I learned tons of useful things along the way, which will definitely strengthen our group expertise and credibility in the field.

Beyond that, we are going to develop it further in the open, and we invite the larger JVM community to play with Golo.

**Hack with it. Hack it.**

There is no limit as long as you stick to our core values: 

1. be fun,
2. be respectful,
3. don't take what you do too seriously.

## But you do have hidden plans, don't you?

No.

Golo is being developed as part of normal research activities. It belongs to [my (public) institution](http://www.insa-lyon.fr/).

Golo is made available under the terms of a [very liberal license](https://github.com/golo-lang/golo-lang/blob/master/LICENSE), and if you decide to contribute we will just need you to sign a simple contributor license agreement.

Golo is certainly a good case for dissemination, technology transfer and academic-industry collaboration.

## Why working behind closed doors for so long?

That's a pretty good question.

The problem with Golo is that it's basically a one-man show: myself, myself and myself.

I did not get any specific funding to work on this project, which means that I devoted part of my research time to it, and mostly many hours at night.

I have more than 10 years of opensource experience at a fairly good international level. I know what it's like to create a project, promote it, build a community, and eventually pass the torch to fresher minds when your time is gone.

A language is a very special piece of software. Many companies are betting on their own JVM language to sell middleware stacks or IDEs. People love to troll about languages. It is anything but a space where you can be in peace.

If I had made Golo opensource from day 1, then I would probably have never been able to get to the state where it is today. I would have faced early criticism, early suggestions on how to do things, and so on. You cannot develop a JVM language *and* have many communication channels open at the same time.

What happened to [Nashorn](http://openjdk.java.net/projects/nashorn/)? Pretty much the same story: they bootstraped the project in a quiet environment before making the code public.

All you need to get to a minimally viable product is some time in peace and a few people you trust to give you feedback. People you know to have no conflict of interest in telling you if anything is *genius* or a *huge pile of crap*.

I had the immense privilege of having a few people motivated enough to give Golo a try, and they all made a huge impact, be it with just testing the provided samples or hacking weird things with the language.

I know that some people got frustrated with the development happening in the shadows while I did some occasional buzz around the *"yet-to-be-released"* language.

Just put yourself into my shoes with all context in mind for a minute, and maybe you'll understand why I did things this way.

## Conclusion

I don't know what the future holds for Golo, really.

The sure thing I know is that I am proud of what I have achieved in so little time, and that I am even prouder and humbled of having had the enthusiastic early testers to help me along the way.

The early feedback now that the project is open seems to be pretty positive, so this will definitely encourage me in going further ahead.

Golo is there, and you are invited to have fun with it! Golo is for all of you, not just rock star programmers.

I am looking forward to hearing what you will do with it, and in any case feel free to ping me with ideas, suggestions and constructive criticism!

* [golo-lang.org](http://golo-lang.org/)
* [Golo on GitHub](https://github.com/golo-lang/golo-lang)
* [Try Golo from a web browser](http://golo-console.appspot.com/)
