#import "@preview/thyme:0.2.0": *
#import blog: *

#show: post.with(
  title: [The Perfect Prompt],
  subtitle: [A `starship` spec where every character earns its place],
  author: "Basil Feitknecht",
  monograph: "bkf7",
  created: datetime(year: 2026, month: 11, day: 24),
  // summary: [My shell prompt as a spec: `user@host:cwd` you can paste into `scp`, one `#` per shell level, and a git status that says everything in a few ASCII characters. Plus the three config bugs that hid half of it.],
  tags: ("shell", "cli", "tools"),
)

The terminal is the door to your computer. It's where you should be most comfortable. Under that assumption, the shell is your swiss army knife.
And since we should measure the quality of a tool by its aesthetics, making the prompt look good is of utmost importance.
Despite the veiled sarcasm, in this post I hope to present an argument for my specification of *The Perfect Prompt* and its actual benefit in functionality.

```
alice@wonderland:~/Projects         # [1] (master *1+1 >1<2) 2026-11-24T00:47:08+0100
%
```

== `$USER@$HOST:$PWD`

The very first part conveys all the important information, with `$HOME` shortened to `~` in the local path
This is the exact syntax of a remote path in `scp`, `rsync` and friends. Double-click to copy, and it's a valid argument in your next command.

== `#SHLVL`

Since the hash symbol starts comments in most all shell languages, it acts as a natural sort of separator. Repeating it the amount of your nesting depth makes accidental total exit out rare.

== Status and Time

Two things money can't buy. It's just nice to see the error code of the previous command. And so often I'm in need of the current ISO date time.

== Git

Inside a repository, the prompt gets a git segment in parentheses. Three `starship` modules fill it, in this order: `git_branch`, `git_state`, `git_status`. Outside a repository, the segment and its parentheses disappear.

```
(branch STATE n/m status ahead-behind)
```

Every symbol is plain ASCII and every count is shown. It reads the same in any font and any terminal.

=== Branch

`git_branch` shows the name of the branch and nothing else. No symbol, no remote name. A detached `HEAD` shows as `HEAD`.

#tablem[
  | *Case* | *Prompt* |
  | :--- | :--- |
  | on a branch | `(master =)` |
  | no upstream | `(feature)` |
  | detached `HEAD` | `(HEAD)` |
]

=== State

`git_state` shows an operation in progress, in capitals. Rebase and `am` also show how far they are. A half-finished rebase cannot hide.

#tablem[
  | *Operation* | *Word* | *Prompt* |
  | :--- | :--- | :--- |
  | `git merge` | `MERGE` | `(master MERGE !1 >1)` |
  | `git rebase` | `REBASE` | `(HEAD REBASE 1/2 !1)` |
  | `git cherry-pick` | `CHERRY` | `(master CHERRY !1 >1)` |
  | `git revert` | `REVERT` | `(master REVERT !1 >2)` |
  | `git bisect` | `BISECT` | `(HEAD BISECT)` |
  | `git am` | `AM` | `(master AM 1/1 >2)` |
  | `am` or rebase (git cannot tell) | `AM/REBASE` | rare |
]

=== Status

`git_status` shows the work tree first, then the relation to the upstream. Each symbol carries its count.

#tablem[
  | *Symbol* | *Meaning* | *Prompt* |
  | :--- | :--- | :--- |
  | `!`_n_ | _n_ files with conflicts | `(master MERGE !1 >1)` |
  | `$`_n_ | _n_ stashes | `(master $2 =)` |
  | `-`_n_ | _n_ files deleted | `(master -1 =)` |
  | `~`_n_ | _n_ files renamed | `(master ~1 =)` |
  | `*`_n_ | _n_ files modified | `(master *1 =)` |
  | `+`_n_ | _n_ files staged | `(master +1 =)` |
  | `%`_n_ | _n_ files untracked | `(master %1 =)` |
  | `=` | up to date with the upstream | `(master =)` |
  | `>`_n_ | _n_ commits ahead | `(master >1)` |
  | `<`_n_ | _n_ commits behind | `(master <1)` |
  | `>`_a_`<`_b_ | diverged: _a_ ahead, _b_ behind | `(master >1<1)` |
]

The order in the table is the order in the prompt. It is the default order of `$all_status` in `starship`. A busy repository looks like this:

```
(master $2*1+1%1 =)
```

Two stashes, one modified file, one staged file, one untracked file, up to date. A file that is staged and then modified again counts in both `+` and `*`. Without an upstream, the ahead-behind part is empty.

The ASCII symbols are not only for looks. The `starship` defaults for deleted and renamed are `✘` and `»`, and a font without them shows a box.

=== Config

This is the git part of `starship.toml`:

