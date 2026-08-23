# enola-rb

Three pure-Ruby gems, one repository, for running
[enola](https://github.com/enola-labs/enola), the architecture-graph tool,
from Ruby. None of them carries a binary or compiles anything.

## `enola`

The wrapper of the released enola. Its version is the upstream release it
drives: `enola 0.4.4` runs enola-labs' v0.4.4.

```ruby
gem "enola"
```

```sh
bundle exec enola --generate .
bundle exec enola baseline pin .
bundle exec enola check .
```

The first command that needs the binary downloads the release for your
platform (linux, darwin, windows; amd64, arm64), verifies it against the
sha256 file the same release publishes, and keeps it under
`~/.cache/enola/upstream/0.4.4/` (`ENOLA_CACHE_DIR` moves the root). An
`enola` already on your PATH is used only when it answers the pinned version;
offline with an empty cache is a refusal that names the cache and the release
rather than a fallback to whatever is installed. Nothing downloads at
`bundle install`.

Every argument and exit code is forwarded unchanged; the wrapper adds no flag
of its own to enola's surface. `--verbose` on any command writes one line to
stderr first, naming the channel, the version and where the binary came from.
`enola --wrapper-probe` prints the channel, the pin, the version the binary
answers and which surfaces it has (`constraints`, `providers`, `check`,
`hook`), read by running them, never by comparing version strings.

This gem is not an enola-labs release; it runs theirs.

## `enola-rb` and `munola`

Placeholders at 0.0.0. `enola-rb` will depend on `enola` and on
[enola-guides](https://github.com/misabegovic/enola-guides) and add the Rails
layer: rake tasks, `rails generate enola:install` writing `enola/constraints/`
from the guides' recipes, and the capability probe the generator needs.
`munola` will be the same wrapper over another channel, the build this
project maintains, carrying the guides' content and the recipes for the
architectures they cover, versioned as the upstream it is built on plus a
fourth segment, and saying in each release what differs from that upstream.
