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

## enola-rb 0.4.4 (2026-08-23)

The Rails layer, first release with an implementation. `rails generate
enola:install` writes `enola/constraints/` from the enola-guides starter laws,
binds the recipes the binary's own `constraints init` picks, writes the rest
as commented bindings and ignores `.enola/`; the `enola:init`,
`enola:snapshot` and `enola:check` rake tasks drive the binary the `enola` gem
fetches. A surface the pinned binary lacks is refused by name with the remedy;
an absent binary still leaves the laws written. Depends on `enola` at the same
version and on `enola-guides`.

## munola 0.0.0

Placeholder. `munola` is the same wrapper over another channel. Follows.
