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
