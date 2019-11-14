---
title: "(draft) A good terminal experience with iTerm2 and ZSH on macOS"
layout: post
---

### iTerm2

I am working on macOS, and I prefer the [iTerm2](https://iterm2.com/) terminal emulator over the macOS _Terminal_ application:

![iTerm2 in Action](/images/posts/2019/iterm2.png)

I especially enjoy the ability to split panes horizontally and vertically, as well as the keyboard shortcuts to move around.

I use the minimal theme with the tab bar on top and the status bar in the bottom with a few helper icons like CPU usage and current process.
The color theme is [Dracula](https://draculatheme.com/).
I like this theme very much also in other tools, notably _Visual Studio Code_ which is my currently preferred editor aside from _IntelliJ IDEA_ for Java projects.
I also use the [Cascadia font from Microsoft](https://github.com/microsoft/cascadia-code).

### Dot files

Everyone has their preferences for managing dot files.

I am using a simple repository for that, with a bill-of-materials for applications to install automatically: [https://github.com/jponge/dotfiles/tree/2019](https://github.com/jponge/dotfiles/tree/2019) (the 2019 edition, switch to another branch if you want).

The dot files get sym-linked using [GNU Stow](https://www.gnu.org/software/stow/).
For instance `~/.zshrc` points to `~/dotfiles/home/.zshrc`.

There are various environment variables and shell functions that I rely on.
They can be found in `~/dotfiles/env`, and they get loaded from `~/.zshrc` (or `~/.bash_profile` if you prefer Bash) using a simple for-loop:

```bash
for envfile in ~/dotfiles/env/*.sh; do
  source ${envfile}
done
```

### Oh My Zsh

There exist several Zsh plugin managers, but if you want something with sensible defaults and batteries included then [Oh My Zsh](https://ohmyz.sh/) is a no-brainer.

Once you have it installed, you will like open `~/.zshrc` and start changing the configuration.
It is very likely that you will start with the theme 😉

I personally like the default `robbyrussell`, but you can also use a random theme and eventually find something you like better:

```bash
# (...)
ZSH_THEME="random"
# (...)
```

Next come the plugins, and this is all about the tools that you need to use on daily basis.
Check `~/.oh-my-zsh/plugins/` to see all the plugins that come with _Oh My Zsh_.

I personally have the following plugins in use, more on them in the next sections:

```bash
plugins=(
  git
  docker
  fzf
  httpie
  minikube
  zsh-syntax-highlighting
  zsh-autosuggestions
)
```

I'd recommend not having too many plugins in use.
You can often replace a plugin with loading a Zsh completion from the tool.

### fzf, a command-line fuzzy finder

You will have to install the tool for the corresponding _Oh My Zsh_ plugin to work, so go to [https://github.com/junegunn/fzf](https://github.com/junegunn/fzf).

This tool will help your for completions. A lot 😉

### Syntax highlighting

This external plugin provides syntax highlighting as you type shell commands, much like the [Fish shell](http://www.fishshell.com/) would do.
This is very useful, especially since you get instant feedback on non-existing commands, etc.

Head over to [https://github.com/zsh-users/zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting) for installation instructions, aka:

```bash
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git \
    ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
```

### Auto-suggestions

There is another useful plugin for having a Fish-like experience with completion suggestions based on past history.

Go to [https://github.com/zsh-users/zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions) for more details, or simply run:


```bash
git clone https://github.com/zsh-users/zsh-autosuggestions \
    ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
```

### Misc. useful command-line tools

There are a bunch of command-line tools that I use but that not everyone may know.

- [HTTPie](https://httpie.org/) is great for doing HTTP requests. It comes with syntax highlighting and sensible ways to pass form fields, JSON data, files, etc. It is much better that `cURL` in a development context.
- `pstree` to list processes as a parent-child tree. This is not installed by default on macOS.
- [bat](https://github.com/sharkdp/bat) is similar to `cat`, except it offers syntax highlighting (and other goodies).
- [watchexec](https://github.com/watchexec/watchexec) is a general-purpose tool to watch files and trigger a command in response to changes.
- [dive](https://github.com/wagoodman/dive) is a tool for exploring Docker images, and especially see what each layer brings to the filesystem.
- [foreman](https://github.com/ddollar/foreman) is a tool for running multiple processes. You just specify commands in a `Procfile`, and then start them all and check their logs. It is very useful in development when you need to start many processes.
- [hub](https://hub.github.com/) is the GitHub command-line tool for interacting with repositories. It is especially useful for checking out pull-requests.
- [plantuml](http://plantuml.com/) is a fantastic tool for generating all sorts of diagrams from... text.