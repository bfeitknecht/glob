#import "@preview/thyme:0.2.0": *
#import blog: *

// DRAFT. Not mounted in site.typ. Reachable by URL only after a release.
#show: post.with(
  title: [AGENTS],
  subtitle: [The rules I give every coding agent in my workspace],
  author: "Basil Feitknecht",
  created: datetime(year: 2026, month: 11, day: 16),
  summary: [Write in Simplified Technical English. Put the result first. Ask before you guess. Never touch secrets or destroy without a "yes". Solve it the simple way. Get every tool from a Nix flake. One tool for each task.],
  tags: ("agents", "workflow", "nix", "tooling"),
)

I work with coding agents every day. They read my repositories, run my commands, and write my commits. An agent does not remember the last session. It reads what is in front of it. So I give every agent the same file. My system config installs it as `AGENTS.md` for OpenCode and as `CLAUDE.md` for Claude Code. A project's own `AGENTS.md` adds to it and wins where the two differ.

The file has one main idea: there is one way to do each task. The agent uses the tool that the file names. It does not pick another.

= How to talk to me <talk>

Long answers cost me effort. So the rules for text are strict.

All prose follows #link("https://www.asd-ste100.org")[ASD-STE100] Simplified Technical English. That includes answers, comments, commit messages, and docs. Short sentences. One instruction per sentence. Active voice. A non-native reader gets the same meaning, and so does the next agent that reads the text.

No LLM speak. No praise, no filler, no "Great question", no "Let me", no summary of what comes next. No emoji. No "it is not X, it is Y" contrast: say what it is.

The answer has a fixed shape:

- The result comes first. Then the important details as a short list. Then stop.
- Headings and lists only when they help to scan. Tables for comparisons.
- When the agent needs me to act (a login, a secret, a decision, a button in a UI), it says so in one line at the top.
- Commands for me to type are in nushell syntax.
- The agent reports what it ran and what failed. It does not claim a success that it did not check.

When the agent is not sure what I want, it asks at once. One short question, 2 to 4 options, and its recommendation. A question costs me ten seconds. The wrong thing, built well, costs me an hour.

= Safety <safety>

Some actions are hard to undo. The agent does not do them on its own.

- It does not read secrets: no `sops -d`, no `.env`, no key files, no token files, no `~/.ssh`, no `~/.gnupg`. If a task needs a secret, it asks me for it.
- It does no destructive action without my explicit "yes" in this session. That covers deleted files and branches, `git push --force`, `git reset --hard`, history rewrites, `rm -rf`, dropped data, and deleted cloud or cluster resources.
- It does not commit, push, tag, or open a pull request unless I ask.
- It does not change the system configuration. All my machines are declared in one Nix flake: NixOS, nix-darwin, and Home Manager. If a tool or a setting is missing, the agent tells me the change to make there. It does not apply the change.

= Keep it simple <simple>

Solve the problem the simple way, with the least new code. Read the code first, and find every place that the change must reach. Then take the first option that fully works, in this order:

+ It is not needed at all.
+ The project already has it.
+ The standard library has it.
+ A dependency that the project already has does it.
+ The minimum new code.

Deleting code beats adding code. No abstraction, wrapper, option, or config "for later". Three similar lines are better than a premature helper. Fix a bug at its root, once, and check all callers first.

Be lazy about the solution, not about the change: finish it, test it, clean up. And some code is never "simple" to cut: input checks at trust boundaries, error handling that prevents data loss, and security.

= Keep things clean <clean>

- Scratch work goes in `/tmp`, in a new directory for each task (`mktemp -d`). Never in `$HOME`, never in a repository.
- The agent writes only inside the project it works on. Build output and caches go in paths that `.gitignore` lists.
- A dependency must earn its place. The standard library comes first. The agent says why it adds one.
- The agent cleans up after itself. It deletes its scratch directories, stops the processes and terminal sessions it started, and deletes its own branches after the merge. It asks before it deletes anything that it did not make.
- Languages, language servers, formatters, and tasks that only one project uses go in that project: the tools in its `flake.nix`, the editor settings in its `.zed/settings.json`. The global config stays small.

= Tools come from Nix flakes <nix>

Every project gets its tools from its own `flake.nix` (`devShells.default`) and `flake.lock`. `direnv` loads them with `use flake` in `.envrc`. All three files are committed. If a project has no flake and needs tools, the agent first writes a minimal one.

The agent never installs a tool globally: no `brew install`, `npm -g`, `pip install`, `cargo install`, `go install`, `curl … | sh`, or `apt`, and no edits to shell profiles. For a tool that one command needs, it runs `nix run nixpkgs#<tool> -- …`. It finds a package with `nix search nixpkgs <name>`. If `nix` is not available, the agent says so and stops.

So "it works on my machine" means "it works in the shell". The shell is the same on every machine and in CI.

= Defaults <defaults>

One tool for each task:

#tablem[
  | *Task* | *Use* |
  | :--- | :--- |
  | Search text, find files | `rg`, `fd` |
  | JSON, YAML | `jq`, `yq` |
  | Version control | `git` |
  | GitHub, Forgejo, GitLab | `gh`, `tea`, `glab` |
  | Python | `uv` (`pyproject.toml` and `uv.lock`), `ruff` for lint and format, `ty` for types |
  | JavaScript, TypeScript | `bun` for new projects, else the package manager whose lock file exists. TypeScript `strict` |
  | Rust | `cargo`, clean under `clippy` and `rustfmt` |
  | Nix | `nixfmt`, flakes only: no channels, no `nix-env` |
  | Shell scripts | POSIX `sh` or `bash` with `set -euo pipefail`, clean under `shellcheck` |
  | Secrets in repositories | `sops` with age, encrypt only |
  | Containers | `docker` with OrbStack on macOS, `podman` on Linux |
  | Docs and papers | Typst |
]

Before the agent says it is done, it formats and lints with the project's tools and runs the tests that exist.

= My system <system>

The agent also gets a short map of my setup, so it does not have to guess:

- Two machines: a MacBook on nix-darwin, and a NixOS VM in my cluster that is my main dev box. Tailscale connects them.
- Long-running processes (servers, watchers, builds that take minutes) go in a #link("https://www.superlogical.com/rex")[Rex] session, not in the background of the agent's shell. Rex also reaches my other machine. The agent runs, watches, and types into sessions there as if they were local, instead of one-shot `ssh` commands.
- My interactive shell is nushell, my login shell is zsh. The agent's own commands run in bash, and that is fine. The commands it writes for me are nushell.
- My shell history is in atuin. To find how I did something before, the agent runs `atuin search --cmd-only <words>`, read only.
- All repositories are in `~/Projects/<name>`.

= The short version <summary>

Write plain English. Result first. Ask, do not guess. No secrets, nothing destructive without a "yes". The least code that works. Every tool from a Nix flake. One tool for each task.
