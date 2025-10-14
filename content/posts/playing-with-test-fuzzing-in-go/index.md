---
date: '2022-03-23'
title: 'Playing with Test Fuzzing in Go'
readTime: true
toc: true
autonumber: true
---

Go 1.18 recently introduced _test fuzzing_, so I decided to give it a go (no no, I'm not making a stupid joke).

[Go has a great tutorial about fuzzing](https://go.dev/doc/tutorial/fuzz).
The idea behind fuzzing is not to replace traditional tests but rather to complement them by (randomly) iterating over input values to the code under test.
This is helpful to find bugs and security issues on data whose domain are numbers, byte arrays or strings.

Using fuzzing to detect a division by zero error is most likely a bad idea if the code under test takes a parameter that is directly used to divide, as in:

```go
func DoSomeMath(a int, b int, c int) int {
	return (a + b) / c
}
```

Catching that `c` shall not be `0` is possible with fuzzing as at some point `c` will be `0`, but it should really be one of the first test cases you write.
Now of course if your code performs a division by a number whose link with the function arguments is not so obvious then fuzzing might help.

## Palindromes shall be easy, right?

So let's take a quite simple example: [palindromes](https://en.wikipedia.org/wiki/Palindrome).

`1221`, `//--//`, `madam` and `eye` are valid palindromes, while `foo` is not.

Let's start with a first iteration of a `IsPalindrome` function:

```go
func IsPalindrome(str string) bool {
	first := 0
	last := len(str) - 1
	for first <= last {
		if str[first] != str[last] {
			return false
		}
		first++
		last--
	}
	return true
}
```

I took a very simple approach to the code, with indexes at both ends of the string that converge to the middle as long as characters are identical.

Let's have a simple tabular test to cover some basic cases:

```go
func TestIsPalindrome(t *testing.T) {
	tests := []struct {
		str  string
		want bool
	}{
		{
			str:  "eye",
			want: true,
		},
		{
			str:  "1221",
			want: true,
		},
		{
			str:  "//--//",
			want: true,
		},
		{
			str:  "foo",
			want: false,
		},
	}
	for _, tt := range tests {
		t.Run(tt.str, func(t *testing.T) {
			if got := IsPalindrome(tt.str); got != tt.want {
				t.Errorf("IsPalindrome() = %v, want %v", got, tt.want)
			}
		})
	}
}
```

Let's test:

```
$ go test                
PASS
ok      yolo/playground 0.239s
$
```

Great! How about coverage?

```
$ go test -coverprofile=coverage.out
PASS
coverage: 100.0% of statements
ok      yolo/playground 0.170s
```

With 100% of statements, our code must be great... right?

## Enter fuzzing! (drama)

Fuzzing works for types such as numbers, strings, byte arrays, boolean values, etc.
If your input data is some `struct` then you will need to feed its fields with some fuzzed data.
The fuzzing engine can't magically generate random `struct` values 🤣

Here's a fuzzing test:

```go
func FuzzIsPalindrome(f *testing.F) {
	f.Add("kayak")
	f.Fuzz(func(t *testing.T, str string) {
		t1 := IsPalindrome(str)
		t2 := reverse(str) == str
		if t1 != t2 {
			t.Fail()
		}
	})
}
```

The `testing.F` type is for fuzzing.
The `Add` function allows passing some _seed data_ for each argument of the function given to `Fuzz`.
Since we have just 1 parameter for fuzzing we just pass 1 string.
This will be the value of `str` at the first iteration, then the engine will derive some other (random) strings.

Checking failures requires having some way to check results.
This can be a challenge with fuzzing since you don't know in advance what is the outcome given the input values.
In this case we use a custom `reverse` function that reverses a string, so it's a cheap way to check the behavior of our `IsPalindrome` function (more on `reverse` in the next section).
In other cases you might rely on the code under test to report an error or even panic.
Your mileage varies, but it can sometimes be difficult to find a way to report when tests pass and when they fail.

So what happens when we run tests just like before?

```
$ go test -v                    
=== RUN   TestIsPalindrome
=== RUN   TestIsPalindrome/eye
=== RUN   TestIsPalindrome/1221
=== RUN   TestIsPalindrome///--//
=== RUN   TestIsPalindrome/foo
--- PASS: TestIsPalindrome (0.00s)
    --- PASS: TestIsPalindrome/eye (0.00s)
    --- PASS: TestIsPalindrome/1221 (0.00s)
    --- PASS: TestIsPalindrome///--// (0.00s)
    --- PASS: TestIsPalindrome/foo (0.00s)
=== RUN   FuzzIsPalindrome
=== RUN   FuzzIsPalindrome/seed#0
--- PASS: FuzzIsPalindrome (0.00s)
    --- PASS: FuzzIsPalindrome/seed#0 (0.00s)
PASS
ok      yolo/playground 0.246s
$
```

We can see that the fuzz test case as been used with the seed data.

Now let's run some proper fuzzing:

```
$ go test -fuzz FuzzIsPalindrome
fuzz: elapsed: 0s, gathering baseline coverage: 0/8 completed
fuzz: minimizing 264-byte failing input file
fuzz: elapsed: 0s, gathering baseline coverage: 3/8 completed
--- FAIL: FuzzIsPalindrome (0.02s)
    --- FAIL: FuzzIsPalindrome (0.00s)
    
    Failing input written to testdata/fuzz/FuzzIsPalindrome/530aa3ce17341fb6fbfd1f28e61b116d8a1f20c03b796122175963d7a7863256
    To re-run:
    go test -run=FuzzIsPalindrome/530aa3ce17341fb6fbfd1f28e61b116d8a1f20c03b796122175963d7a7863256
FAIL
exit status 1
FAIL    yolo/playground 0.270s
$
```

Oops! We have a bug! 🙀

We have a new file under `testdata`, a folder where you can place all files useful for your package tests but that compilation will ignore.
This file tells us which input string caused the failure:

```
$ cat testdata/fuzz/FuzzIsPalindrome/530aa3ce17341fb6fbfd1f28e61b116d8a1f20c03b796122175963d7a7863256 
go test fuzz v1
string("11\xc311")
$
```

In any case our regular tests now take this input data into account to catch regressions:

```
$ go test                       
--- FAIL: FuzzIsPalindrome (0.00s)
    --- FAIL: FuzzIsPalindrome/530aa3ce17341fb6fbfd1f28e61b116d8a1f20c03b796122175963d7a7863256 (0.00s)
FAIL
exit status 1
FAIL    yolo/playground 0.214s
$
```

Note that since that file catches a bug it shall be under version control.

## Fixing bugs

So let's go back to the failed test: the input string is not a correct UTF-8 string.

We can fix the `IsPalindrome` using the `unicode/utf8` package `ValidString` function:

```go
func IsPalindrome(str string) bool {
	if !utf8.ValidString(str) {
		return false
	}
	first := 0
	last := len(str) - 1
	for first <= last {
		if str[first] != str[last] {
			return false
		}
		first++
		last--
	}
	return true
}
```

And now we're back to green tests:

```
$ go test
PASS
ok      yolo/playground 0.242s
$
```

Are we done?

Let's do some more fuzzing for 15 seconds:


```
$ go test -fuzz FuzzIsPalindrome -fuzztime 15s
fuzz: elapsed: 0s, gathering baseline coverage: 0/9 completed
fuzz: elapsed: 0s, gathering baseline coverage: 9/9 completed, now fuzzing with 12 workers
fuzz: elapsed: 0s, execs: 1406 (5198/sec), new interesting: 2 (total: 11)
--- FAIL: FuzzIsPalindrome (0.27s)
    --- FAIL: FuzzIsPalindrome (0.00s)
    
    Failing input written to testdata/fuzz/FuzzIsPalindrome/b102348c25c69890607f026bc3186f5faf9de089188791a75c97daf5fdd10caa
    To re-run:
    go test -run=FuzzIsPalindrome/b102348c25c69890607f026bc3186f5faf9de089188791a75c97daf5fdd10caa
FAIL
exit status 1
FAIL    yolo/playground 0.526s
$
```

Another failure! 😿 

```
$ cat testdata/fuzz/FuzzIsPalindrome/b102348c25c69890607f026bc3186f5faf9de089188791a75c97daf5fdd10caa
go test fuzz v1
string("Ó")
$
```

It turns out that we should work on _runes_ (aka the string as a bytes array) rather than accessing string elements by index.

A good hint is the `reverse` function we use in tests and that we copy/pasted from somewhere on the _Grand Internet_:

```go
func reverse(str string) string {
	r := []rune(str)
	var res []rune
	for i := len(r) - 1; i >= 0; i-- {
		res = append(res, r[i])
	}
	return string(res)
}
```

So let's do the same and work on runes:

```go
func IsPalindrome(str string) bool {
	if !utf8.ValidString(str) {
		return false
	}
	r := []rune(str)
	first := 0
	last := len(r) - 1
	for first <= last {
		if r[first] != r[last] {
			return false
		}
		first++
		last--
	}
	return true
}
```

We are now back to green:

```
$ go test                                     
PASS
ok      yolo/playground 0.257s
$
```

And let's do some more fuzzing:

```
$ go test -fuzz FuzzIsPalindrome -fuzztime 15s                                                       
fuzz: elapsed: 0s, gathering baseline coverage: 0/12 completed
fuzz: elapsed: 0s, gathering baseline coverage: 12/12 completed, now fuzzing with 12 workers
fuzz: elapsed: 3s, execs: 223057 (74327/sec), new interesting: 24 (total: 36)
fuzz: elapsed: 6s, execs: 223057 (0/sec), new interesting: 24 (total: 36)
fuzz: elapsed: 9s, execs: 503462 (93490/sec), new interesting: 26 (total: 38)
fuzz: elapsed: 12s, execs: 538411 (11648/sec), new interesting: 27 (total: 39)
fuzz: elapsed: 15s, execs: 580859 (14151/sec), new interesting: 28 (total: 40)
fuzz: elapsed: 16s, execs: 580859 (0/sec), new interesting: 28 (total: 40)
PASS
ok      yolo/playground 16.336s
$
```

No more failures, we seem to be much better now! 🎉

## Conclusion

We just saw test fuzzing in Go.

- Fuzzing works on Go data types.
- Fuzzing is useful to detect obscure bugs even when your regular tests have excellent coverage.
- Detecting failing tests can be tricky compared to regular tests. Failures can be detected based on: errors, panics, a side function to check, a property of the function return value, etc.
- Fuzzing produces test data files that are picked up by tests, and that shall become part of your source code to prevent from future regressions.
- Fuzzing is not deterministic. But the beauty is that it helps you enrich your deterministic tests.