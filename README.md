<p align="center">
  <img src="images/icon.png" alt="Shared Menu" width="120">
</p>

# Shared Menu

Shared Menu is a Flutter app to plan lunches and dinners and share the plan with other people. Everyone who joins the same menu sees and edits the same meals.

## Features

- Scrollable list of the next 14 days, each with a lunch and a dinner entry
- Set or change a meal
- Create a new menu, or join an existing one by scanning its QR code
- Share your menu by showing its QR code
- English and Italian localisations


## Getting started

Requirements: Flutter SDK with Dart `>=3.0.0 <4.0.0`.

```bash
git clone https://github.com/alebar12/shared-menu.git
cd shared-menu
flutter pub get
flutter run
```

Supported targets: Android, Linux desktop and web. QR code scanning relies on
`mobile_scanner` and needs a camera, so it is only usable on devices that
provide one.

### Building

```bash
flutter build apk      # Android
flutter build linux    # Linux desktop
flutter build web      # Web
```

### Localisation

Translations live in `lib/l10n/app_en.arb` and `lib/l10n/app_it.arb`. The
generated Dart code is produced by the Flutter tool according to `l10n.yaml`:

```bash
flutter gen-l10n
```

To add a language, copy an existing `.arb` file, translate the values and keep
the `@key` metadata blocks in sync.

## Project layout

```
lib/
  clients/      API clients
  constants/    application constants
  dto/          Application data transfer objects
  l10n/         .arb translation sources and generated localisations
  services/     Application services
  widgets/      Application UI widgets
  main.dart     app entry point and provider wiring
test/           unit and widget tests mirroring lib/
```


## Tests

```bash
flutter test
```

Static analysis uses `flutter_lints` via `analysis_options.yaml`:

```bash
flutter analyze
```
