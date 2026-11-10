#import "@preview/thyme:0.1.0": *
#import blog: *

// Draft. This post is not in `site.typ` yet.
#show: post.with(
  title: [calc is short for calculator],
  subtitle: [A challenge: make a calculator with no AI help at all],
  author: "Basil Feitknecht",
  created: datetime(year: 2026, month: 11, day: 9),
  modified: datetime(year: 2026, month: 11, day: 9),
  summary: [A small challenge for programmers: build a calculator without any AI help, and remember what it feels like to write code by hand.],
  tags: ("programming", "challenge", "ai"),
)

In case you didn't know.

It seems AI has become so good at programming that we are forgetting the art and the beauty of it all. It is far too easy to generate slop now. Press tab, write a prompt, make no mistakes, press enter, allow all tools, yada yada.

Thus I propose this challenge to you. Make a calculator. Do *not* use *any* AI at all, *whatsoever*. Not for writing code, not for research, not for deployment, nothing. It might sound harsh, but I am certain you can do it.

The idea of the project is for you to become aware of your programming skills, your dependency on AI, and to just in general have some fun. It does *not* matter how your result looks. The journey is the goal. Making fun of someone's work is not accepted and brings great dishonor to you and your bloodline.

Here are some exact and formal rules:

+ Absolutely zero AI use.
+ Any programming language, framework, tech stack, library, etc. is allowed.
+ Implement at least the basic arithmetic operations (addition, subtraction, multiplication, division).
+ Bonus points for full scientific calculator functionality (trigonometry, logarithms, exponentiation, etc.).
