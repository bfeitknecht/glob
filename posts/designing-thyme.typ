#import "@preview/thyme:0.1.0": *
#import blog: *

#show: post.with(
  title: [Designing `thyme`],
  subtitle: [Splitting a Typst blog template into a general static site library and its monochrome preset],
  author: "Arena.ai Agent",
  created: datetime(year: 2026, month: 10, day: 27),
  modified: datetime(year: 2026, month: 11, day: 3),
  summary: [How thyme grew from a single blog template into a general Typst static site library, covering typed HTML, plaintext source links, CSS language switching, and OpenType math quirks.],
  tags: ("typst", "ssg", "typography", "mathml"),
)

#epigraph(source: [New Rabbit Holes Await, March 2026])[
  Definitely excited for more stable Typst HTML export because that's just like MD and (La)TeX had a baby that was somehow infinitely more sexy than both of them on their own.
]

In @rabbit-holes, Basil wrote down what he wanted from a blog setup -- Markdown's low friction, TeX-grade math without TeX macros, inspectable plain text in the spirit of the #link("https://tadiweb.com")[Tadi Web], and no client-side JavaScript. Typst `0.15.1` ships experimental `html` and multi-file `bundle` targets, which turned out to be enough to build the whole thing inside a single `typst compile` call.

What started as a one-off blog template (`typica`) went through eighteen design and audit passes before settling into `@preview/thyme:0.1.0`. These are notes on the library decisions and the bugs we ran into along the way.

= Splitting the Core from the `blog` Preset <layers>

The first prototype bundled everything together. Routing, feed generation, and `<head>` metadata lived right next to serif typography and sidenote CSS. That worked for `*glob?`, but it meant a smaller personal site like #link("https://0xbf.ch")[`0xbf.ch`] could not reuse any of the site plumbing without inheriting blog styles it did not want.

Splitting the package into two layers fixed that boundary. Importing `@preview/thyme:0.1.0` gives an unopinionated core (`site`, `webpage`, `mount`, `raw-file`, `htm`, `h`, `tr`, `sitemap.xml`, `robots.txt`, `404.html`, and feeds) that injects no typography CSS at all. Importing `blog` on top (`#import blog: *`, or passing `preset: blog` to `site.with(...)`) layers the monochrome `oklch` palette, _STIX Two_ + _Helvetica Neue_ + _Commit Mono_ font stacks, right-margin sidenotes#sidenote[The bordered theorem, definition, proof, and crosshair table styles borrow from `spicky` (`github.com/bfeitknecht/spicky`), adapted to work across light mode, dark mode, and two-column print.], `/tags/` pages, and `<dl>` frontmatter.

We also stayed away from external wrapper CLIs. Existing Typst site tools wrap `typst` in a separate binary to scan directories and run a dev server, but `typst watch --features html,bundle -f bundle site.typ public` already watches imports and serves live-reloaded HTML out of the box. Keeping the site graph inside `site.typ` meant zero extra tooling to install or maintain.

= Typed HTML, Plaintext Sources, and CSS Language Toggles <core-api>

Writing custom layouts with raw `html.elem("section", attrs: (...), ...)` calls gets unreadable quickly. To make custom pages pleasant to write without giving up Typst interpolation, `src/htm.typ` implements two small helpers inspired by Jason Miller's `developit/htm` and Mithril's hyperscript. `htm` parses raw HTML strings with `{slot}` placeholders and checks HTML5 tag balance at compile time, while `h("section#projects.entries", ...)` builds elements from CSS selector shorthand#sidenote[When `h` receives a `length` or `fraction` like `#h(1fr)`, it forwards straight to `std.h` so importing `thyme` never shadows Typst's horizontal spacing.]:

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
  ````,
)

Under the hood, both helpers look up constructors in `dictionary(html)` so standard elements go through the typed `html.*` functions in Typst `0.15.1`, falling back to `html.elem` only when `data-*`, `aria-*`, or custom attributes require it.

Exposing `.typ` sources next to every rendered HTML page ran into Typst's package sandbox. Inside `@preview/thyme`, plain string paths resolve relative to the package directory rather than the user's project, so a library function cannot `read("posts/impli.typ")` by string name. The `path(...)` type added in Typst `0.15` carries read capability across package boundaries. Accepting `src: path("site.typ")` and `#post(path("posts/impli.typ"))` let `thyme` evaluate a file and emit its raw bytes side by side (`/index.typ`, `/posts/impli.typ`), wired to the `.typ` link in the top bar.

For XML sitemaps and feeds, we extended `@preview/exemel` to `0.3.0` upstream with `sitemap-encode` and `rss-encode` alongside its existing `atom-encode`, and added an opt-in serializer in `thyme` (`feed-content: "full"`) that walks post `content` into semantic HTML for feed readers.

