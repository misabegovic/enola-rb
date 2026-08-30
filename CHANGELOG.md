## munola 0.6.2 (2026-08-30)

munola drives channel release `0.4.10.1`, cut from the promoted current at
upstream enola 0.4.10. The difference list shrank again by contribution: the
exclusion filter went upstream in 0.4.7, and the constraints reference this
channel once carried inside INTENT.md shipped upstream as CONSTRAINTS.md and
PROVIDERS.md over 0.4.5. What the channel still adds is the recipe catalogue
at enola-guides v0.3.1, the init role binding, the cache-version double
history and a readability spelling in blame.go.

## enola 0.5.4 and enola-rb 0.5.4 (2026-08-30)

The gems drive upstream enola 0.4.10. Between 0.4.6 and here upstream took the
exclusion filter (#255, in 0.4.7), rescored the layers explainer per language
cohort (0.4.7), began reading package manifests as dependency facts with a
declared-purpose diff (0.4.8), gave the dashboard its own command (0.4.9), and
documented the snapshot artifacts as a versioned contract with fact identity
(0.4.10). The vendored Prism provider script and the Rubydex engine pin are
byte-identical across the span, so nothing re-vendors; the wrappers move by
the release they name.

## munola 0.6.1 (2026-08-24)

munola drives channel release `0.4.6.1`, cut from the promoted current at
upstream enola 0.4.6. The prefix walk fix is in the binary this gem fetches,
so the expiry the 0.6.0 note named is met and Rubydex is on by default again.
The channel still carries the exclusion filter, which upstream merged an hour
after 0.4.6 was published, so an excluded document is skipped before its
definitions are read: 440 seconds to 193 on a Rails monolith, facts identical.

The 0.6.0 note said munola waits on Prism alone. On the Rails install path it
did not. `munola init` reuses enola-rb's installer, which writes
`mcp-arch.yaml` first, and munola's own writer yields to a file that already
exists, so the config every Rails project got was the enola gem's, with both
providers on, against a channel binary built before the fix. Two things follow.
The config and the binary now agree, which is what closes it. And munola's
writer has a test that reads munola's writer, rather than one that reads the
file enola-rb wrote and reports on munola.

## enola 0.5.3, enola-rb 0.5.3 and munola 0.6.0 (2026-08-24)

Both providers are on again. enola-labs shipped the prefix walk fix in 0.4.6,
which is the release the enola and enola-rb gems now drive, so the config they
write carries Prism and Rubydex as it did before the hang was found.

munola waits. Its binary is a fork release cut before that fix, so it stays on
Prism alone until the channel is re-cut, and its version file says which
upstream it is built on rather than implying the newest.

munola-rb is gone, and was never published. The railtie and generator move
into munola, which is why munola is 0.6.0: one gem for one channel, since the
split that makes sense for enola and enola-rb, letting a Rubyist take the
binary wrapper without the Rails layer, does not describe anyone's use of
munola. Requiring munola still loads no Rails; the generator registers when
the application has already loaded it.

## enola 0.5.2, enola-rb 0.5.2, munola 0.5.2 and munola-rb 0.5.2 (2026-08-23)

Rubydex is off in the config these gems write, and named in a comment beside
the reason. The release each gem drives carries a walk that can fail to
return: a constant reference spanning lines could be treated as its own
predecessor, so a tree with vendored gems could snapshot for twenty-six
minutes and several gigabytes without finishing. Two of the three Rails trees
it was tried on did exactly that.

The fix exists and is not yet in a published enola, so the default cannot
depend on it. Prism is unaffected and stays on: it parses a monolith in 13.7
seconds. Uncommenting the two lines brings Rubydex back for anyone who wants
it deliberately, and the default returns the moment the binary each gem drives
carries the fix.

## enola 0.5.1 (2026-08-23)

The resolver no longer probes its own binstub. It read a candidate's first 512
bytes looking for the marker RubyGems writes, and a real binstub carries a
`/bin/sh` + `ruby -x` preamble holding the interpreter's absolute path, which puts
that marker around byte 580 — outside the window. So the guard missed every
RubyGems-generated binstub, the wrapper ran itself, and running itself has no
bottom: `enola --version` on a cold cache spawned Ruby processes until it was
killed. The whole file is read now, capped at 64 KiB so a released binary is never
slurped only to be rejected, and `Gem.bin_path` is recognised beside
`Gem.activate_bin_path`. A probe also marks its child's environment, and a resolver
that sees the marker declines to look at PATH at all, so the recursion is bounded
by construction rather than by how well a heuristic reads a file.

The marker is written where it is spawned: every probe passes it into the child,
so a wrapper reached under another name leaves PATH alone instead of probing in
turn. That bound is what covers the wrappers the content check cannot see, a
version manager's shim among them, which carries none of the markers a binstub
does. Reported and fixed by dejo1307 in #1.

## munola 0.4.4.2 and munola-rb 0.4.4.2 (2026-08-23)

munola follows the channel it drives. Its binary is now cut from the stable
channel after it took eight changes measured against a Ruby architecture
linter, so the gem's version moves with the release it fetches. The Rails
layer is its own gem, `munola-rb`, the way `enola-rb` is for the upstream
channel; `require "munola"` loads no Rails. A catalogue recipe the binary
already binds is no longer bound a second time.

## enola 0.4.4.1 and enola-rb 0.4.4.1 (2026-08-23)

Wrapper fixes on the same upstream release. A test that set the channel put
back upstream rather than what it found, so on some orderings a channel gem's
own installation read as upstream. The Rails layer packaged its generator
through a glob wide enough to take another channel's; it now packages its own.
Both gems still drive upstream v0.4.4.

## munola-rb 0.4.4.1 (2026-08-23)

The Rails layer over munola, what enola-rb is to enola: `rails generate
munola:install [--tenant-column COLUMN]` writes the starter laws, the
bindings the binary's own init picks and the munola catalogue, and the
enola:init, enola:snapshot and enola:check tasks drive munola's binary
because munola installs its own resolver. The generator and the railtie
move here out of the munola gem, so `require "munola"` loads no Rails and a
project that only drives the binary carries no Rails machinery. The recipe
catalogue, the detection and the tenant-column argument stay munola's.

`Enola.resolver_factory` is readable as well as writable, so whoever
replaces it can put back what was installed rather than what it assumed.

## munola 0.4.4.1 (2026-08-23)

The wrapper over the munola channel, first release with an implementation.
`munola init` writes the starter laws and upstream's bindings the way
`enola:install` does, then the recipe catalogue from enola-guides, binds the
recipes the tree shows a need for, fills the tenant foreign-key template
from the schema, writes `mcp-arch.yaml` with Prism and Rubydex on and fetches
the Rubydex library; `munola --version` names the munola version, its
upstream base and the binary that answered; `MUNOLA_BINARY` names a binary
to drive until the first munola release is cut. The channel's tag shape is
`munola-v<version>` on the fork's releases.

## enola 0.4.4 (2026-08-23)

The wrapper, first release with an implementation: a pure-Ruby `enola`
executable that drives upstream's v0.4.4. The binary is fetched on first use
from the release for the running platform, verified against the sha256 the
release publishes, and kept under `~/.cache/enola/upstream/0.4.4/`; a binary on
PATH is used only when it answers the pinned version; offline with an empty
cache is a refusal that names the cache and the release. Every argument and
exit code is forwarded; `--verbose` adds one stderr line naming channel,
version and where the binary came from; `enola --wrapper-probe` prints the
channel, pin, found version and which surfaces the binary answers.

Both providers by default: the gem vendors upstream's Prism provider script
at the pinned version and depends on the `prism` gem; `enola init` writes
`mcp-arch.yaml` with Prism (run by this Ruby) and Rubydex on, then runs the
binary's `constraints init`; the Rubydex engine library is fetched once per
binary version after the binary itself, a failure printed once as a named
skip. `Enola::Config.write_default` and `Enola::Providers` are the seams the
Rails layer and munola call.

## enola-rb 0.4.4 (2026-08-23)

The Rails layer, first release with an implementation. `rails generate
enola:install` writes `enola/constraints/` from the enola-guides starter laws,
binds the recipes the binary's own `constraints init` picks, writes the rest
as commented bindings and ignores `.enola/`; the `enola:init`,
`enola:snapshot` and `enola:check` rake tasks drive the binary the `enola` gem
fetches. A surface the pinned binary lacks is refused by name with the remedy;
an absent binary still leaves the laws written. Depends on `enola` at the same
version and on `enola-guides`. The generator writes the provider config first,
so a fresh app's graph carries Prism and Rubydex facts from its first snapshot.

## munola 0.0.0

Placeholder. `munola` is the same wrapper over another channel. Follows.
