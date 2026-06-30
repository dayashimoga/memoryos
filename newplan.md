# MemoryOS — Feature Activation, App Motto & Enhancement Plan

## What MemoryOS Is (Core Motto)

> **MemoryOS is your private, offline-first digital brain** — a unified platform to index, search, organize, transform, and recall everything you've ever saved, powered by Rust speed and local AI.

The app's key value propositions (currently not highlighted on first launch):
1. **Universal File Memory** — index and semantically search all your local files in milliseconds
2. **Offline AI Assistant** — local LLM for summarize, chat, explain — no cloud, no privacy risk
3. **Smart Storage Optimizer** — find duplicates, blurry images, large files, reclaim space automatically
4. **Secure Vault** — AES-256 encrypted file storage built into the OS layer
5. **Digital Toolbox** — convert documents, resize images, normalize audio, manage archives — all offline

---

## Root Cause: Why Features Are Inaccessible

| Issue | Root Cause |
|---|---|
| All Toolbox tools fail silently | `toolboxRepo` in Dart calls the stub — never wired to Rust FFI |
| File converter shows placeholder paths | Text fields pre-filled with `/path/to/...` — no file picker integration |
| No files on Home after install | `memoryos_init()` wasn't called with data dir → DB never opened |
| Toolbox Archive Extract fails | Path text is hardcoded, no platform file-picker wired to it |
| Home shows "No files yet" forever | Import sheet UI exists but `importFile()` calls stub |
| App motto/purpose invisible | No onboarding screen, no "what is this?" hero section |
| Image toolkit disabled | `processImage` wired to stub, not `RustFfi.processImage` |
| Audio normalizer disabled | `normalizeWav` wired to stub, not FFI |

---

## Proposed Changes

### Phase 1 — Wire Existing Toolbox to Real FFI (Highest Priority)

The Rust `toolbox.rs` has real implementations for: document conversion, image resizing, WAV normalization, ZIP archives, encrypted backups. The Flutter `FfiToolboxRepository` doesn't exist yet — the Toolbox page calls `ServiceLocator.toolboxRepo` which is a stub.

#### [MODIFY] [ffi_repositories.dart](file:///h:/memoryos/apps/flutter_app/lib/core/domain/ffi_repositories.dart)
- Add `FfiToolboxRepository` class with real calls to:
  - `RustFfi.convertDocument(input, output)` → returns `int` (0=success)
  - `RustFfi.processImage(input, output, w, h, quality)`
  - `RustFfi.normalizeWav(input, output)`
  - `RustFfi.archiveList/Create/Extract`
  - `RustFfi.backupPerform/Restore`

#### [MODIFY] [service_locator.dart](file:///h:/memoryos/apps/flutter_app/lib/core/di/service_locator.dart)
- Wire `_toolboxRepo = FfiToolboxRepository()` instead of `StubToolboxRepository()`

#### [MODIFY] [toolbox_page.dart](file:///h:/memoryos/apps/flutter_app/lib/features/toolbox/pages/toolbox_page.dart)
- Replace hardcoded path text fields with **FilePicker** buttons for all input paths
- Show a banner "FFI engine not available — build with native library" when stub is active
- Auto-suggest output path based on input filename

#### [MODIFY] [rust_ffi_stub.dart](file:///h:/memoryos/apps/flutter_app/lib/core/ffi/rust_ffi_stub.dart)
- Add missing stub methods: `categorizeText`, `toggleFavorite`, `listFavorites`

---

### Phase 2 — Home Page: Show App Motto + Onboarding

#### [MODIFY] [home_page.dart](file:///h:/memoryos/apps/flutter_app/lib/features/home/pages/home_page.dart)
- Add a **MottoHeroBanner** at the top (shown once, dismissible after first file import):
  - "Your Private Digital Brain" heading
  - Three pillars: Search Everything · Secure Vault · AI Insights
  - "Start by importing files" CTA button  
- Quick Actions cards: Import Files, Open Toolbox, Scan Duplicates, AI Chat
- Fix Import Files action to actually trigger `FilePicker` → `indexFile()` via FFI

---

### Phase 3 — Storage & Duplicate Finder (Make Accessible)

The duplicate detection is already implemented in Rust. The storage scan bloc exists. The UI just shows 0 duplicates because `analyzeStorage()` never gets called on app start.

#### [MODIFY] [service_locator.dart](file:///h:/memoryos/apps/flutter_app/lib/core/di/service_locator.dart)
- After FFI init, trigger a background `StorageBloc.add(StorageScanRequested())` if files > 0

---

### Phase 4 — New Features (Value-Adding Enhancements)

| Feature | Description | Effort |
|---|---|---|
| **Quick Import Drop Zone** | Drag-and-drop files on Home page (desktop) | Low |
| **Recently Used History** | Smart "Jump to where you left off" section | Low |
| **File Preview Panel** | In-app preview for PDF, image, text without leaving app | Medium |
| **Smart Rename** | AI-powered batch rename using file content | Medium |
| **Export Collections** | Export a Collection as ZIP with manifest JSON | Low |
| **Onboarding Tour** | 4-step interactive tour on first launch | Low |
| **FFI Status Indicator** | Header badge showing "Engine Active / Stub Mode" | Low |
| **Quick Stats Widget** | Animated counters: files indexed, space saved, queries run | Low |

---

## Verification Plan

### Automated Tests
```bash
docker compose run --rm flutter-test
docker compose run --rm rust-test
docker compose run --rm flutter-build-android
```

### Manual Verification
1. Open Toolbox → Document Convert → pick a `.md` file → convert → confirm `.html` file created
2. Home page → Import Files → pick 5 images → confirm they appear in Recent Files
3. Storage → Scan → confirm duplicate count > 0 for test files
4. Verify app title/motto visible on first launch
5. Verify FFI status badge shows "Engine Active" when library loaded

---

## Execution Order

1. `ffi_repositories.dart` → Add `FfiToolboxRepository` with real FFI calls
2. `rust_ffi_stub.dart` → Add missing stub methods  
3. `service_locator.dart` → Wire FfiToolboxRepository + trigger storage scan
4. `toolbox_page.dart` → Add file pickers, fix all actions
5. `home_page.dart` → Add motto hero banner + fix import action
6. New: `onboarding_page.dart` → First launch onboarding flow
7. New: `ffi_status_widget.dart` → Engine status indicator in app bar
