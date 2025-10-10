---
title: "Exporting HTML Slides in Markdown to PDF"
layout: post
---

I am not a big fan of HTML slides.
For sure many fancy tools and libraries exist in that space, but no matter what I always prefer the pixel-perfection of a tool like Apple Keynote.
Pushing pixels is what I prefer doing for public talks and important meetings.

The flip side of the coin is that crafting great slide decks **is** time consuming.
There is a context where having _just good enough_ slides is key: teaching.

Teaching slide decks are always big, and you _need_ to put lots of text for students.
Doing a public talk with lots of text is a major _faux-pas_, but when doing teaching a reasonable amount of text it is actually helpful.
I'm in computer engineering, so my slides tend to have lots of code snippets: this is an area where traditional presentation softwares fall short.

Last but not least: teaching slide decks need to be frequently updated, refactored and remixed, so any tooling friction is painful.

### Markdown to HTML

There are many fancy tools with rollercoaster visual effects on slide transitions.
I like none of them, so I went with the simple and effective [markdown-to-html](https://github.com/cwjohan/markdown-to-html).

This way I can just type some Markdown, as in:

    ---

    class: middle, left

    # Basic stuff

    ---

    # A class...

    `src/main/java/fr/insa/tc/mid/Hello.java`

    ```java
    package fr.insa.tc.mid;

    import java.util.List;
    import java.util.ArrayList;

    public class Hello {

        private final List list = new ArrayList();

        public void doStuff() {
            list.add("A");
            list.add("B");
            list.add("C");
        }
    }
    ```

Except for the `class` attributes that allow some layout and positioning, it's just Markdown with slides being separated by `---` rulers.

![Slides in HTML](/images/posts/2017/md2html.png)

I am using the default CSS stylesheet with some font adjustments.
The great thing with markdown-to-html is that it is very easy to customize.

Rendering slides to HTML is done with this quick shell script:

{% highlight bash %}
#!/bin/bash
for f in *.md; do
  markdown-to-slides -s style.css -o "$(basename $f .md).html" $f
done
{% endhighlight %}

### PDF export 

Some students have asked me for a PDF output.
Fortunately it is not very complicated to do!

I recommend [DeckTape](https://github.com/astefanutti/decktape) for that purpose.
Like most HTML to PDF renderers, it takes control of a web browser engine via PhantomJS to capture slide images then assemble them as a PDF.

If you use DeckTape as a one-shot tool just like I do, it is perhaps easier to use the Docker image.
Again, a shell script does the heavy work:

{% highlight bash %}
#!/bin/bash
for f in *.md; do
  deck=$(basename $f .md) 
  docker run --rm -v `pwd`:/slides astefanutti/decktape $deck.html $deck.pdf
done
{% endhighlight %}

The way it works is simple:

1. `--rm` ensures the container gets erased after execution,
2. `-v` allows mounting the local folder to `/slides` in the container,
3. DeckTape then does the magic.

Easy, isn't it?

![Slides in HTML](/images/posts/2017/html2pdf.png)