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

## enola-rb 0.0.0, munola 0.0.0

Placeholders. `enola-rb` is the Rails layer over `enola` and enola-guides;
`munola` is the same wrapper over another channel. Both follow.
