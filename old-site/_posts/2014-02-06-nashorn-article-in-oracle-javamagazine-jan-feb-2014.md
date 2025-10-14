---
title: "Nashorn Article in Oracle Java Magazine Jan/Feb 2014"
layout: post
---

> **Update March 7th 2014:** the article is now also [available without registration on the Oracle Technology Network](http://www.oracle.com/technetwork/articles/java/jf14-nashorn-2126515.html).

> **Update March 11th 2014:** the article is now also [available on JaxEnter](http://jaxenter.com/oracle-nashorn-a-next-generation-javascript-engine-for-the-jvm.1-49712.html) (best format and source code indentation).

[My latest article for Oracle Java Magazine](http://www.oraclejavamagazine-digital.com/javamagazine_open/20140102#pg60) has been published in the January/February 2014 edition:

[![Article preview](/images/posts/2014/nashorn-javamag.png)](http://www.oraclejavamagazine-digital.com/javamagazine_open/20140102#pg60)

This article presents [Oracle Nashorn](http://openjdk.java.net/projects/nashorn/), a next-generation
JavaScript engine for the JVM that replaces Mozilla Rhino in Java 8 Oracle-built JDK releases.

The article puts a strong emphasis on the 2-ways Java interoperability so that JavaScript and Java
code can be mixed and matched in polyglot applications.

Nashorn also serves as a showcase for the JDK team working on `invokedynamic`, as the implementation
of this language runtime on the JVM poses quite a few challenges. In this regard, I highly recommend
the Devoxx 2013 talk by Atilla Szegedi:
["The Curious Case of JavaScript on the JVM"](http://parleys.com/play/5290a8f9e4b054cd7d2ef4c2/about).

Making an ECMA-compliant engine for JavaScript is one thing, making it fast is another story.

Finally, you may also look at [DynJS](http://dynjs.org/). It is an independent project that also
leverages `invokedynamic` to provide a modern JavaScript engine for the JVM. I haven't tested it
much but it seems like a worthy project!
