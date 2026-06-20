# Astro Portable

A cross-platform mobile sky-chart app (iOS + Android) built with Flutter.  
Draws a real-time astrological wheel using the Swiss Ephemeris — **fully offline, computed on-device** via FFI.

---

## Features

- Live geocentric planet positions for any date/time
- Time steppers: ±hour / ±day / ±month / ±year with correct roll-over
- Jump to any date (preserves current wall-clock time-of-day)
- "Back to Now" reset
- Toggleable bodies: main planets, lunar nodes, Lilith, main-belt asteroids, Centaurs, and TNOs
- Aspect lines (conjunction, sextile, square, trine, opposition) colour-coded by type
- Glyph fan-out to prevent label collisions when bodies cluster
- Retrograde marker ("R") on glyphs when a body's speed is negative
- Dark space-themed UI

---

## Prerequisites

- Flutter ≥ 3.3.0  
- Dart ≥ 3.3.0  
- iOS 12+ / Android 5.0+ (API 21+)

---

## Setup

### 1. Create the Flutter project shell

Because Flutter is not pre-initialised in this repo, run once to generate the
Android / iOS platform directories:

```bash
cd astro-portable
flutter create --project-name astro_portable --org com.example .
```

`flutter create` in an existing directory does **not** overwrite `lib/`,
`pubspec.yaml`, or `analysis_options.yaml`; it only generates the missing
platform boilerplate.

### 2. Install Dart dependencies

```bash
flutter pub get
```

### 3. Obtain Swiss Ephemeris data files

The computation engine is `libswe` (Swiss Ephemeris by Astrodienst).  
The Dart `sweph` package bundles the native library; you only need to supply
the **data files** (`.se1`).

#### Minimum files (main planets, nodes, Lilith — always on)

| File | Covers |
|------|--------|
| `sepl_18.se1` | Sun–Pluto, main planets (~1800–2399 CE) |
| `semo_18.se1` | Moon (~1800–2399 CE) |
| `sefstars.txt` | Fixed stars (optional, not currently used) |

> The `18` in the name is the file block covering Julian Days around J2000.
> If your target date range extends beyond 2399 CE or before 1800 CE, you
> need additional blocks (`_17`, `_19`, etc.).

#### Main-asteroid file (enables Ceres, Pallas, Juno, Vesta, Hygiea)

| File | Covers |
|------|--------|
| `seas_18.se1` | Main-belt asteroids MPC 1–10000 (~1800–2399 CE) |

#### Individual TNO / Centaur files

For each large asteroid/TNO listed below, place its individual `.se1` file:

| Body | MPC # | File |
|------|-------|------|
| Hygiea | 10 | included in `seas_18.se1` |
| Pholus | 5145 | `se005145s.se1` |
| Nessus | 7066 | `se007066s.se1` |
| Chariklo | 10199 | `se010199s.se1` |
| Varuna | 20000 | `se020000s.se1` |
| Ixion | 28978 | `se028978s.se1` |
| Quaoar | 50000 | `se050000s.se1` |
| Sedna | 90377 | `se090377s.se1` |
| Orcus | 90482 | `se090482s.se1` |
| Eris | 136199 | `se136199s.se1` |
| Haumea | 136108 | `se136108s.se1` |
| Makemake | 136472 | `se136472s.se1` |
| Gonggong | 225088 | `se225088s.se1` |

> If a file is missing for an optional body, the app silently skips it.
> The main planets and Chiron fall back to the built-in Moshier ephemeris
> if no `.se1` files are present at all (lower accuracy, still works offline).

#### Where to download

- **Official Astrodienst FTP**: <ftp://ftp.astro.com/pub/swisseph/ephe/>  
  (Direct links not provided here; copy the URL into your browser or FTP client.)
- Or from the [Swiss Ephemeris GitHub mirror](https://github.com/aloistr/swisseph)
  in the `ephe/` directory.

### 4. Place the files

Copy all downloaded `.se1` files into:

```
assets/ephe/
```

Flutter will bundle them into the app binary. On first launch, the app
extracts them to the device's documents directory and points `libswe` there.

### 5. Run

```bash
flutter run          # connected device or emulator
flutter run --release
```

---

## Project layout

```
lib/
├── main.dart                          # Entry point + ephemeris init
├── models/
│   ├── celestial_body_definition.dart # All body metadata (data-driven)
│   ├── body_position.dart             # Computed position for one body
│   └── aspect.dart                   # Aspect types + computation
├── services/
│   └── ephemeris_service.dart         # Wraps sweph FFI; Julian Day; asset extraction
├── providers/
│   └── chart_provider.dart            # Riverpod state: time, enabled bodies, positions
├── painters/
│   └── wheel_painter.dart             # CustomPainter drawing the zodiac wheel
├── widgets/
│   ├── time_stepper.dart              # H/D/M/Y stepper bar
│   ├── body_panel.dart                # Bottom-sheet body toggle panel
│   └── date_jump_dialog.dart          # "Jump to date" dialog
└── screens/
    └── home_screen.dart               # Main layout
assets/
└── ephe/                              # Place .se1 files here (see above)
```

---

## Adding new bodies

Everything is driven by `kAllBodies` in
`lib/models/celestial_body_definition.dart`.  Add a new `CelestialBodyDef`
entry with:

- `sweId` = `10000 + MPC_number` for numbered minor planets
- place the matching `seNNNNNs.se1` file in `assets/ephe/`
- the body automatically appears in the bottom-sheet panel under its category

---

## Coordinate convention

The wheel renders with **0° Aries at the 9-o'clock position (left)**, and
ecliptic longitude increases **counter-clockwise** — matching the traditional
Western chart orientation:

```
         ♑ Capricorn (270°)
              ↑  12
    ♒ Aqu  11   1  ♐ Sag
  ♓ Pis  10       2  ♏ Sco
9 ← ♈ Aries (0°)   ♎ Libra (180°) → 3
  ♉ Tau  8        4  ♍ Vir
    ♊ Gem  7    5  ♌ Leo
              ↓  6
         ♋ Cancer (90°)
```

Houses and Ascendant are **not included in v1** — the code is structured so
that a `HouseCusp` model and a `LocationProvider` can be added later without
touching the existing painters or providers.

---

## Swiss Ephemeris — License & Attribution

The Swiss Ephemeris is © Astrodienst AG, Zürich, Switzerland.

This app uses the Swiss Ephemeris under the **GNU Affero General Public License
(AGPL) v3**, or alternatively under a professional license from Astrodienst
if you distribute a closed-source app.

> **Required attribution** (display in your About screen or app store listing):
>
> *This app uses the Swiss Ephemeris, © 1997–2024 Astrodienst AG, Zürich.*
> *Swiss Ephemeris is licensed under the AGPL v3.*
> *See https://www.astro.com/swisseph/*

If your app is closed-source or commercial, obtain a professional license:
<https://www.astro.com/swisseph/swephinfo_e.htm#proflic>

The Dart FFI bindings are provided by the `sweph` package (MIT license).

---

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| Planet positions clearly wrong | Verify the correct `.se1` block covers your target date |
| TNO/asteroid not appearing | Add the matching `seNNNNNs.se1` to `assets/ephe/` |
| App crashes on startup | Check `flutter logs` — likely a missing FFI symbol; ensure `sweph` version matches Dart SDK |
| Glyphs rendering as boxes | The device font lacks those Unicode code points; glyphs fall back to the 3-letter abbreviations automatically in future version |
