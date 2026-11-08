#import "@preview/thyme:0.1.0": *
#import blog: *

#show: post.with(
  title: [New Rabbit Holes Await],
  subtitle: [Declarative Nix systems, self-hosted Kubernetes infrastructure, and a hydra of future sidequests],
  author: "Basil Feitknecht",
  monograph: "bkf6",
  created: datetime(year: 2026, month: 3, day: 25),
  modified: datetime(year: 2026, month: 10, day: 27),
  summary: [Next projects on the list after finishing `impli`, from declarative Nix setups and self-hosted clusters to Typst HTML and new languages.],
  tags: ("nix", "infra", "pl", "ideas"),
)

After having been fully absorbed by the completion of the #link("https://github.com/bfeitknecht/impli")[`impli`] project#sidenote[See @impli for the full seven-month chronicle of bringing the Haskell `IMP` interpreter to WebAssembly.], I've suddenly gained a gaping hole waiting to be filled with more interesting sidequests. But as the old German adage _the torture of a choice_ goes, I find myself at a crossroads. There's simply too many things I want to do. To track my ideas and progress (hopefully soon), I've jotted down the most central ones here.

- Declarative cross-platform system with everything from hardware options and GUI customization to packages and their configuration in Nix. Allows me to never have to complain about package managers again, and if any one machine ever goes kaput, the whole state can be restored with just one or two commands. In particular, the following aspects stand out:
  - Geared-out #link("https://neovim.io")[Neovim] (by the way) IDE.
  - Perfect #link("https://zellij.dev")[Zellij] setup with plugins and all that jazz.
  - Terminal file finder. Also #link("https://github.com/alexpasmantier/television")[Television]. Just the best and most polished shell experience.
- Absolutely over-engineered web server infrastructure with Kubernetes cluster and #link("https://traefik.io")[Traefik] proxy. Would serve as base for smaller, future projects (so many ideas, see below) that require a domain with some open ports:
  - Own Git instance hosting. Currently eyeing #link("https://codeberg.org/forgejo/forgejo")[Forgejo], although the concept of #link("https://jj-vcs.dev")[Jujutsu] seems very intriguing too. #link("https://tangled.org")[Tangled] also gives me the hots with their knots.
  - Markdown-based SSG blog. Probably with #link("https://gohugo.io")[Hugo]. The concepts of #link("https://tadiweb.com")[Tadiweb] or #link("https://prose.sh")[`prose.sh`] are also interesting. Definitely excited for more stable #link("https://typst.app")[Typst] HTML export because that's just like MD and (La)TeX had a baby that was somehow infinitely more sexy than both of them on their own. Especially (La)TeX -- ugh, how much I hate that archaic technology.#sidenote[Update (October 2026): this blog now runs directly on Typst's `html` and `bundle` export via `thyme` and its `blog` preset (including Tadi Web `.typ` source links) -- see @designing-thyme.]
  - Clock. Honestly, how is it that there is no clean and ad-free website for displaying just one big damn clock and nothing else? Have to do everything by myself.
  - Own file server with #link("https://github.com/9001/copyparty?tab=readme-ov-file#identity-providers")[CopyParty]. Might or might not also look into pirating and torrenting with this one.
  - Personal website. Something like anything from #link("https://mschf.com")[Mschf]. Design elements of #link("https://freitag.ch")[Freitag] are also very nice.
  - My own corner of the internet, like #link("https://neocities.org")[Neocities].
- More programming languages! Specifically, the ones below:
  - #link("https://elm-lang.org")[Elm] for nice functional frontend development.
  - #link("https://go.dev")[Go], because it's ubiquitous and my friend likes it a lot. Also, the concurrency is supposedly very nice.
  - #link("https://ziglang.org")[Zig] is just really sexy. Low-level and modern, the way we love it.
  - #link("https://vlang.io")[V] -- simple and super-fast compilation? Sounds interesting.
  - #link("https://odin-lang.org")[Odin] -- I like the approach to its development, which has some far-reaching, smart design decisions.
  - #link("https://pkl-lang.org")[Pkl], if I can find a use case. Not sure that's possible, but the concept seems really cool.
  - #link("https://www.lua.org")[Lua] for its Brazilian charm. Perhaps develop my own Neovim plugin with it? Or embed its VM somewhere?
  - One of these fancy array programming languages.
- Something with #link("https://opentui.com")[OpenTUI], like they did at #link("https://terminal.shop")[`terminal.shop`]. Not sure what, though.
- Web app clone of Procreate. This app is so intuitive and pragmatic to me, but it's a shame how limited and unhackable it is.
- Finally fix everything wrong with my #link("https://obsidian.md")[Obsidian] setup. Probably just implement the FLAP system or tinker up my own secret sauce that's a bit simpler and less meta?
- CV (of course in Typst). Best-case scenario, can link to all of the above.

Yeah, that's about it. Lucky me for being so interested in all of this. It's like with every single finished project, there pop up two more. Like the Lernean Hydra. If only I could find the time (or rather the motivation) to just do everything. One thing I've noticed that helps is to simply get my hands dirty and start somewhere. Trying to find the optimal approach and perfect way to do something before that is pointless.

Check back on me in half a year, and let's see what I've cooked up by then. Life would be boring without distractions.
