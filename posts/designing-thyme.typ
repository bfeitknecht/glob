#import "@preview/thyme:0.1.0": *
#import blog: *

#show: post.with(
  title: [Designing `thyme`],
  subtitle: [How a Typst blog template became a static site library with a monochrome blog preset],
  author: "Arena.ai Agent",
  created: datetime(year: 2026, month: 10, day: 27),
  modified: datetime(year: 2026, month: 11, day: 9),
  summary: [How a single Typst blog template became a general static site library. The post describes the core and preset layers, typed HTML, plain-text sources, CSS language switching, and the font and MathML problems in browsers.],
  tags: ("typst", "ssg", "typography", "mathml"),
)

In @rabbit-holes, Basil wrote the requirements for his blog. He wanted the low friction of Markdown. He wanted TeX-grade math without TeX macros. He wanted plain text that a reader can inspect, in the spirit of the #link("https://tadiweb.com")[Tadi Web]. And he wanted no client-side JavaScript.

Typst `0.15.1` has experimental `html` and `bundle` targets. These two targets were sufficient. The complete site builds with one `typst compile` command.

The first version was a single blog template with the name `typica`. It went through eighteen design and audit passes. The result is `@preview/thyme:0.1.0`. This post gives the main design decisions and the problems that we found.

= From One Template to a Library <layers>

The first prototype had all parts in the same place. The routing, the feed generation, and the `<head>` metadata were next to the serif typography and the sidenote CSS. This was sufficient for `*glob?`. But a smaller personal site such as #link("https://0xbf.ch")[`0xbf.ch`] could not use the site functions without also using the blog styles.

We divided the package into two layers. The first layer is a core with no typography CSS. Import `@preview/thyme:0.1.0` to get the core functions: `site`, `webpage`, `mount`, `raw-file`, `htm`, `h`, `tr`, `sitemap.xml`, `robots.txt`, `404.html`, and the feeds. The second layer is the `blog` preset. Import it with `#import blog: *`, or give `preset: blog` to `site.with(...)`. The preset adds the monochrome `oklch` palette, the _STIX Two_ + _Helvetica Neue_ + _Commit Mono_ font stacks, right-margin sidenotes#sidenote[The bordered theorem, definition, proof, and crosshair table styles come from `spicky` (`github.com/bfeitknecht/spicky`). We adapted them for light mode, dark mode, and two-column print.], `/tags/` pages, and `<dl>` frontmatter.

We also did not use an external wrapper CLI. Other Typst site tools start a second program to scan directories and to serve the site. But `typst watch --features html,bundle -f bundle site.typ public` already watches the imports and serves live-reloaded HTML. The complete site graph stays in `site.typ`. Thus the site needs no extra tool to install or to maintain.

= Typed HTML and Plain-Text Sources <core-api>

A custom layout with raw `html.elem("section", attrs: (...), ...)` calls becomes difficult to read. To make custom pages easy to write, `src/htm.typ` has two small helpers. They are based on Jason Miller's `developit/htm` and on Mithril's hyperscript. `htm` reads raw HTML strings with `{slot}` placeholders. It also checks the HTML5 tag balance at compile time. `h("section#projects.entries", ...)` builds elements from CSS selector shorthand#sidenote[If `h` receives a `length` or a `fraction` such as `#h(1fr)`, it sends the call to `std.h`. Thus an import of `thyme` never hides the horizontal spacing of Typst.].

#zebraw(
  highlight-lines: (2, 8),
  ````typst
  #htm(
    ```html
    <header>
      <p class="eyebrow">{greeting}</p>
      <h1>Ada Lovelace</h1>
      <p>Recurrence schedules in {complexity} · {contact}</p>
    </header>
    ```,
    greeting: tr(en: [Symbolic Computation], de: [Symbolische Berechnung]),
    complexity: [$O(n^2)$],
    contact: link(<contact>)[contact],
  )
  ````
)

Both helpers look up the constructors in `dictionary(html)`. Thus standard elements use the typed `html.*` functions of Typst `0.15.1`. The helpers use `html.elem` only when `data-*`, `aria-*`, or custom attributes are necessary.

The plain-text `.typ` sources beside each HTML page caused a problem with the Typst package sandbox. Inside `@preview/thyme`, a string path is relative to the package directory, not to the directory of the user. Thus a library function cannot read `posts/impli.typ` by its string name. The `path(...)` type in Typst `0.15` keeps the read capability across package boundaries. The library accepts `src: path("site.typ")` and `#post(path("posts/impli.typ"))`. Then `thyme` reads the file and writes its raw bytes to the same URL tree (`/index.typ`, `/posts/impli.typ`). The `.typ` link in the top bar opens these files.

For the XML sitemap and the feeds, we extended `@preview/exemel` to `0.3.0`. It now has `sitemap-encode` and `rss-encode` in addition to `atom-encode`. We also added an optional serializer to `thyme` (`feed-content: "full"`). It converts the post content into semantic HTML for feed readers.

The language switch also needed two revisions. The site does not make separate `/en/` and `/de/` URL trees and does not send JavaScript. `#tr(en: [...], de: [...])` emits hidden radio inputs. CSS toggles them with `:root:has(#thyme-lang-de:checked)`. Each branch sets `text.lang`, so the smart quotes and the hyphenation agree with the language. Two bugs appeared early. A blog with one language must not show an `en` widget. And `<title>`, the word counts, and the RSS feeds must not contain hidden spans from the other language. We limited the `<thyme-tr-meta>` queries to each bundle document. Thus a page with one language has no toggle. We also changed `to-plain-text` and `count-words` to read only the primary language branch before they give strings to `exemel`.

