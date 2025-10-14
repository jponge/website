---
title: "Avoiding Benchmarking Pitfalls on the JVM in Oracle Java Magazine Jul/Aug 2014"
layout: post
---

![Oracle Java Magazine](/images/posts/2014/jmh-javamag.png)

My latest article for Oracle Java Magazine is called ["Avoiding Benchmarking Pitfalls on the JVM"](http://www.oraclejavamagazine-digital.com/javamagazine/july_august_2014?#pg42) *(reading the article requires a free subscription)*.

Benchmarking programs on a speculative virtual machine is surprisingly hard, as I found out while implementing the [Golo programming language](http://golo-lang.org/).

The article first discusses a naive approach to benchmarking. This is probably what you have been doing in your own experiments, and I show you why it is wrong in general. The article then switches to [JMH](http://openjdk.java.net/projects/code-tools/jmh/), an OpenJDK tool project that provides a harness for writing correct benchmarks.

While JMH in itself is not magic, some basic understanding of what the JVM does and how JMH provides safety nets will help you write more meaningful benchmarks.

**Note:** some annotation APIs have changed in JMH since the article was written, but the impact on the article comprehension is neglectible.

