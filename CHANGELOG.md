# Changelog
All notable changes to this project will be documented in this file.

The format is based on Keep a Changelog, and this project adheres to Semantic Versioning.
## [1.0.1] - 2025-08-11
- Updated README.md documentation

## [1.0.0] - 2025-08-11
### Added
- Offline-first architecture.
- Automatic sync on app launch, connectivity change, or manual trigger.
- Change tracking for inserts, updates, and deletes.
- Pluggable adapters for local and remote storage (Hive, Drift, customizable).
- Conflict resolution strategies: ClientWins, ServerWins, Timestamp, and custom resolvers.
- Encrypted local storage support via Hive.
- Connectivity-aware retry mechanism.
- Testable architecture with mock support.
- Arabic and RTL support.

### Documentation
- Comprehensive README with Getting Started, Architecture overview, Adapter interfaces, Conflict resolution, and Configuration options.

### Example
- Added full example app under `example/` demonstrating setup and usage.

## [0.0.1] - 2025-08-11
### Added
- Initial scaffolding.
