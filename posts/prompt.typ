#import "@preview/thyme:0.2.0": *
#import blog: *

#show: post.with(
  title: [The Perfect Prompt],
  subtitle: [A `starship` specification where every character earns its place],
  author: "Basil Feitknecht",
  monograph: "bkf7",
  created: datetime(year: 2026, month: 11, day: 24),
  summary: [Superlative of opinionated customization with good basis and better quality of life nicities. ASCII only characters for maximum compatibility, `user@host:cwd` you can paste into `scp`, one `#` per shell level (so you know where you're at), and git status with everything you need.],
  tags: ("shell", "cli", "tools"),
)

The terminal is the door to your computer. It's where you should be most comfortable. Under that assumption, the shell is your swiss army knife.
And since we should measure the quality of a tool by its aesthetics, making the prompt look good is of utmost importance.
Despite the veiled sarcasm, in this post I hope to present an argument for my specification of *The Perfect Prompt* and its actual benefit in functionality.

```
alice@wonderland:~/Projects                    # [1] 2026-11-22T09:41:00+0100
%
```

== `$USER@$HOST:$PWD`

The very first part conveys all the important information, with `$HOME` shortened to `~` in the local path
This is the exact syntax of a remote path in `scp`, `rsync` and friends. Double-click to copy, and it's a valid argument in your next command.

== `#SHLVL`

Since the hash symbol starts comments in most all shell languages, it acts as a natural sort of separator. Repeating it the amount of your nesting depth makes accidental system exit rare.

== Exit Code and Date and Time

Two things money can't buy. It's just nice to see the error code of the previous command. And so often I'm in need of the current ISO date time.

== Git

This is arguably the most important part of the prompt. It quickly conveys everything to know about the repository on hand.
Every symbol is plain ASCII and every count is shown. It reads the same in any font and any terminal.
```
(branch STATE n/m status ahead-behind)
```

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

`git_state` shows an operation in progress, in capitals (to draw attention). Rebase and `am` also show how far they are. A half-finished rebase cannot hide.

#tablem[
  | *Operation* | *Word* | *Prompt* |
  | :--- | :--- | :--- |
  | `git merge` | `MERGE` | `(master MERGE !1 >1)` |
  | `git rebase` | `REBASE` | `(HEAD REBASE 1/2 !1)` |
  | `git cherry-pick` | `CHERRY` | `(master CHERRY !1 >1)` |
  | `git revert` | `REVERT` | `(master REVERT !1 >2)` |
  | `git bisect` | `BISECT` | `(HEAD BISECT)` |
  | `git am` | `AM` | `(master AM 1/1 >2)` |
  // | `am` or rebase (git cannot tell) | `AM/REBASE` | rare |
]

=== Status

`git_status` shows the work tree first, then the relation to the upstream. Each symbol carries its count.

#tablem[
  | *Symbol* | *Meaning* | *Prompt* |
  | :--- | :--- | :--- |
  | `!n` | `n` files with conflicts | `(master MERGE !1 >1)` |
  | `$n` | `n` stashes | `(master $2 =)` |
  | `-n` | `n` files deleted | `(master -1 =)` |
  | `~n` | `n` files renamed | `(master ~1 =)` |
  | `*n` | `n` files modified | `(master *1 =)` |
  | `+n` | `n` files staged | `(master +1 =)` |
  | `%n` | `n` files untracked | `(master %1 =)` |
  | `=` | up to date with upstream | `(master =)` |
  | `>n` | `n` commits ahead | `(master >1)` |
  | `<n` | `n` commits behind | `(master <1)` |
  | `>a<b` | diverged: `a` ahead, `b` behind | `(master >1<1)` |
]

The order in the table is the order in the prompt. It is the default order of `$all_status` in `starship`.
A busy repository looks like below.

```
(master $1*1+1%1 >1<1)
```

One stash, one modified, one staged, one untracked, one ahead, one behind. A file that is staged and then modified again counts in both `+` and `*`. Without an upstream, the ahead-behind part is empty.

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

== Transience, Compactness, Symbol

The best prompt is one you barely notice. Because of that it is transient and compact in the places it can be. Currently only Nushell supports transient prompts. That means it collapses to only the prompt symbol on running a command. Same for the right side. Less visual noise, less distraction.
On Nushell Vi mode is used. In insert mode the symbol is `:`, in normal mode it's `$`. In Zsh the symbol is the classical `%` and a sleek `X` on failure.

```
%                                                                           #
```

Isn't this simply so super sexy?


// make flowchart diagram of prompt build up
