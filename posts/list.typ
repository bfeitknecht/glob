#import "@preview/thyme:0.1.0": *
#import blog: *

#show: post.with(
  title: [Feitk's List],
  subtitle: [Twenty-one projects for the aspiring computer science generalist],
  author: "Basil Feitknecht",
  monograph: "bkf5",
  created: datetime(year: 2026, month: 3, day: 18),
  modified: datetime(year: 2026, month: 10, day: 27),
  summary: [A computer science counterpart to Robert A. Heinlein's generalist manifesto -- and 50 CHF if you have genuinely built all twenty-one.],
  tags: ("cs", "projects", "unix"),
)

Perhaps you're familiar with Robert A. Heinlein's list.

#quote(block: true)[
  "A human being should be able to change a diaper, plan an invasion, butcher a hog, conn a ship, design a building, write a sonnet, balance accounts, build a wall, set a bone, comfort the dying, take orders, give orders, cooperate, act alone, solve equations, analyze a new problem, pitch manure, program a computer, cook a tasty meal, fight efficiently, die gallantly. Specialization is for insects."
]

Allow me to propose another list for people in computer science. In particular, it should serve to shine a light on all the extremely diverse aspects of this profession and let you develop some sense as to how you fare against the ultimate (so far hypothetical) generalist that has done all of these projects. And I mean really done them, not half-assed or vibe-coded. If you have done every single one of these, please contact me with proof to receive my utmost respect, a heartfelt congratulations, and 50 CHF.

- [x] Interpreter or compiler#sidenote[Checked off with @impli, an interpreter for the `IMP` language in Haskell.]
- [ ] Text editor
- [ ] Database
- [ ] Full network stack web server (HTTP/TCP/IP)
- [ ] Fast web app with good a11y and i18n
- [ ] Kernel with rudimentary shell
- [x] Hardware (in HDL) with rudimentary Assembly
- [ ] VM or emulator
- [ ] Boolean satisfiability reduction
- [ ] Computer-aided formal proof
- [ ] Scientific research paper
- [ ] Touch grass
- [x] Memory (de)allocator or garbage collector
- [ ] Filesystem specification
- [ ] Neural network
- [ ] Cryptographic protocol
- [ ] Fix `{computer, router, printer, TV, radio, ...}`
- [ ] Physics engine
- [ ] Regular expression engine
- [ ] Ray tracer or rasterizer
- [ ] Exit Vim

Specialization is for tools adhering to the UNIX philosophy.
