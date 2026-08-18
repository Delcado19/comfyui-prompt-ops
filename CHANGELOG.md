## [1.6.3](https://github.com/Delcado19/comfyui-prompt-ops/compare/v1.6.2...v1.6.3) (2026-08-18)


### Bug Fixes

* crash and cross-platform bugs in service scripts and installers ([6d2b45f](https://github.com/Delcado19/comfyui-prompt-ops/commit/6d2b45fafee7004bda523edc98ee123e47776110))

## [1.6.2](https://github.com/Delcado19/comfyui-prompt-ops/compare/v1.6.1...v1.6.2) (2026-08-17)


### Bug Fixes

* restart_services.ps1 never actually started the Espanso daemon ([17a8e27](https://github.com/Delcado19/comfyui-prompt-ops/commit/17a8e274126c31e3c9cd73bf1b148845ad04da4c))

## [1.6.1](https://github.com/Delcado19/comfyui-prompt-ops/compare/v1.6.0...v1.6.1) (2026-08-17)


### Bug Fixes

* installer misdetects Winget failures and loses PATH additions ([0fd3eb5](https://github.com/Delcado19/comfyui-prompt-ops/commit/0fd3eb5b378b13d5ed1292440b89ceccfb12beb7))

# [1.6.0](https://github.com/Delcado19/comfyui-prompt-ops/compare/v1.5.2...v1.6.0) (2026-05-19)


### Features

* add admin header logo ([03ad9c6](https://github.com/Delcado19/comfyui-prompt-ops/commit/03ad9c6a5980d66f36a0bd25e7df3b20c54cda05))

## [1.5.2](https://github.com/Delcado19/comfyui-prompt-ops/compare/v1.5.1...v1.5.2) (2026-05-19)


### Bug Fixes

* simplify admin editor fields ([fc835a4](https://github.com/Delcado19/comfyui-prompt-ops/commit/fc835a4f3e16a530de1385509c9f561a6e2ddc78))

## [1.5.1](https://github.com/Delcado19/comfyui-prompt-ops/compare/v1.5.0...v1.5.1) (2026-05-19)


### Bug Fixes

* make admin log panel dismissible ([23339ed](https://github.com/Delcado19/comfyui-prompt-ops/commit/23339ed0a8b90b1283222f548088349fda72ddee))

# [1.5.0](https://github.com/Delcado19/comfyui-prompt-ops/compare/v1.4.0...v1.5.0) (2026-05-19)


### Features

* add prompt library admin ([f5338f7](https://github.com/Delcado19/comfyui-prompt-ops/commit/f5338f7c1a7b9c721a56947ddb09756d0b623e6e))

# Changelog

All notable changes to this project will be documented in this file.

The format follows **Keep a Changelog** and **Semantic Versioning**.

---

## [Unreleased]

### Added

- Header logo for the local prompt library admin, inspired by the project banner artwork.
- Local web admin for editing prompt categories and snippets through a central prompt library.
- Central `library/prompt_library.yml` source of truth with generators for Espanso snippets, prompt builder output, and snippet documentation.
- Import and generation scripts for migrating existing snippets into the library workflow.
- Model-aware prompt presets for Z-Image Turbo, Z-Image Base, Flux2 Klein, SDXL Cinenauts, wildcardXL fusion, and Qwen edit workflows.
- Expanded style, context, character, scene, camera, lighting, quality, negative, and NSFW prompt components based on local ComfyUI output patterns.
- Prompt snippet naming guidance for model-adapted triggers.

### Fixed

- Windows launcher now keeps the admin server logs visible and stops the server when its window is closed.

---

## [1.4.0](https://github.com/Delcado19/comfyui-prompt-ops/compare/v1.3.7...v1.4.0) (2026-05-19)

### Added

- PowerShell parser validation for local development and GitHub CI.

### Changed

- Installer now prefers Winget for Espanso and CopyQ, with Scoop as the fallback package manager.

---

## [1.3.7](https://github.com/Delcado19/comfyui-prompt-ops/compare/v1.3.6...v1.3.7) (2026-03-18)

### Bug Fixes

- test changelog final ([cd2a9d3](https://github.com/Delcado19/comfyui-prompt-ops/commit/cd2a9d33fc596c5b53415895b9721667f5f58af9))

---

## [1.3.6](https://github.com/Delcado19/comfyui-prompt-ops/compare/v1.3.5...v1.3.6) (2026-03-18)

### Bug Fixes

- enable changelog generation ([0082f57](https://github.com/Delcado19/comfyui-prompt-ops/commit/0082f579e568e81a65c44c77f370e7da123bf0e1))

---

## [1.3.5](https://github.com/Delcado19/comfyui-prompt-ops/compare/v1.3.4...v1.3.5) (2026-03-18)

### Bug Fixes

- use correct semantic-release config filename ([e4e27ca](https://github.com/Delcado19/comfyui-prompt-ops/commit/e4e27ca3cd0a7303a102c17f07054400f93e15c4))

---

## [1.2.0]

### Added

- automatic prompt builder generation
- snippet documentation generator
- developer utility scripts
- logging system for installer (`logs/install.log`)
- extended project documentation

### Improved

- installer dependency checks
- developer tooling
- repository structure
- README documentation

---

## [1.1.0]

### Added

- automated installer
- snippet installation system
- dependency checks
- espanso reload
- service restart logic

### Improved

- project structure
- developer tooling
- README documentation

---

## [1.0.0]

### Initial Release

- base snippet architecture
- modular prompt system
- espanso integration
