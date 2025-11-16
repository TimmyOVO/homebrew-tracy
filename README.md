# Tracy Homebrew Tap

This repository is a very small, personal Homebrew tap that exists only to build a patched version of the Tracy profiler on macOS.  
It is not a general-purpose collection of formulae.

The single formula provided here is:

- `timmyovo/tracy/tracy` – Tracy Profiler 0.13.0 with local patches so it builds cleanly against the current macOS toolchain and Homebrew dependencies.

## Install

Add the tap:

```bash
brew tap timmyovo/tracy https://github.com/TimmyOVO/homebrew-tracy
```

Install Tracy:

```bash
brew install timmyovo/tracy/tracy
```

Or in a `Brewfile`:

```ruby
tap "timmyovo/tracy"
brew "timmyovo/tracy/tracy"
```

## What this Tracy formula does

Compared to building Tracy from upstream sources directly, this formula:

- Builds Tracy 0.13.0 on macOS (including Apple Silicon) using Homebrew libraries:
  - `capstone`
  - `zstd`
  - `glfw`
  - `freetype`
- Enables `-DHOMEBREW_ALLOW_FETCHCONTENT=ON` so Tracy can use its bundled CPM/FetchContent configuration to download third-party dependencies (ImGui, md4c, tidy, etc.) even under Homebrew.
- Applies small source patches to Tracy so it compiles with the Homebrew `capstone` 5.x API (AArch64 → ARM64 renames) and with newer macOS SDKs.

This tap is tailored for my own development environment. If you just need “a Tracy that installs and runs on current macOS via Homebrew”, this formula aims to provide exactly that. For stricter, upstream-style Homebrew packaging, treat this as a starting point and adjust as you like.
