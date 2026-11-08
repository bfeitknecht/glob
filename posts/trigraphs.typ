#import "@preview/thyme:0.1.0": *
#import blog: *

#show: post.with(
  title: [Try Some Trigraphs!],
  subtitle: [Escaped linebreaks and pre-C23 keyboard relics],
  author: "Basil Feitknecht",
  monograph: "bkf3",
  created: datetime(year: 2026, month: 3, day: 16),
  modified: datetime(year: 2026, month: 10, day: 27),
  summary: [How C trigraph sequences turn an innocent single-line comment into an escaped newline that swallows the next statement.],
  tags: ("c", "compilers", "trivia"),
)

Apparently, in the early days of computers, people's keyboards were just missing some letters sometimes? So that's why they had trigraphs and digraphs#sidenote[In ISO C89 through C17, trigraph translation happens in translation phase 1 -- _before_ comment stripping -- mapping `??<` to `{`, `??/` to `\`, and `??>` to `}`. C23 finally removed trigraphs.] -- character groups that would indicate one of those pesky, important letters you couldn't type. Here's an example for demonstration purposes. Notice the multiple returns. This is fine because the comment above the first is an escaped linebreak. So, if trigraphs are enabled, that doesn't get compiled. Pretty wonky, but nonetheless genius. You can compile it with pre-C23 and probably have to pass `-trigraphs`.

#zebraw(
  highlight-lines: (2,),
  ```c
  int foo() ??<
      // ??/
      return 1;
      return 0;
  ??>
  ```,
)
