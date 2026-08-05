---
date: '2026-08-05T18:29:32+02:00'
title: 'Fish abbr Tip: Put the Cursor Exactly Where You Need It'
readTime: true
toc: true
autonumber: true
---

One of my favorite features in the [fish shell](https://fishshell.com/) is the ability to define _abbreviations_ using the [`abbr` command](https://fishshell.com/docs/current/cmds/abbr.html).

Here's a quick note about `abbr`, and how to set the cursor to the right position without breaking your flow.

## The problem

As a [Quarkus](https://quarkus.io) core team contributor, I frequently need to rebuild extensions and run integration tests.
These require some boilerplate Maven commands, such as:

```shell
./mvnw -Dno-build-cache -Dstart-containers -Dtest-containers -Pnative clean install -f integration-tests/resteasy-jackson/
```

or:

```shell
./mvnw -Dno-build-cache -Dstart-containers -Dtest-containers clean install -f extensions/vertx-http/
```

## First attempt

In most cases `abbr` behaves like an alias in other shells, with the difference being that the abbreviation is expanded to its content.
So I initially went with something like this:

```shell
abbr -a -- qbex './mvnw -Dno-build-cache -Dstart-containers -Dtest-containers clean install -f extensions/'
abbr -a -- qbit './mvnw -Dno-build-cache -Dstart-containers -Dtest-containers -Pnative clean install -f integration-tests/'
```

This defined `qbex` (to build a Quarkus extension) and `qbit` (to build a Quarkus integration test).

The problem was that when I typed, say, `qbit` + <kbd>Tab</kbd>, the expansion of `qbit` was followed by a _space_ character.
So to run the `resteasy-jackson` integration test, I had to type:

`qbit` + <kbd>Tab</kbd> + <kbd>Backspace</kbd> + `resteasy-jackson` + <kbd>Enter</kbd>

This is not a fluid experience.

## Second attempt

The `--set-cursor` flag of the `abbr` command can be used to move the cursor after expansion:

```shell
abbr -a --set-cursor=^ -- qbex './mvnw -Dno-build-cache -Dstart-containers -Dtest-containers clean install -f extensions/^'
abbr -a --set-cursor=^ -- qbit './mvnw -Dno-build-cache -Dstart-containers -Dtest-containers -Pnative clean install -f integration-tests/^'
```

With this, `qbit` + <kbd>Tab</kbd> places the cursor right where it should be, and I can even benefit from shell completion right away to select the target.