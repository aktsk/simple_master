# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.1] - 2026-05-18

### Fixed
- `MarshalLoader` no longer raises `Errno::ENOENT` when a dump file is missing; the corresponding table is loaded as an empty record set, matching `QueryLoader`'s fallback for unavailable tables.

## [1.0.0] - 2025-12-26

### Added
- Initial public release.

[1.0.1]: https://github.com/aktsk/simple_master/compare/v1.0.0...v1.0.1
[1.0.0]: https://github.com/aktsk/simple_master/releases/tag/v1.0.0