#zebraw(
  ```toml
  right_format = "($shlvl)( $status)( \\($git_branch( $git_state)($git_status)\\))( ${custom.time})"

  [git_branch]
  format = "$branch"

  [git_state]
  format = "$state( $progress_current/$progress_total)"
  rebase = "REBASE"
  merge = "MERGE"
  revert = "REVERT"
  cherry_pick = "CHERRY"
  bisect = "BISECT"
  am = "AM"
  am_or_rebase = "AM/REBASE"

  [git_status]
  format = "( $all_status)( $ahead_behind)"
  up_to_date = "="
  ahead = ">${count}"
  behind = "<${count}"
  diverged = ">${ahead_count}<${behind_count}"
  conflicted = "!${count}"
  stashed = "\\$${count}"
  deleted = "-${count}"
  renamed = "~${count}"
  modified = "*${count}"
  staged = "+${count}"
  untracked = "%${count}"
  ```,
)

The `( ... )` groups in a format string drop out when everything inside them is empty. That is why a clean repository with no upstream shows only `(feature)`, without trailing spaces.

== Nitty Gritty

Nix, Home Manager, starship, omni, zsh, nushell




// == The character
//
// The line you type on starts with `%` after a successful command and `X` after a failed one. `%` is the classic `zsh` prompt sign; `X` is loud on purpose. In Zed's terminal and in Rex, the first line disappears and only the character is left, because those already show where I am.
//
// == `#` per shell level
//
// The right side starts with one `#` for every level of `$SHLVL`. A login shell shows `#`, a `nix develop` inside it `##`, a `nix-shell` inside that `###`. I live in dev shells, and before this I regularly typed `exit` once too often and closed the whole terminal. Now I can count before I leave.
//
// == Status
//
// When the last command failed, its exit code follows in brackets: `[1]`, `[127]`, `[130]` for a `Ctrl-C`. The `X` says _that_ something failed, the code says _how_.
//
// == The git part
//
// The git segment is in parentheses: the branch, then any operation in progress, then the status. Every symbol is plain ASCII and every count is shown, so it reads the same in any font and any terminal:
//
// #table(
//   columns: 3,
//   table.header[Symbol][Meaning][Example],
//   [`=`], [up to date with the upstream], [`(master =)`],
//   [`>`#emph[n]], [#emph[n] commits ahead], [`(master >2)`],
//   [`<`#emph[n]], [#emph[n] commits behind], [`(master <2)`],
//   [`>`#emph[a]`<`#emph[b]], [diverged: #emph[a] ahead, #emph[b] behind], [`(master >1<2)`],
//   [`+`#emph[n]], [#emph[n] staged], [`(master +3)`],
//   [`*`#emph[n]], [#emph[n] modified], [`(master *1)`],
//   [`%`#emph[n]], [#emph[n] untracked], [`(master %4)`],
//   [`$`#emph[n]], [#emph[n] stashes], [`(master $1)`],
//   [`!`#emph[n]], [#emph[n] conflicts], [`(master !2)`],
// )
//
// An operation in progress shows up in capitals with its progress, so a half-finished rebase cannot hide: `(HEAD REBASE 1/3 !1)`. The others are `MERGE`, `REVERT`, `CHERRY`, `BISECT`, `AM` and `AM/REBASE`.
//
// == The time
//
// Last on the right is the time in ISO 8601, `2026-11-24T00:47:08+0100`. It is the time the prompt was drawn, so the scrollback doubles as a log of when each command ran. ISO because it sorts, has no locale and carries its own time zone.
//
// == The config
//
// This is the git part as `starship` reads it:
//
// #zebraw(
//   ```toml
//   [git_status]
//   format = "( $all_status)( $ahead_behind)"
//   up_to_date = "="
//   ahead = ">${count}"
//   behind = "<${count}"
//   diverged = ">${ahead_count}<${behind_count}"
//   untracked = "%${count}"
//   stashed = "\\$${count}"
//   conflicted = "!${count}"
//   modified = "*${count}"
//   staged = "+${count}"
//
//   [status]
//   disabled = false
//   format = '\[$status\]($style)'
//
//   [shlvl]
//   disabled = false
//   format = "$symbol"
//   symbol = "#"
//   repeat = true
//   threshold = 1
//   ```,
// )
//
// == Three bugs that were mine
//
// For weeks, a branch that was behind its upstream showed a bare `<` with no count. I was ready to file a bug against `starship`. It was my config:
//
// - `behind` said `<${behind_count}`. But `${behind_count}` and `${ahead_count}` only exist in the `diverged` format; `ahead` and `behind` know only `${count}`. An unknown variable renders as nothing, silently.
// - `stashed` said `$${count}`. In a `starship` format string `$` starts a variable, so a literal dollar sign has to be escaped as `\$`. Unescaped, the format fails to parse and the stash count never shows. This one at least prints a warning, if you look.
// - The status code never showed at all, because the `status` module is _off by default_ in `starship`. The spec said `[ERR]`, the prompt never did.
//
// The lesson is an old one: a spec is only worth something if you test against it. I rendered every case from the table in a scratch repository: up to date, behind, diverged, dirty, stashed, nested shells, a failed command, a rebase with a conflict. Ten minutes, three bugs.
