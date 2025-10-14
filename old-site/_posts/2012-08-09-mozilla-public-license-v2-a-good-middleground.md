---
title: "The Mozilla Public License Version 2.0: A Good Middle Ground?"
layout: post
---

The release of the [Mozilla Public License Version 2.0](http://www.mozilla.org/MPL/2.0/) probably flew under the radar [when it happened in January 2012](https://mpl.mozilla.org/2012/01/03/announcing-mpl-2-0/).

In fairness, the initial Mozilla Public License (MPL) was admittedly not much used outside of the Mozilla world. Mozilla-branded software source code have traditionally been released under a tri-license comprising the [GNU GPL](http://www.gnu.org/copyleft/gpl.html), the GNU LGPL and the MPL itself. Some Mozilla extensions and derivatives decided to follow the same path, but the reality is that the MPL never really spread outside of its originating community ([Adobe publishing significant parts of Flex under the MPL](http://www.adobe.com/products/eula/flex/flex3sdk.html) is a rare counter-example). This is in sharp contrast to, say, the Apache License or the Eclipse Public License.

## Spirit of the MPL

In essence, the MPL was designed as a "middle-ground" license sitting between the extremes of restrictive licenses like the GNU (A)GPL and liberal licenses such as the [Apache](http://www.apache.org/licenses/LICENSE-2.0) / [BSD](http://opensource.org/licenses/bsd-license.php/) / [MIT](http://opensource.org/licenses/mit-license.php/). While the MPL license itself allows derivative works to be released under *any* license, including a proprietary one, it still requires a form of [copyleft](http://www.gnu.org/copyleft/) at the file level. This consequently puts the MPL in the same bucket as the [Eclipse Public License](http://www.eclipse.org/legal/epl-v10.html) and the [GNU LGPL](http://www.gnu.org/licenses/lgpl.html).

In practice, you may take some MPL code and use it as part of your proprietary software. However, you must give access in source form to the MPL-covered parts, and any modification of a piece of MPL-covered code from your side must also be published as MPL-covered code. **This is just simple copyleft, really.**

The fact that most Mozilla-branded software have been historically released under a tri MPL/GPL/LGPL license is for increased compatibility with third-party libraries, especially those published under the terms of a GNU license. The versions 1.x of the MPL were not (L)GPL-compliant.

## A simpler, reusable and pragmatic software license?

A weak copyleft license certainly has some merits, especially when the said license applies at the file level, was written in the open by both opensource advocates and lawyers, and... is free of any political message which you may not necessarily adhere to (*yes, I am looking at you Richard*).

That being said, the MPL in its original form was not necessarily easy to apply to non-Mozilla projects, so much that derivatives of the MPL were written such as the [CDDL by (late) Sun Microsystems](http://opensource.org/licenses/cddl-1.0).

The latest installment of the MPL looks much more appealing outside of the Mozilla world. Quoting the [announcement blog post](https://mpl.mozilla.org/2012/01/03/announcing-mpl-2-0/):

> The result of a two year revision process that included feedback and suggestions from the Mozilla community, users of the MPL (both community and corporate), and the broader open source legal community, MPL 2.0 contains several important changes from MPL 1.1. In particular, MPL 2.0:
>
> * is simpler and shorter, using the past 10 years of in-practice application of the license to help better understand what is and isn’t necessary in an open source license.
> * is modernized for recent changes in copyright law, and incorporates feedback from lawyers outside the United States on issues of applicability in non-US jurisdictions.
> * provides patent protections for contributors more in line with those of other open source licenses, and allows an entire community of contributors to protect any contributor if they are sued.
> * provides compatibility with the Apache and GPL licenses, making code reuse and redistribution easier.

The explicit compatibility with the GNU and Apache licenses is also an added benefit, especially as it does not involve a complex multi-licenses scheme like it was the case with the old MPL. I recommend reading what [Simon Phipps had to say in his "Can Mozilla Unify Open Source?" column for Computer World](http://blogs.computerworlduk.com/simon-says/2012/01/can-mozilla-unify-open-source/index.htm):

> Other coverage of the new license has focussed on the modified patent-peace and other adjusted terms (goodbye, Netscape!) but the most important development in the creation of version 2 of the Mozilla license in my opinion is the inclusion of specific compatibility with the GNU General Public License (GPL). Previously, the Mozilla project used a complex and messy triple license arrangement to allow it to straddle the worlds of copyleft and non-copyleft licensing. Other users of the MPL (and its many vanity-named clones) tended not to bother, with the result that some code-bases were isolated from collaboration with the great universe of GPL-licensed software.

## You should consider using it!

I can say that I am certainly going to consider the MPL v2.0 for future software publications.

I am clearly not a proponent of the strong copyleft GNU licenses (GPL and AGPL): they are way too restrictive and they carry a political message which should not be part of a license text if you ask me. That being said those licenses can be very useful in certain contexts, especially when a business model needs to be put in place to sustain the development of a project.

While the *lax* BSD / MIT / Apache licenses generally have my preference, I sometime feel that they may be giving away too much to the "free loaders" who never give anything back to the upstream projects. Open source is now widespread unlike it was the case 10 years ago, and I have witnessed first-hand a change in the way people "consume" open source projects. I don't want to sound like an old fart, but people participate less in the projects than back in the days.

**The MPL v2.0 form of copyleft may be an appealing incentive to those projects that want to liberate creativity while reminding its users that a bit of ethics never hurts.**

The simplicity of the MPL v2.0 combined with a fair yet unobtrusive level of copyleft is what makes it a strong candidate for your next open source project!

### Resources

* [MPL v2.0](http://www.mozilla.org/MPL/2.0/)
* [MPL v2.0 FAQ](http://www.mozilla.org/MPL/2.0/FAQ.html)

### How to apply it to your code

You should follow the convention of putting the license text at the root of your source code tree in a `LICENSE` file.

In each source file, simply add a header with the text from *Exhibit A* in the MPL v2.0:

{% highlight java %}
/*
 * Copyright (c) <year> <copyright holders>
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/.
 */
{% endhighlight %}

