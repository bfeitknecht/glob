#import "@preview/thyme:0.1.4": *
#import blog: *

// DRAFT. Not mounted in site.typ. Reachable by URL only after a release.
#show: post.with(
  title: [AGENTS],
  subtitle: [The rules I give every coding agent in my workspace],
  author: "Basil Feitknecht",
  created: datetime(year: 2026, month: 11, day: 16),
  summary: [Write in Simplified Technical English. Expose a Nix dev shell. Use `just` as the one command runner. Pick modern tools. Format and lint in CI. Keep the interface small.],
  tags: ("agents", "workflow", "nix", "tooling"),
)

I work with coding agents every day. They read my repositories, run my commands, and write my commits. An agent does not remember the last session. It reads what is in the repository. So the repository must say what I want. This post collects the rules that I put into every `AGENTS.md`.

= Write in Simplified Technical English <ste>

All prose follows #link("https://www.asd-ste100.org")[ASD-STE100]. That includes comments, docs, commit messages, and pull request bodies.

STE has a small vocabulary and short sentences. One sentence gives one instruction. Use the active voice. Do not use idioms.

The reason is simple. An agent writes a lot of text, and I read all of it. Short, plain sentences are fast to read and hard to misread. A non-native reader gets the same meaning. A second agent that reads the text later gets the same meaning too.

= Assume Nix, expose a dev shell <nix>

A repository that needs tools has a `flake.nix` with a dev shell. `nix develop` gives the exact compiler, formatter, and CLI versions that CI uses.

The agent must not install tools globally. It must not tell me to `brew install` something. If a tool is missing, it goes into the dev shell. Then "it works on my machine" means "it works in the shell", and the shell is the same everywhere.

= One command runner: `just` <just>

Nix pins the tools. `just` gives them names. Every repository has a `justfile` with the same verbs:

- `just` lists the recipes.
- `just fmt` formats the tree. `just fmt --check` only reports. CI uses that form.
- `just check` runs everything that CI runs: format check, lint, tests, build.
- `just serve` starts a local preview, if the project has one.
- `just image` builds the container image locally.
- `just release` validates the version, then tags and pushes. `just release --check` only validates.

The verbs are the interface. I do not need to remember if a project uses `cargo`, `uv`, `typst`, or `hugo`. An agent does not need to guess either. A recipe that CI also runs cannot drift away from CI.

= Use modern, good tools <tools>

Pick the tool that is fast, strict, and maintained:

- Python: `uv` for environments and scripts, `ruff` for format and lint.
- Rust: `cargo fmt` and `clippy` with warnings as errors.
- Typst: `typstyle` with a pinned line width.
- Containers: multi-arch builds with `docker buildx`.

Pin the version of every tool. A formatter that changes between versions makes noise diffs.

= Format and lint in CI, always <ci>

Every repository has a CI job that runs `just fmt --check` and the linter. The job fails on a diff. No exceptions for "small" repositories.

This is the cheapest guard against agent drift. An agent can forget the formatter. CI does not forget.

= Simple UI, UX, and DX <simple>

Make the smallest interface that does the job. One page instead of three. One command instead of a flag matrix. One config file instead of four.

This rule applies to the developer experience too. A new contributor, human or agent, runs `nix develop` and then `just`. After that, everything is one verb away.

= The short version <summary>

Write plain English. Pin tools in Nix. Name commands in `just`. Format and lint in CI. Keep it small.
