---
date: '2022-03-09'
title: 'A Workflow for Experiments in Git: Scratchpad Branches'
readTime: true
autonumber: true
---

Git is a fantastic tool to manage source code.
Switching branches is especially easy (if you are a CVS / Subversion veteran you know what I mean).

My workflow to implement features is not very surprising:

1. I spawn a new branch from the `main` branch,
2. I prepare changes in one or a few commits,
3. I open a pull-request and ask for peer-review,
4. (goto 1)

Still, there are times when I need to explore various designs, and doing so takes several days or even weeks.
In such cases I would use a mix of:

- `git stash` to discard failed attempts but still be able to go back to them, and
- `git rebase` to synchronize with the latest progress in the `main` branch, and
- `git rebase -i HEAD~N` (e.g., with `N = 3` if I have 2 commits) to squash changes and reduce intermediate draft commits to one.

I've recently shifted to a new workflow that allows me to make exploratory branches, keep track of all intermediate steps, and finally offer a clean pull-request when ready.

1. I spawn a new branch from the `main` branch, and I prefix it with `scratchpad/` to signal the intent: `git switch -c scratchpad/yolo`
2. I make commits as I need them (the code might even be broken!), sometimes being informative, sometimes just having `WIP` as a comment: `git commit -am 'WIP'`, `git commit -am 'Adding docs'`, etc
3. I can move to another `scratchpad/` branch any time I need to explore another design by going back to step 1
4. I frequently rebase on top of `main` to capture any future conflict: `git rebase origin/main`
5. I push these branches to my fork of the repository that I am working on (unless it's a purely solo project), so I have a backup somewhere and I can share experiments no matter if the code works or not: `git push myfork scratchpad/yolo --set-upstream`
6. Once I have a branch that works, I can derive a clean branch and assemble a pull-request.

Deriving a clean branch is easy with a _soft reset_:

```
git switch scratchpad/yolo
git switch -c feature/yolo
git reset --soft origin/main
git commit -a
```

Starting from here the `feature/yolo` branch has a clean commit with the whole feature, while the `scratchpad/yolo` branch remains visible somewhere with all the steps.
