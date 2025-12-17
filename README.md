# SimpleMaster

In game development and other domains, configuration/definition datasets are often called “master data.” SimpleMaster was built to serve that master data fast inside Ruby apps. It keeps masters in memory and offers an ActiveRecord-like DSL so you can access them with speed and simplicity. It works in Rails and other Rack apps, and in data-heavy services it can significantly shrink response times.

> 日本語版は [README.ja.md](README.ja.md) を参照してください。

## Features
- **No DB queries after load**: master tables are loaded at boot, then everything runs in memory, so responses stay lightweight.
- **Familiar associations, very fast**: `belongs_to` / `has_many`-style API resolved in memory, fast enough that N+1 is rarely a concern.
- **COW-friendly for multi-process**: records are frozen, making Copy-on-Write efficient when sharing memory across forked processes.

## License
MIT License. See [LICENSE](LICENSE) for details.
