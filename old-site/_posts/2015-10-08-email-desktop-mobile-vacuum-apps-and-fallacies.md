---
title: "Email, Desktop, Mobile Vacuum Apps and Fallacies"
layout: post
---

Email on the Desktop is in a mess. In 2015 Mozilla has more or less long abandoned Thunderbird, Postbox is Thunderbird with a slightly better GUI, Apple Mail is _good enough_ but very short on customizability (shortcuts, plugins, etc), and MS Outlook is not especially better.

This in stark contrast with the huge interest for email productivity apps in the mobile space. Mailbox, now a (quiet) Dropbox product, showed the way a few years back by introducing new patterns for dealing with email. These patterns are mainly about swiping gestures to quickly take actions, and the ability to _snooze_ emails to get back to them at a specific time.

While dealing with personal email is generally _easy_, dealing with work email is a different matter. Adopting a _getting things done_ strategy typically revolves around moving email between folders, say _action_, _hold_, etc. Some people use flagging, and / or the (un)read status to help in their triage. The more hats you have in your job, and the more it gets complicated as you need to keep track of different contexts.

Mailbox and its myriad of clones provide genuine helpers to reduce frictions and turn a flood of email into actionable items. But this comes at a very special price...

### Email Vacuum

The email client has traditionally been a multi-protocol software commonly supporting IMAP, POP3 and possibly Exchange. Mailbox showed the way for something different: the client is connected to proprietary gateway services that in turn connect to the email servers. In short: to provide functionality and push notifications, a _man in the middle_ service reads all your emails from your provider, which can be your company.

This is of course a very big threat, as third-party companies just tap into _all_ your email. All _modern_ and _fancy_ productivity email applications just do that: Outlook/Accompli, myMail, CloudMagic, Mail.ru, etc. Only Inbox from Google fares better in the war of email productivity, as email does not leave the Google servers.

What is perhaps a bigger issue is that most end users have absolutely _no idea_ that their email is being vacuumed to a third-party service which in turn is _likely_ to do _something_ from the data. All these applications ask for the type of email account you would like to add (GMail, Exchange, IMAP, etc) then for your credentials. It takes a bit of technical knowledge not to be fooled with the wordings and claims of _industry-grade security_.

So yes, most of these apps will suck all your email _and_ they will know your email password (exception: GMail has OAuth, iCloud has app-specific passwords).

### Providing functionality: fallacies

So suppose you enjoy crunching through email with one of these applications on mobile devices. Now get back to the desktop and enjoy the total lack of continuity: you are stuck with a big mismatch between what your mobile application does, and what your desktop application does. This isn't exactly true: Mailbox has a (broken) desktop application and Inbox works fine from a web browser. But still, it's not like a using a quality desktop email client.

Email is fundamentally based on distributed and client-agnostic protocols. Application providers are lying when they claim that vacuuming your email is the only way to provide functionality.

* A protocol like IMAP is generic enough to hold something else than email. Apple Notes are being stored as emails in a special folder. You could imagine an email application that would store its preferences and state in such _special_ emails. This could include identifiers of _snoozed_ emails, when they should be pushed front again, email classification learnings, etc etc.

* Push email works with IMAP, too. The excellent Android K9 client supports _push_ by keeping a connection. Fastmail and Yahoo! have been given the technical details to support push on iOS devices. And even so, what's so wrong with receiving emails on a mobile device at most 15 minutes later?

Nothing precludes desktop and mobile applications to work hand-in-hand to offer great productivity features, and at the same time avoid gateway services. But of course, seeing through your email is very tempting...

### Open source to the rescue?

Between desktop clients lacking efficiency, cloud silos (GMail, Office 365, ...) and nice mobile clients acting as trojan horses for email vacuuming and with little interoperability with other applications, the state of email in 2015 is not all that sparkling.

The solution could, as usual, lie in open source. Mozilla did a lot of good in the browser space a few years back, but sadly it has completely lost interest in email. Still, after the _"let's take back the web"_ initiative, could Mozilla or another foundation fuel a _"let's take back the email"_?

Wouldn't it be nice to snooze an email from the iOS Mail application, have it pop back on a Android phone, and tweak classification settings from a Windows desktop?
