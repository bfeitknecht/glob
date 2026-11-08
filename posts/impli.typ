#import "@preview/thyme:0.1.0": *
#import blog: *

#show: post.with(
  title: [`impli`, My Beloved],
  subtitle: [Bringing a Haskell `IMP` interpreter to the browser via GHC WebAssembly, `xterm.js`, and JS-FFI],
  author: "Basil Feitknecht",
  monograph: "bkf1",
  created: datetime(year: 2026, month: 2, day: 28),
  modified: datetime(year: 2026, month: 10, day: 27),
  summary: [Seven months of Haskell, small-step operational semantics, WASI `stdin` pitfalls, and terminal addons on the road to running `impli` statically in the browser.],
  tags: ("haskell", "wasm", "pl", "compilers"),
)

_*Wow.*_ So many hours spent on this project. Read this blog post for some insight into the process.

= A Passion Project Is Born

Here are some words about the start of the whole thing. Initially, I was just intrigued by the idea of capturing the entire syntax description of core `IMP` in Haskell, just like on the lecture slides. That was pretty easy and fun. Then, I asked AI to write a simple parser. That was really easy too -- it was baffling how compactly this could be done with some library support. Finally, I wanted to be able to execute statements parsed into the IR data types. Again, this was quite straightforward: pretty much just pattern matching on the inference rules from the lecture and implementing them.

From then on, I was hooked. Wanting to add as many extensions as possible forced me to change the state data type frequently. Adding new parse rules was always the easiest part, though. At some point, it occurred to me to also implement small-step semantics. For convenience, it was obvious I had to add a REPL with a full meta-command system and a CLI to wrap everything. To be able to continuously build and release the newest version, I had to adopt a versioning scheme and get familiar with GitHub Actions workflows.

It was an awesome learning experience in so many ways. At first, I was still getting used to Haskell and functional programming, and then I had to learn everything else surrounding such a project. At some point, I realized that few people would actually care enough to use my interpreter if they had to clone and compile it themselves. Thus, I concluded it needed a web version.

#hr

This marked the start of quite the rabbit hole right at the end of summer break and before a very full semester. At first, it somehow seemed very doable.

= The Tragedy of Haskeline <haskeline>

From the beginning, it was clear that the well-established terminal library `xterm.js` would be used to provide the same feel as when running in a terminal emulator. Also, I wanted to host everything on GitHub Pages, so it had to be static and not rely on some dynamic web server. Initial exploration quickly narrowed down two paths to proceed: I could compile `impli` to WebAssembly or JavaScript. Since I had been interested in WASM for some time, that was my first approach.

Immediately, the biggest obstacle became clear, as Haskeline -- which is the library for line editing in the REPL -- used certain terminal capabilities not provided in the context of WASM. To work around this issue, I had to rewrite the monad stack for REPL computations to use pure `IO` as base. In doing so, I was, however, left with some nasty artifacts. The raw bytes for arrow-key navigation and backspace character deletion could not be interpreted and were displayed as escape codes.

One problem solved and another created -- a recurring theme in this undertaking. With some wacky hacks, the REPL seemed to kind of work, but everything fell apart in loops, and there was no way to fix the line-editing issues. Time to go back to the drawing board.

#hr

If you have a hammer, everything looks like a nail. Just have to find the hammer.

= Viva la JavaScript <ghc-js>

What failed with the previous approach? The compiled REPL didn't have the capabilities it expected in the browser environment. Thus, I concluded something that provides that would solve all my problems.

Some searching around led me to `xterm-pty`, which is an addon to the terminal library that promises a pseudoterminal-like environment for projects using Emscripten. Now, what is even that? It turns out to transpile LLVM to JS. That is very cool. Because the JS backend of GHC didn't have the compatibility issues with Haskeline, I decided to switch methods. My envisioned path forwards was basically `Haskell "ghc"-> LLVM "emcc"-> WASM+JS`.

Here, AI really seemed to struggle in being of meaningful assistance to me. I see two possible reasons for this:

+ The problem domain is rather niche; thus, some inaccuracy is to be expected.
+ My ideas were not mature enough, and requirements too unclearly defined.

Both were addressed by the nice community over at #link("https://matrix.to/#/#ghc-js-backend:matrix.org")[Matrix]. Posting my questions there, I was surprised by how quickly people responded with actually helpful tips and insightful follow-up questions. Someone even contributed to the project to help me set up the required build tools -- thank you, #link("https://github.com/alexfmpe")[Alexandre]!

So now I had a way to compile my Haskell to JS, just as God intended. Linking in the addon library code, at first glance, brought everything together. But generated code size was quite big, as the whole Haskell RTS (implemented in JS) has to be included. That was inelegant. Functionality parity was also bad. Most things just would not work, no matter what I tried. But I kept spending lots of time trying to make this approach work because of being hesitant to move away from Haskeline and having given up on WASM. Ultimately, all signs pointed me to accept the bitter taste of biting the bullet and reconsider my choices.

#hr

Surely, someone else has this all figured out.

= Convoluted Roamings

I was at my wits' end. Because both approaches turned out unfruitful, I hoped to find the solution hiding up someone else's sleeve.

