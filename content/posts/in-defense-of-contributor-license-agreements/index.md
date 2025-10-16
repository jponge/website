---
date: '2013-08-27'
title: 'In Defense of Contributor License Agreements'
readTime: true
toc: true
autonumber: true
aliases:
    - /blog/in-defense-of-contributor-license-agreements
---

The other day I stumbled upon a retweet on the anger of [Pierre Joye](https://twitter.com/PierreJoye) against contributor license agreements (CLAs):

{{< x user="PierreJoye" id="366067690714038272" >}}

It is not the first time that I saw complaints or suspicion against
CLAs. For as much as I hate all forms of bureaucracy, I feel that CLAs
are being mistaken by many fellow open source developers.

Here is my modest attempt at debunking some myths and clarifying a few
things. Thanks a lot Pierre for triggering this response that I had
promised you, although I understand we may only agree to disagree :-)

**Warning: I am not a lawyer.**

## TL;DR summary

Not everyone will go through this post, so here is in short my
opinionated view on CLAs:

> Requiring a contributor license agreement is a sign that you intend to
> sustain your project in the long run with responsible practices
> regarding intellectual property management. Responsible open source
> developers aren't afraid of signing contributor license agreements:
> they simply understand the legal implications of sharing source code
> with the rest of the world.

Now if you have a bit of time, here is why I believe that CLAs are a
good thing, although not every project actually needs it.

## But we have licenses, don't we?

Of course we have, but one shall not forget what a license is meant to
be.

Once upon a time, an individual, a group of individuals or a company
decides to publish its work as an open source project. Great I hear you
say, so [they pick up a license](http://choosealicense.com/) according
to how much freedom they want to give to the recipients of their work.

And this is where the story ends for licenses: they grant certain
permissions to whoever receives the source code. In particular, they
provide permissions to make derivative works. Sometimes they will also
permit re-licensing, or include patent protection clauses so that you
cannot both abide to the license terms and threaten to use patents
against copyright holders and recipients.

## What happens the other way around?

Interesting projects attract contributions. People and organizations
propose code changes to the original project maintainers.

It is implicitly and culturally implied that by doing so, one publishes
changes under the same conditions as the original license.

Well, it's not as simple as that. Lawyers dislike blurred lines (or
like, depending on what side of a case they are).

In most jurisdiction and by default, the contributor retains copyright
unless an explicit copyright transfer or license agreement has been
established between both parties. Upon contribution acceptance, the
resulting software published by the upstream project is now in reality a
joint-copyright effort.

This raises a few questions, including:

- What is the license governing the contribution?
- Who holds the contribution copyright? (employers may have a say)
- Was the contributor legally entitled to make the contribution?
- Did the contributor reuse third-party works? (potential harmful copy
  and paste...)
- (...)

Blurred lines, isn't it?

