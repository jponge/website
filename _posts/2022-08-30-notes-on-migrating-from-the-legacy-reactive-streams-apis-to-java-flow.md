---
title: "Notes on migrating from the legacy Reactive Streams APIs to Java Flow"
layout: post
---

The Java [Reactive Streams](https://www.reactive-streams.org/) APIs have been part of the JDK since Java 9.

It is about time for the modern Java ecosystem to migrate away from the legacy APIs (`org.reactivestreams:reactive-streams` Maven coordinates) and adopt the interfaces in [`java.util.concurrent.Flow`](https://docs.oracle.com/javase/9/docs/api/java/util/concurrent/Flow.html).

I have recently started migrating the [Mutiny](https://smallrye.io/smallrye-mutiny/) and [Mutiny Zero](https://smallrye.io/smallrye-mutiny-zero/) libraries and thought these notes would be useful to others as well.

### Migration of isomorphic APIs

The good news is that the legacy and the `Flow` APIs are isomorphic.
For instance `org.reactivestreams.Publisher<T>` becomes `java.util.concurrent.Flow.Publisher<T>`.

One option is to perform string replacements to move from one API to the other, but an IDE like IntelliJ can help you with API migrations (see `Refactor > Migrate Packages and Classes`):

![IntelliJ type migration map](/images/posts/2022/intellij-type-migration-flow.png)

### Transition period

The bad news is that moving from one API to the other _could_ be a breaking change for your own code bases.

If your code relies on a high-level implementation of _Reactive Streams_ then the change will be mostly transparent at the source code level.
For instance the [Hibernate Reactive](https://hibernate.org/reactive/) library uses Mutiny and none of the low-level _Reactive Streams_ types such as `Publisher`, hence the migration of Mutiny to the JDK `Flow` APIs requires no change in Hibernate Reactive.

By contrast [RESTEasy Reactive](https://quarkus.io/guides/resteasy-reactive) does support exposing endpoints using `org.reactivestreams.Publisher<T>` return types (and not just, say, `Multi<T>` from Mutiny), so the migration requires more work than just bumping a dependency version.

1. In many cases one can simply perform an API migration.
2. In some cases such as that of _RESTEasy Reactive_ there needs to be a transition period where both the legacy and `Flow` types will be supported.
3. In some other cases such as using a library with a dependency to the legacy APIs, type adaptation will need to be made.

### Flow / Legacy type adapters

The [`reactive-streams-jvm` project](https://github.com/reactive-streams/reactive-streams-jvm/) contains [adapters](https://github.com/reactive-streams/reactive-streams-jvm/blob/master/api/src/main/java9/org/reactivestreams/FlowAdapters.java) to go back and forth from legacy types to `Flow` types.

You might as well use the [adapters that I developed and maintain as part of Mutiny Zero](https://smallrye.io/smallrye-mutiny-zero/0.4.3/flow-adapters/).

Suppose that you have a library that has yet to migrate to `Flow` APIs.
You can easily turn a `Publisher<T>` into a `Flow.Publisher<T>`:

```java
Publisher<String> rsPublisher = connect("foo"); // ... where 'connect' returns a Publisher<String>

Flow.Publisher<String> flowPublisher = AdaptersToFlow.publisher(rsPublisher);
```

Type adapters exist for the 4 interfaces of _Reactive Streams_, and they have virtually no cost.

### Passing the Reactive Streams TCK

While the _Reactive Streams_ APIs are fairly simple, the evil is in the protocol and semantics.
This is why publishers, processors and subscribers need to pass the _Reactive Streams TCK_.

[There is fortunately a `Flow` variant of the TCK](https://github.com/reactive-streams/reactive-streams-jvm/tree/master/tck-flow), so if you have implemented _Reactive Streams_ the changes will be minimal as you transition to `Flow`.

First, the TCK dependency Maven coordinates will become `org.reactivestreams:reactive-streams-tck-flow`.

Next, you will need to move your test classes from `org.reactivestreams.tck.PublisherVerification<T>` as a base class to `org.reactivestreams.tck.flow.FlowPublisherVerification<T>`.

The rest of your TCK test code will be the same, except that some method names have `Flow` in them: `createPublisher(long)` becomes `createFlowPublisher(long)`, etc.
You can see that in [one of the test cases from Mutiny Zero](https://github.com/smallrye/smallrye-mutiny-zero/blob/f795f242e5d88f0a44fb3838da1fcc0f6da49c68/mutiny-zero/src/test/java/mutiny/zero/tck/CompletionStageTckPublisherTest.java).

### Conclusion

Migrating to the JDK `Flow` APIs is important for the modern Java ecosystem, especially as _Reactive Streams_ APIs have been part of the JDK since Java 9.

The migration is fairly transparent for application developers as they are unlikely to be directly using the low-level _Reactive Streams_ types.
This is instead the duty of frameworks, libraries and drivers to do this transition and impose one less dependency in application stacks.

The migration in itself isn't too hard to perform as types are isomorphic, but there is an inevitable transition period for stacks where multiple dependencies need to be aligned past Java 8 and on top of the JDK `Flow` APIs.
Type adapters represent a virtually no-cost solution when alignment is not possible yet.

The most important part for _Reactive Streams_ implementers remains its TCK as the guardian of interoperability between various libraries.
As the TCK already ships with a `Flow` variant, migrating away from the legacy APIs won't break the behavior and interoperability of _Reactive Streams_ implementations.
