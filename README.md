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

## `enola-rb`

The Rails layer over `enola`. It depends on `enola` at the same version and on
[enola-guides](https://github.com/misabegovic/enola-guides), and adds nothing
to the binary's surface.

```ruby
gem "enola-rb"
```

```sh
bin/rails generate enola:install
bin/rake enola:snapshot
bin/rake enola:check
```

The generator writes `enola/constraints/` from the guides' starter laws (four
laws a Rails team keeps, each with its reason), asks the binary's own
`constraints init` to bind the shipped recipes whose roles resolve in the app,
writes every other shipped recipe as a commented binding to uncomment once the
directories exist, and ignores `.enola/`. It reads what `init` wrote rather
than its exit code, and when the binary cannot be fetched it still writes the
laws and says so. `enola:snapshot` generates and pins the baseline;
`enola:check` grades the working tree against it and fails on a new breach of
a declared law. A surface the pinned binary lacks is refused by name with the
remedy.

## `munola`

One person's taste on top of enola: the same wrapper over another channel,
the builds cut from [a fork of enola](https://github.com/misabegovic/enola),
versioned as the upstream they are built on plus a fourth segment
(`0.4.4.1` drives a build on v0.4.4), each release naming what differs from
that upstream. It is offered upstream where it fits and is not positioned
against it. What it adds is the channel and the catalogue.

```ruby
gem "munola"
```

```sh
bin/rails generate munola:install --tenant-column company_id
bundle exec munola init .
bundle exec munola --version
```

`munola init` does what `enola:install` does, then what only munola carries:
it writes the recipe catalogue the `enola-guides` gem ships (Ember
conventions, data ownership, API boundaries, background work, a tenant
foreign key) into `enola/recipes/`, binds the recipes the tree justifies
(`ember-cli-build.js`, a schema with `app/models`, `config/routes.rb` with
`app/policies`, `app/tasks`, a column most tables share confirmed against
`db/schema.rb`) and writes every other one as a commented binding; it fills
the tenant template from the schema's own table names, never from an
inflection table; it writes `mcp-arch.yaml` with both Ruby providers on by
default, Prism through the script the `enola` gem carries and Rubydex built
into the binary, and fetches the Rubydex library, a failed fetch reported as a
named skip. It never asks a question. `munola --version` names the munola
version, the upstream it is built on and which binary answered.

The first munola release is what makes the channel real; until it is cut,
`MUNOLA_BINARY=/path/to/enola` names the binary to drive, and every command
says so. `munola` depends on `enola` and `enola-rb` at its upstream version
and on `enola-guides` 0.3.1 or later.
