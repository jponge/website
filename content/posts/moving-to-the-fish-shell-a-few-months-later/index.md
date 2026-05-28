---
date: '2026-05-28T16:32:13+02:00'
title: 'Moving to the Fish Shell: a Few Months Later'
readTime: true
toc: false
autonumber: false
---

[I previously shared my experience in moving to the Fish shell]({{< relref "posts/moving-from-zsh-to-the-fish-shell-is-easy/index.md"  >}}) during the last quarter of 2025.

I thought I would share a quick update after a few months going all-in on Fish, and expose the small adjustments that were made.

## Overall experience

[Fish](https://fishshell.com) is a truly productive shell.
Everything feels smooth and fast.

The completions are always spot-on.
A good example is when I need to make a `git push` but I never remember if `origin` is the upstream or my fork.
I just start typing `git push <TAB>` and I instantly get a very clear hint on what are the Git origins, and what repository they point to.
Neat!

## Tide prompt

[Tide](https://github.com/IlanCosman/tide) is still my prompt tool.

It is quite easy to configure to get a productive yet not overwhelming appearance.
It also supports Fish asynchronous operations, so a slow `git` information query will not prevent you from typing in the shell.
The information is updated when it gets available.

## Dropping SDKMAN and switching to Mise

I initially stayed on SDKMAN to configure my Java runtimes and tools (Maven, Gradle, JBang, and some others).

Now SDKMAN doesn't work with Fish as it is essentially a set of Bash-compatible scripts, so I had to use [a plugin that bridged SDKMAN using side effects](https://github.com/reitzig/sdkman-for-fish).
It somehow did the job but I encountered too many bugs and ergonomic issues.

I went with the [increasingly popular Mise tool](https://mise.jdx.dev).
It works like a charm, it is well maintained, and it works across other ecosystems (Go, Python, JavaScript, etc).

Bonus point: when you install `mise` from `brew`, there is no special configuration to do.
Fish picks it up automatically.

## Fish as a system-wide default shell?

I had advised to set Fish a s default shell.

Some people complain that this is a bad idea since Fish is not a "Posix" shell.
I never ran into any issue by doing so, especially as any sane Unix script always has a _shebang_ to specify what interpreter to use (`sh`, `bash`, `zsh`, `fish` or even `python` / `ruby`, etc).

Now I have a work laptop where some system-wide environment variables are set by non-Fish shells, so I thought I'd switch back to the default `zsh` login shell on macOS, and set `fish` as the default shell in my daily terminals ([Ghostty](https://ghostty.org/), VSCode and IntelliJ).

This brings a little more safety, but again if you fully control your operating system then I don't think you will ever get any problem by using Fish as a default, system-wide shell.

## Misc

I found the [`z` plugin](https://github.com/jethrokuan/z) to be very useful to quickly jump between directories.

This is however clearly a _"nice to have"_ plugin.