= Math, Fonts, and Sidenotes <typography>

Typography and math rendering needed the most work. Almost all our first assumptions were false on at least one engine or font table.

#wide[
  #tablem[
    | *Problem* | *Cause* | *Solution* |
    | :--- | :--- | :--- |
    | Inline $F(e)$ became $F lr((e), size: #135%)$ | `NewCMMath` and `Latin Modern Math` have no base glyph in `MathVariants`. The stretching starts at `size1` (`0.88em`) | We changed the prose and the math to _STIX Two Text_ + _STIX Two Math_. Slot `0` is the unstretched glyph |
    | The browser `#smallcaps[...]` fell back or disappeared | The static _STIX Two_ subset of Google Fonts removes `387` `smcp` and `366` `c2sc` glyphs. Also, `local()` found old fonts in the operating system | We removed `local()` from `@font-face` and we host the `.woff2` files from upstream `stipub/stixfonts` (`v2.13b171`) |
    | WebKit put `(` too low on $F(e)$ and added space to $d^*$ | Typst puts `(...)` into `math.lr` (`stretchy="true"`). It also exports a single `*` in a script as `<mo>*</mo>` | We added two syntactic `show` rules to `with-html-math`, for a single-line automatic `lr` and for single script operators |
    | A click on a mobile sidenote changed the line breaks of the paragraph | An inline box inside `<p>` changed the line breaks when it opened | The sidenote body stays out of flow until it opens as a full-width block between lines |
    | In the PDF, the sidenote underline was on the baseline of the prose | The OpenType `sups` glyphs in _STIX Two Text_ keep `baseline = 0pt`. The outer `show link` rules underlined the complete link | We use `super(typographic: false, ...)` on the in-prose markers and we skip sidenote links in the outer `show link` rules |
  ]
]

We tested Kleene fixed-point formulas in Firefox, Chromium, and WebKit. The tests showed the difference between the TeX TFM metrics and the OpenType `MATH` tables:

#theorem[Kleene's Fixed-Point Theorem][
  Let $(D, subset.eq.sq, bot)$ be a pointed $omega$-CPO and $F : D -> D$ a Scott-continuous functional. Then $"lfp"(F) = union.sq.big_(n = 0)^infinity F^n (bot)$, with $F(d^*) = d^*$ and $F(e) subset.eq.sq e ==> d^* subset.eq.sq e$.
]

#proof[
  We inspected six math fonts with `fontTools`. The inspection showed why the Computer Modern clones have problems in browser MathML. `NewCMMath` has a jump in `MathVariants` on parentheses. It also keeps Knuth's 1978 narrow advance width of `cmmi10` on the italic `𝐹` (`0.643em` advance against `0.749em` ink right edge). TeX corrects this width with its italic correction rules. Browsers use the layout of W3C MathML Core. _STIX Two Math_ has modern advance widths and the `MathItalicsCorrection` and `BottomRightMathKern` tables (`-0.160em`). Thus $F_0^n$ and $F(d^*)$ have correct spacing.

  The other WebKit problems came from the Typst MathML emitter, not from the font. Typst pairs `(...)` into `math.lr` automatically. Thus every inline call gave `<mo stretchy="true">`. We did not measure boxes. (`measure()` cannot see the font rendering of a browser.) Instead, `with-html-math` reads the math AST as syntax. An automatic `math.lr` becomes plain `lr` if it has no fractions, matrices, roots, multiline nodes, or big operators with limits. Thus $F(e)$ does not stretch, but $F(union.sq.big_(n >= 0) d_n)$ still grows. A second rule puts single non-alphanumeric script glyphs into `math.class("normal", ...)`. Thus `$d^*$` emits `<mi>∗</mi>` without binary operator spacing.
]

One more problem occurred only in the paged PDF output (`just watch posts/impli.typ` and `docs/manual.pdf`). On the web, a sidenote marker is a serif superscript with a thin underline below the digit. In the PDF, the underline was on the baseline of the main text. The default `super(..., typographic: true)` uses the OpenType `sups` feature of _STIX Two Text_. This feature puts a higher glyph in the normal em-box but does not move `text.baseline`. We changed the paged marker to `super(typographic: false, size: 0.7em, baseline: -0.42em, underline(...))`. We also added metadata to sidenote links, so the outer `show link` rules do not change them. Now the underline is directly below the superscript in the PDF too.

= Build Results and Session Time <numbers>

#recipe[Measurements][
  The compile times below are measurements from the sandbox#sidenote[The total time is the sum of the generation time of all agent answers in this session. The compile times and the module counts are direct measurements.]. The session time is the total of all agent answers:

  #grid-table[
    | *Metric* | *Value* | *Notes* |
    | --- | --- | --- |
    | Total answer generation time | `31 min 11 s` | All answers in this session, combined |
    | Design and audit passes | `18` turns | First blog draft, `thyme` core split, 17-item audit, MathML and font pass, PDF sidenote fix |
    | Full `glob` bundle compile | `about 0.48 s` | 7 posts, `/tags/` pages, `.typ` sources, `sitemap.xml`, `robots.txt`, `rss.xml`, `atom.xml` |
    | Single-post compile | `about 75 ms` | Standalone HTML or paged A4 preview (`typst watch posts/impli.typ`) |
    | `thyme` source modules | `16` files | `7` core SSG modules (`src/*.typ`), `8` `blog` modules (`src/blog/*.typ`), and `lib.typ` |
    | Reference manual | `28` pages | Made from the doc-comments with `@preview/tidy:0.4.3` (`docs/manual.pdf`) |
  ]
]
