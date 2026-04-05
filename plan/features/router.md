# Router — Implementation Plan

**Branch:** `feat/core-router`  
**Phase:** 1.3 + 1.4

## Goal

Set up GoRouter as the navigation system and wire `app_links` for deep link handling (`brewtaste://join/BREW-XXXX`). Routes are added per feature branch — only `/` is defined here.

## Packages

- `go_router: ^17.2.0`
- `app_links: ^7.0.0`

## Structure

```
lib/core/router/
├── app_router.dart        # routerProvider + route definitions
└── deep_link_handler.dart # AppLinks stream → router.go()
```

## Key decisions

- **Auth guard in `main.dart`** — router only renders inside `AsyncData()`. Simpler than a root redirect that handles loading state.
- **Routes added per feature** — `app_router.dart` only has `/` now. Each feature branch adds its routes.
- **Deep link handler as keepAlive provider** — initialized once after auth resolves, never disposed.
- **`_PlaceholderScreen`** — private widget in `app_router.dart`, replaced per feature branch.

## Native config

- Android: intent filter for `brewtaste://` in `AndroidManifest.xml`
- iOS: `CFBundleURLTypes` in `Info.plist`
