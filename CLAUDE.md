# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Ruby SDK for the [CloudEvents](https://cloudevents.io/) specification (CNCF). Gem name: `cloud_events`. Supports CloudEvents spec versions 0.3 and 1.0. Zero runtime dependencies; Ruby 2.7+.

## Development Commands

This project uses [Toys](https://github.com/dazuma/toys) as the task runner (not Rake).

```bash
bundle install              # Install dependencies
gem install toys            # Install task runner (required)

toys test                   # Run minitest unit tests
toys cucumber               # Run Cucumber conformance tests
toys rubocop                # Run linter
toys yardoc                 # Generate YARD documentation
toys build                  # Build .gem file into pkg/
toys install                # Build and install gem locally
toys ci                     # Run full CI suite (test + cucumber + rubocop + yard + build)
toys ci --only --test       # Run only minitest
toys ci --only --cucumber   # Run only Cucumber tests
toys ci --only --rubocop    # Run only linter
```

To focus a single test, add `focus` before a test method (requires `minitest-focus` gem from the bundle).

## Code Style

Enforced by Rubocop (`.rubocop.yml`):
- Double-quoted strings
- Trailing commas in multiline arrays/hashes
- 120 character line limit
- `[:symbol]` array style (not `%i`)
- `["word"]` array style (not `%w`)
- All source files require `# frozen_string_literal: true`

## Architecture

### Event Model

`CloudEvents::Event` is both a module (included by all event classes) and a factory via `Event.create(spec_version:, **attrs)`.

- **`Event::V1`** — CloudEvents 1.0 (primary). Immutable (frozen), Ractor-shareable on Ruby 3+.
- **`Event::V0`** — CloudEvents 0.3 (legacy).
- **`Event::Opaque`** — Wrapper for events that couldn't be fully decoded.

V1 has a dual data model: `data` holds the decoded Ruby object, `data_encoded` holds the serialized string/bytes. Formatters use `data_encoded` if present, otherwise encode `data`.

### HTTP Binding (`HttpBinding`)

Handles encoding/decoding CloudEvents to/from HTTP (Rack env hashes). Supports:
- **Binary content mode** — event attributes as `CE-*` headers, data in body
- **Structured content mode** — entire event serialized in body (e.g., JSON)
- **Batch mode** — array of events in body

`HttpBinding.default` returns a singleton with `JsonFormat` and `TextFormat` pre-registered. Custom formatters are registered via `register_formatter`.

### Kafka Binding (`KafkaBinding`)

Handles encoding/decoding CloudEvents to/from Kafka messages. CloudEvents 1.0 only (no V0.3). Supports:
- **Binary content mode** — event attributes as `ce_*` headers (plain UTF-8, no percent-encoding), data in value
- **Structured content mode** — entire event serialized in value (e.g., JSON)
- **No batch mode** (per the Kafka spec)
- **Tombstone support** — `nil` value represents an event with no data
- **Key mapping** — configurable callables to map between Kafka record keys and event attributes (default: `partitionkey` extension)

Kafka messages are represented as plain `{ key:, value:, headers: }` Hashes, decoupled from any specific Kafka client library.

`KafkaBinding.default` returns a singleton with `JsonFormat` and `TextFormat` pre-registered. Key mappers are configurable at construction and overridable per-call via `key_mapper:` / `reverse_key_mapper:` keyword arguments.

### Format Layer

- **`JsonFormat`** — Encodes/decodes `application/cloudevents+json` and batch format. Also handles JSON data encoding/decoding for binary mode.
- **`TextFormat`** — Handles `text/*` data.
- **`Format::Multi`** — Composite that tries multiple formatters in registration order.

Formatters implement up to four methods: `decode_event`, `encode_event`, `decode_data`, `encode_data`. Return `nil` to decline handling (next formatter is tried).

### Content-Type Parser (`ContentType`)

RFC 2045 compliant parser. Handles charset defaults: `text/plain` defaults to `us-ascii`, other `text/*` and JSON types default to `utf-8`.

### Error Hierarchy

All errors inherit from `CloudEventsError`: `NotCloudEventError`, `UnsupportedFormatError`, `FormatSyntaxError`, `SpecVersionError`, `AttributeError`.

## Contributing

- Use red-green test-driven development when making changes, unless instructed otherwise.
- Conventional Commits format required (`fix:`, `feat:`, `docs:`, etc.)
- Commits must be signed off (`git commit --signoff`)
- Run `toys ci` before submitting PRs