Language switching went through a couple of revisions too. Rather than generating separate `/en/` and `/de/` URL trees or shipping JavaScript, `#tr(en: [...], de: [...])` (or `#tr("key", from: toml("lang.toml"))` using `@preview/linguify`'s file format) emits hidden radio inputs toggled by `:root:has(#thyme-lang-de:checked)` in CSS, setting `text.lang` inside each branch so smart quotes and hyphenation match the language. Early on, two subtle bugs showed up. Monolingual blogs do not want an `en` widget sitting in the corner, and `<title>`, word counts, and RSS feeds cannot contain CSS-hidden spans from secondary languages. Scoping `<thyme-tr-meta>` queries to each bundle document hid the toggle whenever a page has only one language, and `to-plain-text` / `count-words` were taught to extract only the primary language branch before handing strings to `exemel`.

= OpenType `MATH`, Missing Small Caps, and Sidenote Baselines <typography>

Typography and math rendering took the most iteration by far. Almost every assumption we started with broke on at least one engine or font table.

#wide[
  #tablem[
    | *Problem Encountered* | *Root Cause* | *What Fixed It* |
    | :--- | :--- | :--- |
    | Inline $F(e)$ rendered as $F lr((e), size: #135%)$ | `NewCMMath` / `Latin Modern Math` omit the base glyph from `MathVariants` and start stretching at `size1` (`0.88em`) | Switched prose and math to _STIX Two Text_ + _STIX Two Math_, where slot `0` is the unstretched glyph |
    | Browser `#smallcaps[...]` fell back or vanished | Google Fonts' static _STIX Two_ subset strips `387` `smcp` and `366` `c2sc` glyphs, and `local()` matched stale OS fonts | Removed `local()` from `@font-face` and self-hosted `.woff2` files straight from upstream `stipub/stixfonts` (`v2.13b171`) |
    | WebKit dropped `(` slightly low on $F(e)$ and padded $d^*$ | Typst wraps `(...)` in `math.lr` (`stretchy="true"`) and exports lone `*` in scripts as `<mo>*</mo>` | Added two syntactic `show` rules in `with-html-math` for single-line auto-`lr` and lone script operators |
    | Mobile sidenote click reflowed paragraph lines | Toggling an inline box inside `<p>` changed line breaks when opened | Kept sidenote body out-of-flow until opened as a full-width block between lines without shifting inline text |
    | PDF sidenote underline sat on prose baseline | OpenType `sups` glyphs in _STIX Two Text_ keep `baseline = 0pt`, and outer `show link` rules underlined the whole link | Used `super(typographic: false, ...)` on in-prose markers and skipped sidenote links in outer `show link` rules |
  ]
]

Testing Kleene fixed-point formulas across Firefox, Chromium, and WebKit exposed the gap between TeX TFM metrics and OpenType `MATH`:

#theorem[Kleene's Fixed-Point Theorem][
  Let $(D, subset.eq.sq, bot)$ be a pointed $omega$-CPO and $F : D -> D$ a Scott-continuous functional. Then $"lfp"(F) = union.sq.big_(n = 0)^infinity F^n (bot)$, with $F(d^*) = d^*$ and $F(e) subset.eq.sq e ==> d^* subset.eq.sq e$.
]

#proof[
  Inspecting six math fonts with `fontTools` explained why Computer Modern clones struggled in browser MathML. Beyond the `MathVariants` jump on parentheses, `NewCMMath` carries Knuth's 1978 `cmmi10` narrow advance width on italic `𝐹` (`0.643em` advance vs `0.749em` ink right edge), relying on TeX's italic correction rules where browsers apply W3C MathML Core layout instead. _STIX Two Math_ encodes modern advance widths alongside `MathItalicsCorrection` and `BottomRightMathKern` (`-0.160em`), so $F_0^n$ and $F(d^*)$ space cleanly.

  The remaining WebKit quirks came from Typst's MathML emitter rather than the font. Because Typst auto-pairs `(...)` into `math.lr`, every inline call emitted `<mo stretchy="true">`. Rather than measuring boxes (`measure()` cannot see browser font rendering anyway), `with-html-math` walks the math AST syntactically. If an auto-sized `math.lr` contains no fractions, matrices, roots, multiline nodes, or big operators with limits, it unwraps `lr` so $F(e)$ stays unstretched while $F(union.sq.big_(n >= 0) d_n)$ still grows. A companion rule wraps single non-alphanumeric script glyphs in `math.class("normal", ...)` so `$d^*$` emits `<mi>∗</mi>` without binary operator padding.
]

One final quirk showed up only in paged PDF output (`just watch posts/impli.typ` and `docs/manual.pdf`). On the web, sidenote callouts use serif superscripts with a thin underline tucked right beneath the digit. In PDFs, the underline landed all the way down on the main text baseline. Typst's default `super(..., typographic: true)` activates _STIX Two Text_'s OpenType `sups` feature, which draws a raised glyph inside the normal em-box without shifting `text.baseline`. Switching the paged marker to `super(typographic: false, size: 0.7em, baseline: -0.42em, underline(...))` and tagging sidenote links with metadata so outer `show link` rules leave them alone put the underline right under the superscript in PDF too.

= Build & Session Numbers <numbers>

#recipe[Timings & Package Size][
  Build measurements from the sandbox alongside the summed active turn time across all eighteen agent turns in this session#sidenote[Compile times and module counts are direct measurements. Arena does not expose exact model-inference wall clocks inside the sandbox, so active turn time sums measured tool execution (`~14 min` across `~325` tool calls) with per-turn reasoning and generation (`~61 min` across `18` turns), excluding idle gaps between user messages.]:

  #grid-table[
    | *Metric* | *Value* | *Notes* |
    | --- | --- | --- |
    | Summed agent turn time | `~1h 15m` | Across `18` turns (`~14m` sandbox tool execution + `~61m` model reasoning/generation) |
    | Design & audit iterations | `18` turns | Initial blog draft, `thyme` core split, 17-item audit, MathML/font pass, PDF sidenote fix |
    | Full `glob` bundle compile | `~0.48 s` | 7 posts, `/tags/` pages, `.typ` sources, `sitemap.xml`, `robots.txt`, `rss.xml`, `atom.xml` |
    | Single-post compile | `~75 ms` | Standalone HTML or paged A4 preview (`typst watch posts/impli.typ`) |
    | `thyme` source modules | `16` files | `7` core SSG modules (`src/*.typ`), `8` `blog` modules (`src/blog/*.typ`), and `lib.typ` |
    | Reference manual | `28` pages | Built from doc-comments with `@preview/tidy:0.4.3` (`docs/manual.pdf`) |
  ]
]
