#import "@preview/thyme:0.1.0": *
#import blog: *

#show: post.with(
  title: [Yak Shaving Utensils & Co.],
  subtitle: [Battle-tested terminal tools, structured shells, and macOS essentials],
  author: "Basil Feitknecht",
  monograph: "bkf2",
  created: datetime(year: 2026, month: 3, day: 16),
  modified: datetime(year: 2026, month: 10, day: 27),
  summary: [A field guide to modern CLI replacements, Nushell, terminal multiplexers, and macOS power tools so I never repeat myself again.],
  tags: ("cli", "shell", "macos", "tools"),
)

As you might know, I'm very prone to #link("https://devterms.com/define/yak-shaving")[Yak Shaving]. Another way to put it is to say that I'm keen to find the optimal solution for doing things. While this may seem pointless to many, I must admit I'm glad to have sunk those hours into it. Sometimes the rabbit holes you're digging turn out to be gold mines.

Time and time again, friends have come to me asking for advice in the terminal, shell, or some inescapable editor. And I'm so very happy to provide them with the helping hand holding the guiding light they need. Because of one #link("https://devterms.com/define/dry-(don't-repeat-yourself)")[hydrophobic principle] dear to me, I've compiled here some of the most important recommendations I can make. Have fun, and thank me later.

- If you're only going to try even just one of these recommendations, let it be #link("https://github.com/ajeetdsouza/zoxide")[`zoxide`]. It literally lets you teleport around in the terminal. No more endless iterations of `ls` followed by `cd`.
- In the same spirit, #link("https://github.com/junegunn/fzf")[`fzf`] Just Works™ for finding that one file with the name you only kind of remember -- wherever it may be. Also, fuzzy find has so many more places where it can help you. It's really more of a lifestyle rather than just another CLI.
- Knowing what's inside some file is another little thing that you probably don't give another thought. But once you go #link("https://github.com/sharkdp/bat")[`bat`], you never go back. It has syntax highlighting (with color), filenames, line numbers, and a built-in pager. Use it for preview in `fzf` and profit even more.
- Trust me, I'm not a fan of forking processes unless necessary, but be honest with yourself. Have you any idea how to use the `find` command on your platform/shell combination? I don't. That's why I'm using #link("https://github.com/sharkdp/fd")[`fd`] as a modern and blazingly fast replacement for it wherever I go. Most of its flags and syntax should feel intuitively familiar anyways. You can also configure `fzf` to use `fd`.
- Did you know that `grep` comes from the original Unix editor `ed`, where `g/re/p` stands for "#strong[g]lobal search for #strong[r]egular #strong[e]xpression, then #strong[p]rint"? Well, now you do. Bet the way to use it feels pretty clunky, though. Enter #link("https://github.com/BurntSushi/ripgrep")[`rg`], the blazingly fast `grep` killer. Just invoke it with the search string and watch in awe as you get results instantaneously. RIP `grep`, long live `rg`.
- To those of you who would like to see what your machine is up to with nice resource-utilization visualization and powerful search and interrupt capabilities for rogue processes, I give #link("https://github.com/ClementTsang/bottom")[`btm`]. It gives you some sysadmin peace of mind.
- Now we're entering exotic territory. If you've made it this far, please check out #link("https://www.nushell.sh")[`nu`]. It's an entirely new kind of shell, which breaks the curse of Unix compatibility in lieu of one simple yet immeasurably brilliant principle -- _everything is structured data_. First of all, it obviously has nice highlighting and smart suggestions. Secondly, it's a real programming language! Writing scripts has never been this fun and readable. Also, one of its core goals is to be as cross-platform-agnostic as possible. Fearlessly switch OS through the use of abstractions. It's got so many more quality-of-life-improving aspects, ranging from rather small to really significant. Check it out, use it, and forget the idiosyncrasies of `bash`.
- The shell command history is an often-overlooked part of the whole system, except probably for spamming the up arrow. But #link("https://atuin.sh")[`atuin`] makes it so much more useful. You can synchronize your machines and treat the history like a database. Filter by status, execution time, execution date, and more.
- Sometimes the terminal is just too small to contain everything you need. Terminal multiplexers solve exactly that problem. Now, there are very well-established alternatives, but I'm going with the very new #link("https://zellij.dev")[`zellij`]. It has so many more convenient features compared to `tmux`, like a modern configuration language, polyglot plugin support, and even a web server?!
- If you do a lot of Git comparison work, you have to use #link("https://github.com/dandavison/delta")[`delta`].
- Forgot how to `scp` some file via jumphost? Make new SSH keys? Whatever your little question may be, #link("https://github.com/tldr-pages/tlrc")[`tlrc`] has you covered. Don't waste time or resources searching in the browser or asking AI -- simply query the database and find out on the fly.
- Pimp your prompt with #link("https://starship.rs")[`starship`], saving you the time trying to piece all your customization back together when you inevitably switch shells or systems.

For my friends rocking macOS, here are some nice bonus treats.

- You HAVE to use #link("https://brew.sh")[Homebrew]. Please know that if you drag and drop from your `.dmg` installer, I think less of you. This is no way to interact with your beast of a computer.
- If you do Docker on macOS, #link("https://orbstack.dev")[OrbStack] will make the whole ordeal SO much more enjoyable. It's so lightweight you literally don't notice it's there. On top of that, it has this really nice VM feature where literally every OS is just one command away, and then you can seemingly seamlessly interact between them.
- The Universal Turing Machine is an abstract machine that can emulate every other kind of formal computational model. It is my suspicion that this served as namesake for #link("https://github.com/utmapp/UTM")[UTM]. It lets you virtualize and emulate pretty much everything you could dream of with full GUI support, thanks to the power of QEMU.
- Hands down the best editor for macOS, #link("https://zed.dev")[Zed] is simply amazing. It looks so clean and operates so smoothly. Great tooling too, with LSP and native Git support. LLM-based coding is a breeze. Give it a try!
- The new Spotlight is pretty decent, but #link("https://www.raycast.com")[Raycast] is better. It replaces whatever you use for window and clipboard management and does superb date and currency conversion.
- I always know my public and private IP addresses thanks to #link("https://mac-stats.com")[Stats]. Oh, and also network speed, fan intensity, power usage, CPU and RAM workload -- literally every stat there is.
- Insert mode is nice and all, but #link("https://kindavim.app")[KindaVim] allows you to use the other ones too. This is the gift that keeps giving, as your muscle memory finally translates to the OS level. Haven't tried it yet, but very much looking forward to it.
