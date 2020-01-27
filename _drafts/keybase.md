---
title: "Simpler GnuPG with another look at Keybase"
layout: post
---

I recently decided to revoke a 10 years old GnuPG key pair that I was using across machines, and decided to start from a clean sheet.
I wanted to ensure I could continue using GnuPG to sign opensource release materials, but also sign public Git commits.
Until then all I used to sign were Git tags.

As I wanted to find a better solution than just using plain GnuPG and its numerous practicability flaws, I gained renewed interest in [Keybase](https://keybase.io), especially as it now provides more than just a streamlined experience with encryption tools.

The configuration steps are adapted from [Patrick Stadler's instructions on GitHub](https://github.com/pstadler/keybase-gpg-github).
There is a macOS bias in some of the commands which you can easily adapt to other Unix systems 😉

### The GnuPG experience 😟

I have a _"love - hate - hate - love - hate - hate - hate"_ relation with GnuPG.

This tool has a horrible user interface, and I have never really found it useful for communications.
Over 15 years I have had a few GnuPG-encrypted email communications with colleagues or friends, but it has always been a hindrance.
Also while it did encrypt communication content, there is enough meta-data in plain text with email (title, recipients, etc) to make GnuPG email encryption a half-baked solution to a real problem.

Still, GnuPG is useful because we may have files to encrypt so their content can only be read by ourselves and maybe a few people.
We may also want to sign files for integrity checks.
This is especially important with opensource development where signing source and release artifacts is a plus, and often a necessity.

Generating a key pair with GnuPG is not very difficult, and under 2 minutes you can have one and push it to some public key servers.
The problem is that once you have a key pair then no one really knows if the identity claimed is real or not.
So you can get to your friends or at so-called "key signing parties" and sign other people key to claim that you have verified that some public key does belong to the person it claims to be.
By doing so keys form trust networks, which helps recognizing plausibly authentic versus fake keys.

In practice no one but a few geeks or activists will want to do that seriously.
You will likely do it with a few friends and colleagues once in a while, and... that will be it.
And of course people will loose their keys and they will not even have a revocation key 😇

### Enter Keybase 🤔

The [Keybase](https://keybase.io) service was introduced a few years back with the interesting idea of mapping social / public identities to encryption keys.
Keybase essentially introduced a modern way to build trust networks, because people can check that `user123` on Keybase is also `user123_coder` on GitHub, `user123` on Twitter, and that the user owns the `iamuser123.org` domain.
One can do so by posting Keybase-signed messages to these social networks and places.
This is a good idea, because from social networks and Keybase accounts linked to those social networks, you can build a trust network on Keybase.

Keybase also offered streamlined web and command line user interfaces for managing Keybase, following people and encrypting / decrypting content.
Keybase provides a simplified workflow for common tasks including key management (e.g., fetching keys of your contacts), and it has GnuPG interoperability.
You may even make the _devilish_ (read: _convenient_) choice of having your keys stored on Keybase, or just attach existing GnuPG keys that you will still manage locally.

Like many people I on-boarded when the service opened and it went viral on Twitter.
But then like many people I never really used it because, well, I'm not using GnuPG everyday anyway.

### Fast-forward Keybase today 🤔

I believe that Keybase deserves a second wave of interest, because the modern Keybase is way more interesting than just mapping identities to encryption keys.

Indeed Keybase now offers:

* a chat system for individuals,
* a nicely-done Slack-like chat for teams,
* private, group and public file sharing (e.g., folder `me,other` is shared between 2 users),
* Git repositories for yourself and teams,
* some crypto-currency thing which I don't care about.

This is interesting as everything is encrypted.
There are many contexts where using Keybase makes sense, such as research groups in Universities.
This is a context where institutions will typically provide you with bad tools and services, refrain you from using well-known tools, and the boundaries of who you work with are quite malleable since you work with people at other institutions and companies.
Here Keybase can be a secure replacement for chat, file sharing and (unpublished) source code management tools.

So how can we we use Keybase and also make GnuPG friendly to other tools like Git?

### Setup Keybase 💡

On macOS with _Homebrew_ all you need is:

```bash
brew install gnupg
brew cask install keybase
```

For other types of installation please refer to [the Keybase website download section](https://keybase.io/download).

You will then want to use `keybase login` to either register your machine or create a new account.
You can also use the desktop client for a friendlier experience.

You will want to claim identity proofs in various places and services: Twitter, GitHub, your website, your domain name, etc.
You can do so with `keybase prove` or the desktop client.

Last but not least, you will want to _follow_ people: `keybase follow` is your friend 😉

### Generate a GnuPG key 💡

Now you need Keybase to generate a GnuPG key for you:

```bash
keybase pgp gen --multi
```

The `--multi` flag will allow you to generate a key with multiple name / email addresses.
In my case I have 2 personal email addresses and my Red Hat work email that I'm also using for opensource contributions.

Once this is done you run the following command to know the identifier of your secret key:

```bash
gpg --list-secret-keys --keyid-format LONG
```

And of course note the identifier for your public key, here in another format:

```bash
gpg --list-keys  --keyid-format 0xshort
```

### Publicize your GnuPG public key 🎙

Various services like Maven Central will want your public key to be available from a trusty key server.

You can use `gpg` to send your key to various key servers, as in:

```bash
gpg --keyserver pgp.mit.edu --send-keys IDENTIFIER_OF_YOUR_PUBLIC_KEY
```

You may find it equally useful to use the web interfaces of a few popular key servers to paste and upload your public key.
In that case first copy your public key to the clipboard (`pbcopy` is macOS specific):

```bash
gpg --armor --export ONE_OF_YOUR_EMAIL_ADDRESS | pbcopy -
```

then go to a few places:

* [https://keyserver.2ndquadrant.com](https://keyserver.2ndquadrant.com)
* [https://pgp.mit.edu](https://pgp.mit.edu) 
* [https://keyserver.ubuntu.com](https://keyserver.ubuntu.com)

Your key will quickly be synchronized between a network of public key servers.

### Git (and GitHub, GitLab, etc) commit signing ✅

Your signing key is your private key identifier.
With that information, enable commit signing globally:

```bash
git config --global user.signingkey PRIVATE_KEY_IDENTIFIER
git config --global commit.gpgsign true
```

If you are on macOS you will need to install `pinentry-mac`:

```bash
brew install pinentry-mac
```

and then edit `~/.gnupg/gpg-agent.conf` so it contains the following line:

```
pinentry-program /usr/local/bin/pinentry-mac
```

The first time you do a signed commit you will be prompted to enter your secret key passphrase, and you will be offered to save it in your macOS user keychain.
If you do so then you will automatically sign commits and tags without having to worry about the passphrase.

You can now tell your Git repository hosting services about your key, so it can show that your commits have been signed and that the signature is yours:

* get your key in your clipboard (`gpg --armor --export ONE_OF_YOUR_EMAIL_ADDRESS | pbcopy -`),
* in the case of GitHub go to [https://github.com/settings/keys](https://github.com/settings/keys),
* for other providers like GitLab, check in your profile / settings.

### Gradle and key signing 🤦‍♂️

I encountered a few issues with the [Gradle signing plugin](https://docs.gradle.org/current/userguide/signing_plugin.html).
I could not make it use the GnuPG agent, and I had to let it use the default which is to use a secret key ring file.

Edit `~/.gradle/gradle.properties` so all your projects share the same configuration.
You will need 3 signing-specific entries:

```
signing.keyId=0x1234
signing.password=my-secret-password
signing.secretKeyRingFile=/Users/user123/.gnupg/secring.gpg
```

Replace `signing.keyId` with your private key identifier, `signing.password` with the key password, and replace `/Users/user123/` with the path to your user account.
You may also want to lock down the file permissions with `chmod` so only your account can read it (remember, your passphrase is in plain text).

The `secring.gpg` file may not exist if this is a first install, so run this command:

```bash
gpg --keyring secring.gpg --export-secret-keys > ~/.gnupg/secring.gpg
```

### Enter a new machine 💡

What happens if you have another machine to provision, be it as a replacement or as a complement?

Assuming that you created your GnuPG key from Keybase, it is stored and managed by Keybase.
All you need to do is login on the new machine with your Keybase account, then:

```
keybase pgp list
```

should give your GnuPG key identifier.
You can then import the public and private keys as follows:

```
keybase pgp export -q IDENTIFIER | gpg --import
keybase pgp export --secret -q IDENTIFIER | gpg --import --allow-secret-key-import
```

Encryption experts _will_ complain, especially if you let Keybase store your private keys, but:

1. storing your private key on a plain USB drive or unencrypted cloud storage is also dangerous, and
2. if you really need to communicate sensible data to someone else then you will learn GnuPG in-depth, you will be very strict regarding key validation, trust and exchange, and you will not use email.


### Conclusion

Keybase + GnuPG sounds like a nice combo.

👋 By the way you can find me on Keybase at [https://keybase.io/jponge](https://keybase.io/jponge).

Ping me there and let me know if this was useful to you 😎

Thanks again to [Patrick Stadler](https://github.com/pstadler/keybase-gpg-github) for the original instructions.

Have fun!