Licenses do not clarify much either on what happens when a contribution
knocks at a project door. A rare exception is section 5 of the [Apache
Software License v2](http://choosealicense.com/licenses/apache/) that
says:

> 5\. Submission of Contributions.\
> Unless You explicitly state otherwise, any Contribution intentionally
> submitted\
> for inclusion in the Work by You to the Licensor shall be under the
> terms and\
> conditions of this License, without any additional terms or
> conditions.\
> Notwithstanding the above, nothing herein shall supersede or modify
> the terms of\
> any separate license agreement you may have executed with Licensor
> regarding\
> such Contributions.

## But... we are good folks!

Sure!

Most software developers are well-rounded and honest individuals making
worthy contributions.

The lack of a CLA is not much on an issue for the vast majority of
projects, especially when using a permissive license such as the [Apache
Software License v2](http://choosealicense.com/licenses/apache/) or an
[MIT-style license](http://choosealicense.com/licenses/mit/).

A CLA is probably overkill if you are running a project as an individual
free of employer restrictions. Needless to say, it is probably a wise
choice even in these cases to use the [Apache Software License
v2](http://choosealicense.com/licenses/apache/) because the section 5
that we highlighted above is explicit on what happens by default when
someone proposes a contribution.

## Things can go bad

There are many case of long-lived open source projects for which the
lack of clear-cut handling of contributions revealed to be an issue.
Sometimes things go bad, and CLAs can be very useful tools in such
situations.

### Poisoned contributions

I once was chatting with a friend who is an Apache Software Foundation
member. Countless times, he received contribution proposals. While they
did what they were meant to do, they contained large portions of
copy'n'paste code that a simple web search could reveal.

Accepting contributions on sole technical merits is sometimes not
enough...

### License lock

A classic case that comes to my mind is the one of the [KDE Project
re-licensing effort](http://techbase.kde.org/Projects/KDE_Relicensing).
KDE is a long-lived effort that was originally released under the terms
of GNU GPL licenses version 2. Like many GPL'ed projects, the project
investigators opted for version 2 only of the licenses. The GNU licenses
have an option for code to be released under subsequent versions, too,
but given that you don't know what the next versions will be it is not a
bad choice to stick to what you know, especially when the Free Software
Foundation folks are in command.

When version 3 of the GNU licenses came out, KDE, like other
high-profile projects got interested in switching to the new licenses.
Now recall what I said above: by default contributors retain copyright,
and the availability of their contribution under the same license terms
is a convention.

The project license terms cannot be changed unless all contributors
agree. Some contributors may be hard to contact a few years later. Some
may sadly have died, too. Same problem with company contributions: they
may have been bought or have disappeared.

Conclusion: the lack of suitable provisions in the license combined with
no separate agreement means that the project is locked to a specific
version of the license that was initially chosen.

## So, what's in a CLA?

The Apache Software Foundation has an [individual contributor license
agreement](https://www.apache.org/licenses/icla.txt), which is very
popular. It serves as the basis for many other projects, including
Scala, Square projects, Twitter projects and many more.

The sections that I find especially interesting are the following ones.

> You accept and agree to the following terms and conditions for Your\
> present and future Contributions submitted to the Foundation. In\
> return, the Foundation shall not use Your Contributions in a way that\
> is contrary to the public benefit or inconsistent with its nonprofit\
> status and bylaws in effect at the time of the Contribution. Except\
> for the license granted herein to the Foundation and recipients of\
> software distributed by the Foundation, You reserve all right, title,\
> and interest in and to Your Contributions.

This clause is subject to adaptations outside the ASF, but it
nevertheless specificies that it is **not a copyright transfer**. The
contribution stays yours.

> Grant of Copyright License. Subject to the terms and conditions of\
> this Agreement, You hereby grant to the Foundation and to\
> recipients of software distributed by the Foundation a perpetual,\
> worldwide, non-exclusive, no-charge, royalty-free, irrevocable\
> copyright license to reproduce, prepare derivative works of,\
> publicly display, publicly perform, sublicense, and distribute Your\
> Contributions and such derivative works.

This is, I think, the first key point. Contributors explictly grant a
license to the upstream project maintainers to use contributions.
Sublicensing is important, too, as it opens licensing under new terms in
the future, even if the contributor is out of reach.

> Grant of Patent License. (...)

Good licenses already have a provision for that, but it is nevertheless
useful.

> You represent that you are legally entitled to grant the above
> license.\
> (...)\
> You represent that each of Your Contributions is Your original\
> creation (see section 7 for submissions on behalf of others). You\
> represent that Your Contribution submissions include complete\
> details of any third-party license or other restriction (including,\
> but not limited to, related patents and trademarks) of which you\
> are personally aware and which are associated with any part of Your\
> Contributions.

Second key point, this time against poisonous contributions.

> You are not expected to provide support for Your Contributions,\
> except to the extent You desire to provide support. You may provide\
> support for free, for a fee, or not at all. Unless required by\
> applicable law or agreed to in writing, You provide Your\
> Contributions on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS\
> OF ANY KIND, either express or implied, including, without\
> limitation, any warranties or conditions of TITLE, NON-\
> INFRINGEMENT, MERCHANTABILITY, or FITNESS FOR A PARTICULAR PURPOSE.

This may sound funny at first, but this clause just lifts support duties
from the contributor. In certain jurisdictions, you could have to
provide support for your work... even if it is opensource.

## Great, so do I really need a CLA?

By far, not every project needs a CLA and the small bureaucracy
overhead.

My advice is that you use a CLA for any project that meets these
conditions:

1.  you expect the project to be long-lived,
2.  you develop this project as part of your work,
3.  you expect contributions from third-party organizations.

Otherwise, use your gut feeling.

## A CLA in practice

It is not as hard as you think. It is probably a good idea to adapt [the
Apache ICLA](https://www.apache.org/licenses/icla.txt) (see [how Twitter
does](https://dev.twitter.com/opensource/cla) as an example).

Next, push the CLA on your project website, and ensure that every
contribution that you get is from someone who signed it.

It is a good practice to collect CLAs in the form of scanned documents
sent by email.

You may go purely online, too:

1.  some collect agreements through a simple web form (Google Doc is a
    fine choice),
2.  [CLAHub](http://www.clahub.com/) is a CLA management service that
    also checks for CLA on pull-requests.

## Conclusion

I hope to have demystified some myths on the usefulness of contributor
license agreements. While they are not practical for every project that
you may create, I believe that they shall not be overlooked either.

While an open source license gives permissions to project recipients, a
contributor license agreement clarifies the terms and scope of
contributions being made back to such project.

Contributor license agreements are usually not a sign of evilness from
the project maintainers. Evil maintainers with hidden agendas reveal
themselves in how they deal with a community, not by requiring you to
sign a CLA.

So next time you see a CLA: please be a responsible developer and look
beyond the code.

I do not hold the truth, if any, so feel free to comment below!

## Further readings

- [Licenses at the Apache Software
  Foundation](https://www.apache.org/licenses/)
- [Choose a License](http://choosealicense.com/), by GitHub
- [What is a CLA and why do I
  care?](http://www.clahub.com/pages/why_cla), on CLAHub
- [Should Open Source Communities Avoid Contributor
  Agreements?](http://blogs.computerworlduk.com/simon-says/2010/08/on-contributor-agreements/),
  by Simon Phipps
- [Why we chose the Apache
  License](http://www.opscode.com/blog/2009/08/11/why-we-chose-the-apache-license/),
  by OpsCode, with a discussion on CLAs.