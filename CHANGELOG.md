# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2026-04-24

### Added

- Initial release of `ruby_gaurden`, a "walled garden" for untrusted Ruby execution.
- Introduced `RubyGaurden::Bed` as the primary sandbox class.
- Implemented **Context Pooling** to significantly reduce sandbox instantiation latency.
- Added **JSON-based Bridging** for safe and efficient data exchange between the host and sandbox.
- Added **FIFO Cache Pruning** to the `RuntimeEnvironment` to prevent memory bloat during long-running processes.
- Included `RubyGaurden.planted?` and `RubyGaurden.current` helper methods for environment detection.
- Integrated thread-safe IO buffers for `stdout` and `stderr` collection.
- Comprehensive YARD documentation for the public API.
- Automated CI pipeline via GitHub Actions.

### Changed

- Rebranded and forked from `ruby_box`.
- Completely refactored the execution engine to move bridge logic from raw JavaScript to idiomatic Ruby via Opal.
- Updated `mini_racer` to version `0.21.0` and `opal` to `1.8.0`.

### Fixed

- Resolved "Genesis" crashes in V8 by decoupling the Opal runtime from the initialization sequence.
- Fixed thread-safety issues during concurrent sandbox execution using `Monitor`.

[0.1.0]: https://github.com/anarchocurious/ruby_gaurden/releases/tag/v0.1.0
