---
title: "Jekyll and Amazon AWS hosting"
layout: post
---

I used to host [my website](https://julien.ponge.org/) on a virtual private server. Maintaining a
server is always a useful skill to have, especially when using a _"infrastructure as code"_ approach.
See [my article on Vagrant](/blog/scalable-and-understandable-provisioning-with-ansible-and-vagrant/)
as an example.

My VPS instance used to be hosted by [Gandi](https://www.gandi.net/hosting/iaas). I have been a Gandi
customer for 15 years to deal with domain names, and I jumped to them for hosting when they ventured
into the IaaS offering business.

I can only say positive things on the Gandi IaaS offering. It has always been rock solid in my experience.
It is a bit pricey, but you get what you pay for.

As I wasn't using the server instance for anything more than running a HTTP server for static files,
I looked into a cheaper option (I was paying around 9 euros per month for a tuned-down VPS).

I could have gone the [GitHub Pages](https://pages.github.com) way, but I prefer the flexibility of
custom Jekyll plugins, or the ability to switch to another static site generator. I also wanted to
keep the HTTPS support.

So I went with [Amazon AWS](http://aws.amazon.com/).

## Tools of the trade

I generate my websites with [Jekyll](http://jekyllrb.com), mostly because it is as minimalistic as it
needs to be. Jekyll just gets out of the way with minimal fuss.

The produced static website is then stored to a S3 bucket, and delivered using the CloudFront CDN.
Because I had specific requirements on *not* using a `CNAME` DNS entry to point `julien.ponge.org` to
a CloudFront distribution, I also use Route53 to manage the DNS.

This costs me overall about 0.50 / 0.60 euros per month depending on the dollar-euro conversion
rate, and taking into account that S3 and CloudFront cost me pretty much nothing since I am still
eligible for the 1-year free tier.

That is a pretty good deal I guess, and from my traffic figures it should not be significantly more
expensive when I exit the free tier.

## Important notes

### HTTPS

HTTPS support for CloudFront instances is done via [SNI](http://en.wikipedia.org/wiki/Server_Name_Indication).
You will need to upload your certificates from the command-line tooling with the
[`aws iam upload-server-certificate` subcommand](http://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/SecureConnections.html#CNAMEsAndHTTPS).

You should also pay attention to the length of your SSL Certificate: it should be no more than 2048 bits.
I initially had a 4096 bits certificate, and spend some time digging the issue.

### Setup, uploading and invalidating

Uploading to S3 and invalidating CloudFront entries can be daunting, so you should simplify your task
with [s3_website](https://github.com/laurilehmijoki/s3_website).

It also does the proper configuration of your S3 bucket to server websites over HTTP. It does the
same with CloudFront, by creating a distribution if need be.

It uses a simple `s3_website.yml` configuration file. In my case it looks like this:

{% highlight yaml %}
s3_id: <%= ENV['S3_ID'] %>
s3_secret: <%= ENV['S3_SECRET'] %>
s3_bucket: julien.ponge.org

max_age: 300

gzip: true

s3_reduced_redundancy: true

cloudfront_distribution_id: <%= ENV['CLOUDFRONT_ID'] %>
cloudfront_invalidate_root: true
cloudfront_distribution_config:
  default_cache_behavior:
    min_TTL: <%= 60 * 60 * 24 %>
  aliases:
    quantity: 1
    items:
      CNAME: julien.ponge.org
  price_class: PriceClass_100
{% endhighlight %}

Note that I am using `PriceClass_100`, which means that I chose the cheapest CloudFront price class.
Most of my traffic comes from the US and Europe anyway, so I can save money by not having broad CDN replicates
around the globe.

### Misc.

`s3_website.yml` is likely to be in the root of your Jekyll content, so it is a good idea to
exclude it from the output files in `_config.yml`:

{% highlight yaml %}
exclude:
  - bower.json
  - s3_website.yml
  - bower_components
{% endhighlight %}
