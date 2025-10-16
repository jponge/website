---
date: '2016-03-11'
title: 'Developer Certificate of Origin Versus Contributor License Agreements'
readTime: true
toc: true
autonumber: true
aliases:
    - /blog/developer-certificate-of-origin-versus-contributor-license-agreements
---

[I am in favor of using _contributor license agreements (CLA)_]({{< relref "in-defense-of-contributor-license-agreements">}})
for opensource projects that are expected to be developed in the long run, especially when you develop them as part of your professional activities.

That being said, using a CLA is not always a _practical_ option as it adds a bit of bureaucracy.
Indeed, you will need to adapt a CLA [like the one from the Apache Software Foundation](https://www.apache.org/licenses/icla.txt), and you will have to make sure that people send it back to you before you can accept any contribution from them.

The Linux kernel does not use a CLA, but in 2004 the team introduced a [_developer certificate of origin (DCO)_](http://elinux.org/Developer_Certificate_Of_Origin). How does it compare to CLAs?

## What's in a DCO?

From [http://developercertificate.org/](http://developercertificate.org/):

    Developer Certificate of Origin
    Version 1.1

    Copyright (C) 2004, 2006 The Linux Foundation and its contributors.
    660 York Street, Suite 102,
    San Francisco, CA 94110 USA

    Everyone is permitted to copy and distribute verbatim copies of this
    license document, but changing it is not allowed.


    Developer's Certificate of Origin 1.1

    By making a contribution to this project, I certify that:

    (a) The contribution was created in whole or in part by me and I
    have the right to submit it under the open source license
    indicated in the file; or

    (b) The contribution is based upon previous work that, to the best
    of my knowledge, is covered under an appropriate open source
    license and I have the right under that license to submit that
    work with modifications, whether created in whole or in part
    by me, under the same open source license (unless I am
    permitted to submit under a different license), as indicated
    in the file; or

    (c) The contribution was provided directly to me by some other
    person who certified (a), (b) or (c) and I have not modified
    it.

    (d) I understand and agree that this project and the contribution
    are public and that a record of the contribution (including all
    personal information I submit with it, including my sign-off) is
    maintained indefinitely and may be redistributed consistent with
    this project or the open source license(s) involved.

The idea is pretty simple: you certify that you adhere to these requirements by _signing-off_ your commits (`git commit -s`), and it essentially means that:

1. you offer the changes under the same license agreement as the project, and
2. you have the right to do that,
3. you did not _steal_ somebody else's work.

This is a clearer than accepting commits from the random pull-request, and at least the person sharing the contribution engages on some IP cleanliness requirements.

Another bonus point for the DCO is that it is light on bureaucracy compared to a CLA: everything is bound to making signed-off commits with Git.

## What is missing compared to a CLA?

Looking at the [Eclipse CLA](https://eclipse.org/legal/CLA.php) and the [Apache CLA](https://www.apache.org/licenses/icla.txt), a first difference is that the DCO does not explicitly grant a license to the receiving entities.

Apache does it with clause 2:

    2. Grant of Copyright License. Subject to the terms and conditions of
    this Agreement, You hereby grant to the Foundation and to
    recipients of software distributed by the Foundation a perpetual,
    worldwide, non-exclusive, no-charge, royalty-free, irrevocable
    copyright license to reproduce, prepare derivative works of,
    publicly display, publicly perform, sublicense, and distribute Your
    Contributions and such derivative works.

and Eclipse has a mention in the preambule:

    This CLA, and the license(s) associated with the particular Eclipse Foundation
    projects You are contributing to, provides a license to Your Contributions to
    the Eclipse Foundation and downstream consumers, but You still own Your Contributions,
    and except for the licenses provided for in this CLA, You reserve all right, title and
    interest in Your Contributions.

The remainder of the Eclipse CLA is quite similar to the Linux DCO, and very short. My guess is that it mostly defers to the _Eclipse Public License_, especially for patent issues.

The Apache CLA is more lengthy than the one from Eclipse, and it adds a few more clauses, but in effect they are more or less redundant with what the _Apache Software License_ provides. Still, there is one clause that is interesting:

     6. You are not expected to provide support for Your Contributions,
     except to the extent You desire to provide support. You may provide
     support for free, for a fee, or not at all. Unless required by
     applicable law or agreed to in writing, You provide Your
     Contributions on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS
     OF ANY KIND, either express or implied, including, without
     limitation, any warranties or conditions of TITLE, NON-
     INFRINGEMENT, MERCHANTABILITY, or FITNESS FOR A PARTICULAR PURPOSE.

This lifts any requirement for supporting the contributions. This may come as a surprise, but in some countries this _could_ be the case that by default one has to support its work.

## A warning on trust

The DCO is very Git-centric, and it only relies on commit metadata. Indeed, signing-off a commit is just about appending a `Signed-off-by:` line in the commit comment as in:

    commit 0909d26f5de9e7e67fabcc94bab55f82fd33a1d3
    Author: Julien Ponge <julien.ponge@insa-lyon.fr>
    Date:   Tue Nov 17 10:29:19 2015 +0100

    Gradle sample rework

    * Switch to Gradle 2.8
    * Use the new plugins declaration section
    * Point to jCenter and Sonatype OSS snapshots (also switched to HTTPS)
    * Make the Java 8 source requirement explicit
    * The Java 8 Gradle check has been moved to settings.gradle to reduce clutter
    * The application plugin is being used to run the application from Gradle
    * The application code has been made verbose to know if the listen() operation succeeded or not.

    Signed-off-by: Julien Ponge <julien.ponge@insa-lyon.fr>

It is very easy to use _whatever_ email address you want for a commit, and the sign-off is just text.

## Should you use a DCO?

In many respects, the Linux DCO is a valuable alternative to using a CLA, and it is certainly better than having no such mechanism at all for receiving contributions.

Still, the issue of trust is important. What can be done to mitigate that is using GnuPG signatures in Git commits:

* `git commit -s -S` makes GnuPG-signed commits, and
* `git log --show-signature` shows GnuPG signatures in the log history, and
* `git merge --verify-signatures branch` ensures that all commits are signed _and_ valid before performing a merge.

Now having to use GnuPG for _all_ commits can be a bit daunting. Perhaps a simple alternative can be to require that contributors add their name and email to a file (e.g., `CONTRIBUTORS`), and do so with a GnuPG + signed-off commit, and later at least sign-off commits. This is especially doable with services like [keybase.io](https://keybase.io/) that can link several public profiles to a key, and especially GitHub (although yes, GitHub shall not be the center of the universe in opensource!).

I think many variants can work out here, the most important thing is to have GnuPG in the loop at some point.
