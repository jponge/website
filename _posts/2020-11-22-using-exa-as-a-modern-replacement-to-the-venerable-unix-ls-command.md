---
title: "Using exa as a modern replacement to the venerable Unix ls command"
layout: post
---

# Using exa as a modern replacement to the venerable Unix ls command

So you know `ls` (often found as `/bin/ls`), the good old Unix command to list files in a directory.

I recently came across [exa](https://the.exa.website), a modern replacement for `ls`. It is part of a wave of new command-line tools written in [Rust](https://www.rust-lang.org) and that bring modernity while staying faithful to the Unix way of writing focused and composable tools.

Of course you may wonder *why* switching from `ls` is any good idea. It turns out that `exa` is really a better `ls`, with good colour support, customisable output, a humane interface and even `git` metadata support (so you can see which files are being ignored, staged, etc).

### A quick tour of exa

The default behavior of `exa` is to... list files, pretty much like `ls` would do:

![exa](/images/posts/2020/exa/1.png)

The equivalent of `ls -la` is `exa --long --all`:

![exa](/images/posts/2020/exa/2.png)

Note that by default file sizes are given in a human-friendly form.

If you are in a Git repository you can also get metadata  by adding the `--git` flag to any command:

![exa](/images/posts/2020/exa/3.png)

Note that reading Git metadata can slow down the execution of `exa` commands, so I personally tend to use the `--git` flag only when I actually need it.

You can also inspect trees with the `--tree` flag:

![exa](/images/posts/2020/exa/4.png)

There is also a `--recurse` flag to list files in each directory of the file tree:

![exa](/images/posts/2020/exa/5.png)

### My personal aliases

Typing `exa` instead of `ls` is one more character, and you'll likely have to fight muscle memory. In my case I am trying to get rid of typing `ls -lsa` 😉

You can easily define a few aliases so `exa` becomes your new `ls`. Note that `exa` is not fully compatible with `ls`. For instance `ls -lsa` (which I am fighting) results in an error with `exa -lsa` because the `-s` flag requires an argument to define a sort field.

Here are my personal aliases:

```bash
# A few aliases for exa, a ls replacement
alias l="exa --sort Name"
alias ll="exa --sort Name --long"
alias la="exa --sort Name --long --all"
alias lr="exa --sort Name --long --recurse"
alias lra="exa --sort Name --long --recurse --all"
alias lt="exa --sort Name --long --tree"
alias lta="exa --sort Name --long --tree --all"

alias ls="exa --sort Name"
```

Feel-free to take inspiration and define aliases and default flags that make sense to **you**!