AI was always very eager to recommend using Node to me. I absolutely dislike Node, so that was always easily dismissed. But might as well try it now. The problem here is that GitHub Pages, where I wanted to host everything, doesn't have the possibility to use a web server like Node. In similar fashion, AI suggested I write my own web server into `impli`, but that means multiple users could concurrently share the same process with some sort of messaging protocol, or tickets, or queues, or whatever. Things would get sticky fast, and that just didn't sit right with me.

At one point, I considered making a Docker image from scratch with just the `impli` executable and compile that image to WASM and connect it with `xterm.js` via `xterm-pty`. That's what another person did who I've gotten in contact with in hopes of finding my perfect solution. This would instantly yield perfect feature parity forever, for free (except for sacrificing my strong sense of elegance). Off the table. Also, `xterm-pty` deprecated some internal classes required for this hacky solution. Had a nice chat with the author of that addon too -- very helpful by being open to reimplement them.

So you see, it wasn't easy for me to navigate these cloudy waters of unknown depth and shape. But by sheer luck, I was drifting towards the eye of the storm.

#hr

Good things come to those who wait. Better things come to those who search? This is very technical, but I'll go into it because I care.

= Battle of Addons <battle-of-addons>

Like a glimmering ray of light restoring my hope, I stumbled upon `WasmWebTerm`, which promises simple plug-and-play for `xterm.js` with WASM modules. Just what I was looking for -- almost uncannily so. Here's where AI surprised me with its creativity. It suggested I use JS to only drive output and get input from Haskell with a foreign function import. That was a great idea because, for the longest time, I tried to do both things in only one or the other language. But this approach could actually bridge the ever-lurking gap by utilizing the best of both worlds.

I had already used two different libraries to instantiate my WASM and connect its standard output to the browser terminal. I'd realized very early on that the WASI standard input couldn't be connected to `xterm` in any meaningful way. The reason is that WASI needs synchronous `stdin`#sidenote[WASI's `fd_read` blocks synchronously, whereas browser keystrokes arrive asynchronously on the main event loop unless bridged through JS-FFI or a `WebWorker` + `SharedArrayBuffer` ring buffer.]. Thus, I exposed an asynchronous method to return user input when available, which I could then access through JS-FFI for the REPL in Haskell.

Sadly, that didn't work for the `read` statement, because the Haskell thread eagerly and asynchronously requested from standard input. If none was available, the REPL quit. As it turns out, by assigning a no-op in the WASI instantiation, the REPL would read empty input and crash. I needed a way to globally pass all input reading through the FFI or enable synchronous input with WASI.

Here, I iterated quite some times with different configurations. In the back of my mind, I still would have liked to avoid FFI for reading input. Looking back, I'm aware that wouldn't be feasible, but you're often wiser in hindsight. Anyways, `WasmWebTerm` wasn't the perfect fit it was, as it includes quite some other stuff that I didn't care about. Luckily, I found `LocalEchoAddon`. And thus began the battle of addons. My Git branches were many and more.

Even `xterm-pty` entered the stage again. The tried techniques include `WebWorker` with `SharedArrayBuffer` or promise chaining, and, on a high level, were mostly centered around managing an input queue. Mind you, I tried quite some of the possible combinations between addons and passing input between the frontend and backend. Below is a selected list of all the branches during development:

#zebraw(
  numbering: false,
  highlight-lines: (9,),
  ```
  echo-ffi
  echo-ffi-conditional
  echo-ffi-ts
  echo-ioref
  echo-pure
  feature/web/docker
  feature/web/wasm
  haskeline
  * master
  pty-ffi
  pty-runno
  pty-shim
  ```,
)

Finally, I settled with `LocalEchoAddon` coupled with JS-FFI. Specifically, the input acquisition method is stored in a global `IORef`. This way, I don't need conditional compilation or changes to the `IMP` library code. There might be another, cleaner way to do it with input being handled in JS, but I've reached my limit with breaking my head over this.

#hr

= Final Words

So now you know what I've been up to in my free time the last seven or so months. Hope you enjoyed this article and the insights it provided into the process behind the final presentable. If you haven't, check it out #link("https://bfeitknecht.github.io/impli")[here]. Below, you find a list of relevant links of articles, blog posts, or similar, with commentary for further reading:

- The #link("https://ghc.gitlab.haskell.org/ghc/doc/users_guide/javascript.html")[canonical page] for reference in regards to the GHC JS toolchain.
- #link("https://ghc.gitlab.haskell.org/ghc/doc/users_guide/wasm.html")[Ditto] for the WASM backend.
- Previously mentioned #link("https://abhinavsarkar.net/posts/repling-with-haskeline")[Docker approach] -- pretty much exactly the same scenario, just solved differently.
- #link("https://abhinavsarkar.net/posts/implementing-co-2/")[Article series] on the subject of interpreters -- very high-quality content.
- Simple, but straightforward #link("https://blog.haskell.org/case-study-foreign-integration-js-browser/")[guiding example] for usage of the JavaScript backend.
- #link("https://blog.haskell.org/report-of-js-code-minification/")[JS code minification report], since GHC JS sometimes does too much.
- Very clear and helpful #link("https://finley.dev/blog/2024-08-24-ghc-wasm.html")[guiding example] for the WASM backend.
- Extremely detailed and super interesting #link("https://aosabook.org/en/v2/ghc.html")[overview] of the native GHC.
