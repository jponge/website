---
title: "The power of conventional commits"
layout: post
---

I had been randomly exposed to [conventional commits](https://www.conventionalcommits.org/) as part of my opensource activities, not really paying attention to this _weird_ form of commit messages.
It is only in the recent months that I have taken a serious look at them and realised how they were **much better commits**.

Here is why I think you should pay notice, too! 😃

## How much of a commit is a commit?

This is a classic problem in software engineering: you create a branch, you make some changes, and then you create a Git commit.
In theory your commit is self-contained: it is a documentation update, or it is a bug fix, or it is a new feature, etc.

Disciplined and self-contained commits are great because the Git history becomes very readable.
It is also very easy to selectively drop a commit if something goes wrong (`git revert`) or port a given change to another (maintenance) branch (`git cherry-pick`).

Of course theory and practice tend to disagree, especially as we work under time-sensitive constraints, so we often end up with commits that mix several changes in one, or branches with series of commits that should really be just one.

Another problem is that of writing _proper_ Git commits.
After all, [a Git commit message is loosely defined](https://git-scm.com/docs/git-commit) with the first line being a title / summary of the changes, and the longer body providing more details, as in:

```
Fixes a race condition in the concatMap operator

Fixes concurrent signals handling leading to an inconsistent state,
especially with the termination signals of the inner and outer
subscribers.

Fixes: #666
QA-Approver: MrBean
```

So how are [conventional commits](https://www.conventionalcommits.org/) any better than this?

## From human-readable to human & machine-readable

The previous Git commit message was relatively well-structured:
- the first line had a precise and concise summary, and
- the next paragraph provided some insights on the changes being made, and
- the footers provided key / value pairs that a tool could use to extract metadata: the bug being fixed, and who performed the quality assurance checks.

[Conventional commits](https://www.conventionalcommits.org/) are nothing but taking this approach a step further by adding a structure to commit messages.
Back to this example, this would give the following commit:

```
fix(operators): race condition in the concatMap operator

Fixes concurrent signals handling leading to an inconsistent state,
especially with the termination signals of the inner and outer
subscribers.

Issue: #666
QA-Approver: MrBean
```

While this might look like a cosmetic change, this message has more structure!

- `fix` means that the change is a bug-fix. Other common types can be `feat` (feature), `docs` (documentation updates), `refactor` (refactoring), etc. In fact, you can create your own conventions around it, although the [Angular conventions](https://github.com/angular/angular/blob/22b96b9/CONTRIBUTING.md#-commit-message-guidelines) are both widely accepted and fairly complete.
- The `operators` scope gives more context: the fix applies to some _"operators"_ area of the code base. Scoping is optional, though.
- The rest of the first line gives a quick summary.
- The body provides details, as before.
- The footers can be used to reference issues, pull-requests, specifications, process sign-offs... actually anything that would make sense for a tool to extract as a commit metadata.

The structure of a *conventional commit* message is as simple as:

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

Note that the same ideas can be found in other approaches such as [GitMoji](https://gitmoji.dev/).
Sure, emojis are fun to have in commits, but I personally find it easier to decipher that a commit is a bug fix when it starts with `fix:` rather than `🐛` (but my friend Philippe probably thinks otherwise 😇).

## Benefit #1 - Automatic release changelogs

[Conventional commits](https://www.conventionalcommits.org/) can be parsed by tools, and a very nice use-case is that of generating release changelogs.

Here is a screenshot of what it looks like for the release of [Mutiny 2.5.6](https://github.com/smallrye/smallrye-mutiny/releases/tag/2.5.6):

![Changelog of the release of Mutiny 2.5.6](/images/posts/2024/jreleaser-sample-changelog.png)

I introduced [JReleaser](https://jreleaser.org/) as part of the Mutiny release process when I made the project adopt conventional commits.
The tool is able to group commits by kind (e.g., features, documentation updates, bug fixes, etc).
It also provides a summary of the merged-pull requests, provided not just the pointers to such pull requests but also those of the fixed issues.

## Benefit #2 - No excuse for not doing semantic versioning

Shall your next version be 2.6.0 or 2.5.6?

If you are maintaining a library then sticking to [semantic versioning](https://semver.org/) should be a no-brainer.
- Have you made breaking changes? Bump to 3.0.0.
- Have you added new features while keeping backward compatibility? Bump to 2.6.0.
- Have you _"only"_ done bug fixes, documentation updates, non-user facing API internal changes? Bump to 2.5.6.

This is, again, another good example where the theory is nice but practice slips 🤣
This can be due to the marketing value of a version number, or just due to the fact that you have a bunch of changes and the last release was 3 months ago so you decide to raise the minor version number.

We have all done that, but as library consumers it is quite easy to see how rigorous semantic versioning helps.

Conventional commits make it quite easy to decide what the next release number shall be.
I know that some projects leave it completely to release scripts to decide on the version number by inspecting commits.
I personally prefer to inspect the Git history and have the last word:

```
$ git log --oneline --no-merges
b9c3b93e build(deps): bump codecov/codecov-action from 3.1.4 to 3.1.5
2ec49880 chore(release): set development version to 999-SNAPSHOT
bc3ba4fd (tag: 2.5.6) chore(release): release Mutiny 2.5.6
f18296bb (origin/fix/concatmap-early-null-innerUpstream) fix(concatMap): deadlock on inner upstream subscription
796003cc fix(concatMap): check for early null inner subscriber
32fdd3e3 build(deps): bump org.assertj:assertj-core from 3.25.1 to 3.25.2
9dc8bdcd chore(release): set development version to 999-SNAPSHOT
a5fca500 (tag: 2.5.5) chore(release): release Mutiny 2.5.5
be54f155 (origin/fix/1494) fix: race condition on cancellation in UniCallbackSubscriber
4811b4b4 (origin/refactor/concatmap-no-cas-on-unbounded) refactor: avoid a compare&swap on unbounded requests
b8da91f3 chore(release): clear RevAPI breaking change justifications
c26a308f chore(release): set development version to 999-SNAPSHOT
```

In this short excerpt you can see that the last commits between tags did not have features (`feat: xyz`), hence hinting at patch releases.
I have to admit that before adopting conventional commits I could have arbitrarily done minor rather than patch releases.

The practice of conventional commits might also help me in deciding to delay the merge of a given pull-request.
If I have bug fixes and new features in the pipe then I might first have a quick patch release, then merge the new features to plan a new minor (or even major) release.

In fact I believe library maintainers shall not be afraid to frequently bump the major release number.
If your web browser is at version 121 then why don't you let your library be at version 12 if you can't avoid breaking changes, even low-impact ones?
At least downstream consumers of your library will be aware that you take versionning seriously.

## Benefit #3 - Hack freely and make sense of your changes later

This might sound counter-intuitive, but conventional commits can be liberating!
How is that possible, since each commit should be nicely self-contained?

The trick is that because you know that you _eventually_ need to expose conventional commits in your pull-requests, you will not be tempted to make half-backed commits.

There are various ways to achieve this, but I suggest you have a look at [my previous blog on scratchpad branch workflows]({% post_url 2022-03-09-a-workflow-for-experiments-in-git-scratchpad-branches %}).
The idea is pretty simple:
- you start making changes in dirty branches where you can commit as often as you want, and use any message as you want, then
- you eventually extract clean branches with nice, self-contained commits, and while I did not know at the time, conventional commits are a perfect fit to such a workflow!

## Bonus #1 - How to check pull requests?

If your project is hosted on GitHub and uses GitHub Action, then it is quite easy to check that a pull-request meets conventional commits.

There are several options that I had tested, but the one that worked better is [wagoid/commitlint-github-action](https://github.com/wagoid/commitlint-github-action).

You can have a simple job in your workflow that looks like this, and it will by default use the Angular conventions:

```yaml
conventional-commits:
runs-on: ubuntu-latest
name: Check conventional commits
steps:
    - uses: actions/checkout@v4
    - uses: wagoid/commitlint-github-action@v5
```

Some people use local Git hooks to make sure that people do not commit wrong commits in the first place, but this is too much for me.

## Bonus #2 - Dependabot and conventional commits

This again applies to projects hosted on GitHub.
If you are using [dependabot](https://docs.github.com/en/code-security/dependabot) to help you keeping dependencies up-to-date, then you need to configure it so it makes conventional commits.

Simply edit your `.github/dependabot.yml` file to look like:

```yaml
version: 2
updates:
- package-ecosystem: maven
  directory: "/"
  schedule:
    interval: daily
  commit-message:
    prefix: "build"
    include: "scope"
  open-pull-requests-limit: 10
- package-ecosystem: github-actions
  directory: "/"
  schedule:
    interval: weekly
  commit-message:
    prefix: "build"
    include: "scope"
```

The relevant part is in the `commit-message` object, which gives you commits of the form:

```
build(deps): bump org.assertj:assertj-core from 3.25.1 to 3.25.2
```

The only minor glitch and well-known issue is that dependabot will make description lines that can be too long for the linter to pass.
In my case I regularly have dependabot pull-requests that fail the `wagoid/commitlint-github-action` checks just because it makes for long lines.
This easily happens with long Maven coordinates.

There are two options:
1. just ignore this and proceed with a merge as long as other checks are green, knowing that many tools such as [JReleaser](https://jreleaser.org/) do not care about the length of description lines, or
2. edit the `wagoid/commitlint-github-action` configuration with relaxed custom rules (_I will leave this as an exercice to the astute reader as we said in my past professional life_ 😄).

## Conclusion

I hope that this blog post will have motivated you to explore [conventional commits](https://www.conventionalcommits.org/).
I don't use them in all of my projects, but I found them to be useful in the important ones that I maintain, with [Mutiny](https://smallrye.io/smallrye-mutiny/latest/) being a good showcase as it is a critical component of larger projects such as [Quarkus](https://quarkus.io/).

At first conventional commits look a bit weird and you will repeatedly wonder what is the format as you make commits.
Still, they will quickly become a second nature and you will realise the benefits in terms to your software engineering processes.

At the very least they will be a useful companion when it comes to planning, crafting and performing releases.
And perhaps you will _finally_ have that clean Git history, just like in the textbooks 🎉
