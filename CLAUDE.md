# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

This project uses [FVM](https://fvm.app/) to pin the Flutter version.

```bash
# Install dependencies
fvm flutter pub get

# Run all tests (local disk-access tests included)
fvm flutter test

# Run CI tests (excludes @Tags(['local']) tests that need disk access)
fvm flutter test --exclude-tags local

# Run a single test file
fvm flutter test test/daily_reading_parsing_test.dart

# Lint / static analysis
fvm flutter analyze

# Generate i18n files (after editing assets/i18n/*.json)
fvm dart run slang
```

## Architecture

**State management**: BLoC pattern (`flutter_bloc`). Two top-level BLoCs are provided at the widget tree root in `main.dart`:
- `ReadingBloc` (`lib/screens/reader/bloc/`) — drives all reading data: which volume is active, current day's content, navigation between days, and progress tracking (completed/missed). This is the core of the app.
- `ThemeBloc` (`lib/theme/bloc/`) — theme mode (light/dark/system) and reading font size.

**Data flow**:
```
Asset files (.txt)
  → LocalReadingStorage   (loads raw text via rootBundle or File)
  → ReadingRepository     (regex-parses text into Reading domain objects)
  → ReadingBloc           (holds state, responds to events)
  → UI screens/widgets    (BlocBuilder/BlocListener)
```

**Domain model** (`lib/screens/reader/domain/reading.dart`):
- `Reading` — date string, scripture reference, quote body, dailyReading reference, sermon title.
- `ReadingEntry` — a calendar day with its completion status.
- `Volume` enum (`lib/models/volume.dart`) — defines per-volume asset paths, SharedPreferences suffix, display titles, banner images, and app bar colors.

**Navigation**: GoRouter (`main.dart`). Key routes: `/` (home), `/reader`, `/book-selection`, `/foreword-preface`, `/missed-days/book-:volumeId`, `/settings`.

**Persistence**: `SharedPreferences` for reading progress and user settings. Volume I uses bare keys; Volume II appends `_v2`; add `_v3` for Volume III. See `Volume.storageSuffix`.

## Asset file formats

Volumes live under `assets/volume_I/`, `assets/volume_II/`, `assets/volume_III/`. Each has a `daily_readings/` folder and optional static pages (`Foreword.txt`, `Preface.txt`, `preface.txt`).

Daily reading filename convention: `Month_D.txt` (e.g., `January_1.txt`, `December_31.txt`).

**Volume I** (366 files, includes Feb 29 — use leap year 2024 when testing):
```
January 1

(Book chapter:verse)

[quote body]

Daily Reading: Reference

[[[Sermon Title — Date]]]
```

**Volume II** (365 files, no Feb 29 — use 2023 when testing):
```
January 1

(Book chapter:verse)

[quote body]

Parallel Scripture(s): Reference

[[[Sermon Title — Date]]]
```

**Volume III** (365 files, no Feb 29 — use 2023 when testing). Files are **UTF-16 LE** with BOM — `LocalReadingStorage` must decode them explicitly. No "Daily Reading:" or "Parallel Scriptures:" section:
```
Day N⇥The Family Altar⇥January 1

(Book chapter:verse)

[quote body]

[[[Sermon Title — Date]]]
```

## Parsing (`lib/repository/reading_repository.dart`)

`ReadingRepository.fetchReading` uses regex to extract each field:
- **Date**: first `Month D` match.
- **Scripture**: first `(Book ch:v[-v])` match in parentheses.
- **Quote**: text between end of scripture and start of `Daily Reading:` / `Parallel Scriptures:` / `[[[` marker.
- **Daily reading / Parallel scriptures**: volume-specific label lookup; empty string when the section doesn't exist (Volume III).
- **Sermon title**: content inside `[[[…]]]`.

When `sectionIndex == -1` (no daily-reading label), `quoteEndIndex` falls back to `sermonTitleIndex`.

## Testing conventions

`test/daily_reading_parsing_test.dart` is tagged `@Tags(['local'])` because it reads assets directly from disk via `File` (not `rootBundle`) to avoid the Flutter binding overhead. CI excludes these tests with `--exclude-tags local`. Run locally without the flag to execute them.

The test iterates every day of the target year for each volume and asserts that `date`, `scripture`, `quote`, and `title` are all non-empty.
