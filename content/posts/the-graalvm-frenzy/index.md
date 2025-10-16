---
date: '2018-09-06'
title: 'The GraalVM Frenzy'
readTime: true
toc: true
autonumber: true
aliases:
     - /blog/the-graalvm-frenzy
---

It seems like the whole Java ecosystem is going mad these days with [GraalVM](https://www.graalvm.org/). Every library and framework wants to proudly work on GraalVM, making GraalVM a new *silver bullet* for modern Java applications.

I expect the GraalVM crazyness to follow the typical hype cycle, and soon we will hear of disillusions and people will actually understand what GraalVM is *— and more importantly —* what GraalVM is not.

## Where does Graal(VM) comes from?

Graal is a what happens when you give a group of academic and industry researchers ample time and budget to work on interesting problems.

The history of Graal dates back to the [research works on MaxineVM](https://dl.acm.org/citation.cfm?id=2400689), also known as a *meta-circular virtual machine*. If this sounds complicated then all you really have to understand is that MaxineVM is a Java virtual machine written in… Java (hence it is *meta-circular*).

Fast forward a few years and the people behind this project have made great research and great prototypes. Most software from research projects remain in some experimental state, but since Oracle has invested a lot over the last few years and the results are good, they now invest in turning the results of this project into a product called GraalVM.

*(note: I have absolutely no insider information)*

## So what is Graal(VM)?

Graal is a native code generator, just like LLVM. You give it some intermediate model of executable code, and then you get native code for processors. And of course it is written in Java.

Once you have a code generator, you can do many other things such as a compiler to native code for some language, you can do a JIT *(just-in-time) *compiler for another language, etc.

## Why do people manifest so much interest?

Cloud. Containers. You name it :-)

What excites people so much about GraalVM is a sub-project called *SubstrateVM* (SVM), and that compiles JVM applications to native executables. This is also called a *ahead-of-time* compiler.

Once you compile a JVM application into a native executable, it can run without a JVM. In fact, what you get is a self-contained executable just like you would get with Go.

This is interesting in a container world since the process starts *fast*, and since there is no virtual machine there is no code to generate with a JIT, and the process uses much less memory (a traditional issue for JVM in a memory-capped environment).

My colleague Paulo Lopes has a [Vert.x application running as 38MB Docker image consuming 10MB of RAM](https://www.jetdrone.xyz/2018/08/10/Vertx-native-image-10mb.html). While Vert.x has always been leaner compared to *mastodon* JVM frameworks, this is still an impressive result.

## So why do you talk about upcoming disillusions?

Don’t get me wrong: GraalVM is a very interesting project!

What is important however is to realize that while SVM is an interesting option compared to running a traditional JVM, things aren’t that simple.

### Not every JVM application can be compiled to SVM.

Reflection is a problem for an AOT compiler, so you need to help the compiler by telling it of all classes that may be dynamically loaded at runtime. Since reflection and dynamic loading are key ingredients in many libraries and frameworks, your mileage varies greatly depending on your stack.

You can check out the full list of limitations here: [https://github.com/oracle/graal/blob/master/substratevm/LIMITATIONS.md](https://github.com/oracle/graal/blob/master/substratevm/LIMITATIONS.md)

### There is no JIT

The native executables produced by SVM do not have a JIT compiler.

This means that while the process start fast compared to a JVM, there is no profiler and JIT compiler to aggressively generate better code at runtime.

### The garbage-collector is simpler

The JVM is a great place for the development of garbage-collectors that are suited at very specific workloads.

Just like there is no JIT compiler in a SVM-produced executable, the garbage-collector is a simpler one. Again, this may not necessarily be an issue in your particular setting, but it may be worth comparing how your application fares:

* on a JVM with a fine-tuned GC, and
* as a standalone native executable.

## GraalVM is not just SubstrateVM!

Remember that Graal is a code generator, and SubstrateVM is only one facet.

There are more things in the larger GraalVM project like being a platform for interoperability between languages, fast implementations of JavaScript / R / Ruby, executing native code, Truffle for building language interpreters, etc.

### Hotspot is getting old

The JVM traditionally uses the *Hotspot* JIT compiler, which is made of 2 compilers:

* C1 emits simple native code, but which is still faster than executing bytecode in an interpreter, and
* C2 is a more aggressive compiler that generates better native code based on execution profiles, but it may frequently *de-optimize*, eating more memory as it generates code on the fly.

C2 is the compiler that gives performance, but it is and older, complex code base written in C++. Very few people on this planet have the ability to maintain it.

### Enter Graal

Written in Java, more extensible and easier to maintain, Graal works great as a C2 replacement.

My own experiments with using a JVM and Graal as a JIT compiler are that you can indeed achieve better performance. Others like Twitter have been publicly announcing better performance (and reduced costs) by using Graal instead of C2.

One issue that I have always had with running [Golo](https://golo-lang.org/) code on the JVM is that C2 never managed to get rid of primitive boxing. This is not the case with Graal as a JIT compiler as it has a better escape analysis.

## Summary

So… should you use a JVM + Graal, or should you use SubstrateVM?

### SubstrateVM

Pros:

* self-contained native executables
* fast process start
* smaller memory footprint
* smaller executable footprint

Cons:

* no JIT compiler, so lesser peak performance
* simple garbage-collector
* not all JVM code easily compiles, and when it does, you may still have surprises at runtime.

Best use-cases:

* command-line tools
* embedded / constrained devices *(note: ARM is not supported for SVM yet)*
* containerized environments where raw performance is not the main concern

### JVM + Graal JIT compiler

Pros:

* it’s still a regular JVM
* combine Graal with the best GC for your workload
* excellent peak performance.

Cons:

* traditional footprint of a JVM
* JVM startup times
* requires more iterations than C2 to reach peak performance, un-tiered compilation (e.g., Graal without C1) is slower until Graal kicks-in.

Best use-cases:

* services, networked services, micro-services,
* data processing applications where performance is critical
* alternative JVM languages.
