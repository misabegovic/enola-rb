# enola-rb

[![Gem Version](https://badge.fury.io/rb/enola-rb.svg)](https://rubygems.org/gems/enola-rb)
[![CI](https://github.com/misabegovic/enola-rb/actions/workflows/ci.yml/badge.svg)](https://github.com/misabegovic/enola-rb/actions/workflows/ci.yml)

Fail the build when a change breaks your Rails app's architecture: a model
that starts calling a controller, a job that renders, a new dependency cycle.
RuboCop reads one file at a time and your tests run the code; neither sees
the edge a change adds between two parts of the app. These gems run
[enola](https://github.com/enola-labs/enola) from Bundler. enola pins your
app's dependency graph as a baseline and grades each change against it, so
the hundreds of crossings an app already has stay out of the report and only
what the change introduced can fail it.

## What it catches

[Campfire](https://github.com/basecamp/once-campfire), 37signals' Rails chat
app, after `bin/rails generate enola:install` and a pinned baseline. One
method added to a model:

```ruby
# app/models/boost.rb
def render_preview
  MessagesController.render(partial: "messages/boost", locals: { boost: self })
end
```

```
$ bin/rake enola:check
FAIL — 1 structural regression introduced.

Regressions (fail):
  - [constraints] 1.00 — Constraint models-do-not-reach-controllers violated: Boost#render_preview -> MessagesController via calls
      forbidden calls edge
      app/models/boost.rb:7
        def render_preview
        ^^^^^^^^^^^^^^^^^^

Policy: fail on new findings from [constraints] at confidence >= 1.00.

New findings (advisory — below the failure policy):
  - [constraints] 0.90 — Advisory constraint layered/domain-knows-no-presentation violated: rubydex-ref: Boost#render_preview -> MessagesController -> MessagesController via depends_on
      forbidden depends_on edge
      app/models/boost.rb:8
          MessagesController.render(partial: "messages/boost", locals: { boost: self })
```

The tests pass and RuboCop is silent; the check exits 1. Campfire already
carries 178 breaches of the bound rules, and none of them is in the report.
A new controller that calls a model passes. Output trimmed: the full verdict
goes on to list what the change resolved, the coupling it added and the
package metrics that moved. `enola check --summary` writes the same verdict in
plain words.

## Quick start (Rails)

```sh
bundle add enola-rb --group "development, test"
bin/rake enola:explain             # what the app is, where to start, what is risky
bin/rails generate enola:install   # mcp-arch.yaml, enola/constraints/, .gitignore
bin/rake enola:snapshot            # snapshot the app and pin it as the baseline
# ...make a change...
bin/rake enola:check               # exits 1 on a new breach of a declared law
```

The generator writes four starter laws a Rails team keeps, each with its
reason (`models-do-not-reach-controllers`, `policies-only-answer`,
`the-request-api-stays-in-controllers`,
`background-jobs-never-invoke-controller-code`), and binds the enola recipes
whose directories the app has. `layered` is bound advisory: Rails
controllers call models by design, which that recipe reads as a breach, so
it reports and never fails a check. The laws are plain Ruby files in
`enola/constraints/`; edit them, delete them, add your own. Upstream's
[Rails guide](https://github.com/enola-labs/enola/blob/main/docs/RAILS.md)
walks the same loop with the binary alone, and
[GATING.md](https://github.com/enola-labs/enola/blob/main/docs/GATING.md)
says exactly what can fail a build.

Not on Rails? `bundle add enola --group development` and every enola command
runs as `bundle exec enola ...`; see [`enola`](#enola) below.

## In CI

Grade each pull request against its base branch. The base is snapshotted in
a worktree beside the checkout, so the PR's `Gemfile.lock` stays in place,
and a regression shows up as an annotation on the line that introduced it:

```yaml
# .github/workflows/architecture.yml
name: Architecture
on: pull_request
jobs:
  enola:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v5
        with:
          fetch-depth: 0
      - uses: ruby/setup-ruby@v1
        with:
          bundler-cache: true
      - name: Snapshot the base branch
        run: |
          git worktree add "$RUNNER_TEMP/base" "${{ github.event.pull_request.base.sha }}"
          bundle exec enola --generate "$RUNNER_TEMP/base"
      - name: Grade the pull request
        run: >
          bundle exec enola check --baseline "$RUNNER_TEMP/base/.enola"
          --fail-on constraints --format annotations --host github .
```

`bundle exec enola` needs no database and does not boot the app. Merge what
the generator wrote before turning the workflow on, so the base declares the
same laws the pull request is graded by.

## With a coding agent

enola is also an MCP server: it gives Claude Code, Cursor and other agents a
map of the app to query instead of grepping through it, and lets them check
their own change before they report it done.

```sh
claude mcp add enola -- bundle exec enola   # serve the graph to Claude Code
bundle exec enola install                   # write enola's instructions into the
                                            # files your agents read; previews first
```

## How it compares

| Tool | Reads | Fails on |
|---|---|---|
| RuboCop, Standard | one file at a time, against style rules | any offence in the tree |
| Brakeman | data flow, for security | any warning in the tree |
| Packwerk | constant references across declared packs | references the packs do not allow |
| enola | the dependency graph across the app, against a pinned baseline | only what this change introduced, and only the rules you name |

They are complements. enola reads Packwerk's `package.yml` files, rolls
impact up by pack and has a packwerk explainer, so an app that already uses
Packwerk keeps it.

## The gems

Three pure-Ruby gems in one repository. None carries a binary or compiles
anything: the first command that needs enola downloads the release for your
platform and verifies its checksum.

| Gem | Use it for |
|---|---|
| `enola-rb` | Rails: the generator and the `enola:*` rake tasks. Depends on `enola`. |
| `enola` | Any Ruby project: the `enola` command, wrapping the released binary. |
| `munola` | A fork channel with its own recipe catalogue; see [`munola`](#munola). |

`enola` and `enola-rb` are split so a Rubyist can take the wrapper without
Rails. `munola` is one gem for its own channel, wrapper and Rails layer
together, because nobody installs it to avoid Rails. The Rails code is written
once, in `enola-rb`, and munola adds only what is munola's own.

## `enola`

The wrapper of the released enola. The gem versions itself; the release it
drives is `Enola::UPSTREAM_VERSION`, v0.4.35 as of `enola 0.5.7`, and every
gemspec summary names it.

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
`~/.cache/enola/upstream/0.4.35/` (`ENOLA_CACHE_DIR` moves the root). An
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

The Rails layer over `enola`. It depends on `enola` at the same minor and on
[enola-guides](https://github.com/misabegovic/enola-guides), and adds nothing
to the binary's surface.

```ruby
gem "enola-rb"
```

```sh
bin/rails generate enola:install
bin/rake enola:explain
bin/rake enola:snapshot
bin/rake enola:check
```

The generator writes `enola/constraints/` from the guides' starter laws (four
laws a Rails team keeps, each with its reason), asks the binary's own
`constraints init` to bind the shipped recipes whose roles resolve in the app,
writes every other shipped recipe as a commented binding to uncomment once the
directories exist, and ignores `.enola/`. A `layered` binding the binary's
init wrote is set to `mode: advisory`; a `recipes.yaml` the app already had
is never touched. It reads what `init` wrote rather
than its exit code, and when the binary cannot be fetched it still writes the
laws and says so. `enola:explain` needs no setup: it prints what the app is,
where to start reading, what is risky to change and what is worth a look
(the full statistics report on a binary without `--summary`).
`enola:snapshot` generates and pins the baseline;
`enola:check` grades the working tree against it and fails on a new breach of
a declared law. A surface the pinned binary lacks is refused by name with the
remedy.

## `munola`

One person's taste on top of enola: the same wrapper over another channel,
the builds cut from [a fork of enola](https://github.com/misabegovic/enola),
each release naming what differs from that upstream. The gem versions itself;
the channel release it fetches is `Munola::CHANNEL_VERSION`, which carries the
upstream it is built on plus a segment of its own (`0.4.4.2` on v0.4.4). It is
offered upstream where it fits and is not positioned against it. What it adds is the channel and the catalogue.

```ruby
gem "munola"
```

```sh
bundle exec munola init . --tenant-column company_id
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
version, the channel release and upstream it is built on, and which binary
answered.

The binary comes from the fork's releases the way `enola`'s comes from
upstream's, fetched on first use and verified against the sha256 the release
publishes; `MUNOLA_BINARY=/path/to/enola` names one to drive instead, and
every command says which answered. `munola` depends on `enola` at the same
minor and on `enola-guides` 0.3.1 or later; requiring it loads no Rails.

## munola under Rails

munola carries its own generator, and the rake tasks are enola-rb's:

```sh
bin/rails generate munola:install --tenant-column company_id
bin/rake enola:snapshot
bin/rake enola:check
```

The generator runs the same install `munola init` does. `munola` installs its
own resolver when it loads, so `enola:snapshot` and `enola:check` drive the
munola binary in an app that has this gem, and the upstream binary in one that
does not. Requiring munola loads no Rails; the generator registers when the
application has already loaded it.
