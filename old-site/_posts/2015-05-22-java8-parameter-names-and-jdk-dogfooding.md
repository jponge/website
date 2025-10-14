---
title: "Java 8 Parameter Names and Dogfooding"
layout: post
---

Java 8 received most of its praise for the support of _lambdas_ and _streams_, but many framework
developers certainly rejoiced that the JVM now **finally** supports parameter names.

### Do not repeat yourself

Many frameworks try to take advantage of conventions to ease the programming models,
which translates to something like this with, say, Spring MVC:

{% highlight java %}
@RequestMapping(value = "/login", method = RequestMethod.POST)
public String login(
    HttpSession session,
    @RequestParam("login") String login,
    @RequestParam("password") String password) {
  // (...)
  return "redirect:/";
}
{% endhighlight %}

The `@RequestParam` annotation is inherently inelegant: in an ideal world it should only be used
when a parameter name does not match a request parameter. In practice the annotation value is most
always the same as the parameter name, but going through the annotation is the only reliable way to
pass a name to the framework.

### What's in a parameter? (before Java 8)

On the JVM, a parameter or a local variable is simply a 0-indexed number. In the `login` method
example above, `this` is at index 0, `login` at index 1 and `password` at index 2. There is simply
no name encoded in the bytecode to be accessed through reflection.

This is not 100% true as compiling Java code with debug symbols (which one should always do) gives
the names for debuggers.
[There are hacks to get parameter names through debug symbols](https://github.com/paul-hammant/paranamer), including reading bytecode, but it's never perfect to rely on something that may or may not be present.

### "Do as I say, not as I do" (Java 8)

Now that [Java 8 supports parameter names to be accessible though reflection](https://docs.oracle.com/javase/tutorial/reflect/member/methodparameterreflection.html), the problem is supposed to be solved.

There is just one _little_ problem: one needs to compile with `javac -parameters`, and the `-parameters` flag is off by default. And guess what? **The JDK is not compiled with that flag!**

Here is a simple showcase:

{% highlight java %}
import java.lang.reflect.Method;
import java.util.ArrayList;
import java.util.Arrays;

// Requires `javac -parameters`
public class Main {

  public static void foo(String bar, int baz) { }

  public static void main(String... args) throws Throwable {

    Method method = ArrayList.class.getMethod("add", int.class, Object.class);
    Arrays.stream(method.getParameters()).forEach(System.out::println);

    method = Main.class.getMethod("foo", String.class, int.class);
    Arrays.stream(method.getParameters()).forEach(System.out::println);
  }
}
{% endhighlight %}

Running that code prints:

    int arg0
    E arg1
    java.lang.String bar
    int baz

How can the JDK classes be compiled without parameter names is just beyond me...

### Parameter names in Golo

The next versions of Golo will support [parameter names](https://github.com/golo-lang/golo-lang/pull/250):

{% highlight golo %}
struct Foo = {x, y}

# (...)

let f = |x, y| -> x - y
let r_1 = f(x=10, y=2)
let r_2 = f(y=10, x=2)
let foo = Foo(y="b", x="a")
{% endhighlight %}

We had lots of discussions with Daniel on how to properly do that. Initial experiments used an
annotation to encode parameter names, but as we shifted to Java SE 8 as a requirement we opted for
using the parameter name support in the bytecode.

This works marvelously well for Golo, and we can even take advantage of Java libraries compiled with
`javac -parameters` to call methods using parameter names, just like Golo functions.

### Conclusion

![Y U NO](/images/posts/2015/lvigg.jpg)
