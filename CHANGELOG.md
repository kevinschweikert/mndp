# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased] 

## [0.1.2] - 2024-10-15

### Changed

- `MNDP.CLI.run/0` now starts the whole `mndp` application instead of only the listener

### Fixed

- Fixed `discover.exs` script [#7](https://github.com/kevinschweikert/mndp/pull/7)
- Changelog PR links

## [0.1.1] - 2024-10-14

### Changed

- mix tasked namespaced from `mix discover` to `mix mndp.discover`

### Fixed

- use hex package in docs [#4](https://github.com/kevinschweikert/mndp/pull/4)
- fix typo in configuration example [#5](https://github.com/kevinschweikert/mndp/pull/5)
- update spec to allow `:hostname` for the identity field [#6](https://github.com/kevinschweikert/mndp/pull/6)

## [0.1.0] - 2024-10-13

### Added

- Initial Version
