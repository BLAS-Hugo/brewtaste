# Flutter Guidelines

## Riverpod

### Provider types

| Situation | Provider to use |
|---|---|
| Async data fetch (one-shot) | `FutureProvider` |
| Appwrite realtime stream | `StreamProvider` |
| Simple computed/derived value | `Provider` |
| Async state with actions (most screens) | `AsyncNotifier` + `@riverpod` |
| Sync state with actions | `Notifier` + `@riverpod` |

Use code generation (`riverpod_annotation`) for all notifiers. Avoid `StateProvider` and `ChangeNotifierProvider`.

### Provider placement

- Feature-scoped providers → `features/<feature>/presentation/providers/`
- Shared providers (e.g. current session, current user) → `shared/` or `core/`
- Repository providers → `features/<feature>/infra/`, injected into notifiers via `ref.watch`

### Notifier pattern

```dart
@riverpod
class LobbyNotifier extends _$LobbyNotifier {
  @override
  Future<LobbyState> build(String sessionId) async {
    // initial load — called automatically, drives AsyncValue state
  }

  Future<void> kickParticipant(String participantId) async {
    // 1. delete all votes for this participant in the session
    // 2. delete the participant document
    ref.invalidateSelf();
  }
}
```

- `build()` handles initial async load; `AsyncNotifier` wraps return value in `AsyncValue` automatically
- Side effects are methods on the notifier, never standalone providers
- Use `ref.invalidateSelf()` to force a reload after a mutation

### Realtime subscriptions

Wire Appwrite realtime inside `build()` using `ref.onDispose` to cancel on provider disposal:

```dart
@override
Future<SessionState> build(String sessionId) async {
  final subscription = appwriteRealtime.subscribe([
    'databases.$dbId.collections.$sessionsCollectionId.documents.$sessionId',
  ]);
  ref.onDispose(subscription.close);

  await for (final event in subscription.stream) {
    // parse event and update state
  }
}
```

---

## GoRouter

All routes are defined in `core/router/`. Route path strings are not hardcoded outside that file — export typed route helpers or `GoRoute` path constants.

### Redirect guards

Redirect logic (session expired, wrong status) goes in `redirect:` callbacks on `GoRoute`, not in screen `initState` or `build`.

```dart
GoRoute(
  path: '/session/:id/voting',
  redirect: (context, state) async {
    final session = await ref.read(sessionProvider(id).future);
    if (session.status != SessionStatus.tasting) return '/';
    return null;
  },
)
```

### Deep link entry point

`/join/:code` resolves the session ID from the code, then redirects to `/session/:id/lobby`. All join validation (session exists, not expired, not revealed) lives in this redirect.

---

## Widgets

### Widget base class

| Situation | Use |
|---|---|
| No state, no Riverpod | `StatelessWidget` |
| Reads/watches providers, no local state | `ConsumerWidget` |
| Reads/watches providers + local state (e.g. `AnimationController`, `FocusNode`) | `ConsumerStatefulWidget` |
| Local state only, no providers | `StatefulWidget` |

Prefer `ConsumerWidget` over wrapping a `StatelessWidget` in `Consumer`. Never use `StatefulWidget` just to hold a `TextEditingController` — use `ConsumerStatefulWidget` if you also need a provider.

### Screen structure

Screens (`*Screen`) own layout and connect the UI to the notifier. They are thin: read state, dispatch actions, delegate rendering to sub-widgets.

```dart
class LobbyScreen extends ConsumerWidget {
  const LobbyScreen({required this.sessionId, super.key});
  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(lobbyProvider(sessionId));

    return state.when(
      loading: () => const _LoadingView(),
      error: (e, _) => _ErrorView(error: e),
      data: (lobby) => _LobbyView(lobby: lobby, sessionId: sessionId),
    );
  }
}
```

### AsyncValue rendering

Always use `.when()` on `AsyncValue` at the screen level. Split into three named private widgets (`_LoadingView`, `_ErrorView`, `_DataView` or descriptive equivalents) rather than inline ternaries.

```dart
// Good
state.when(
  loading: () => const _LoadingView(),
  error: (e, _) => _ErrorView(error: e),
  data: (data) => _ContentView(data: data),
);

// Avoid
state.isLoading ? const CircularProgressIndicator() : Text(state.value!.name),
```

### Widget extraction

Extract a widget when any of these apply:
- `build` exceeds ~50 lines
- A sub-tree needs to rebuild independently from its parent
- The same combination of widgets appears in more than one place
- A widget has clear, nameable responsibility

Private widgets within the same file (prefixed `_`) are fine for screen-specific sub-trees. Move to `presentation/widgets/` when a widget is reused across screens in the same feature, and to `shared/widgets/` when used across features.

### Const constructors

Mark every widget constructor `const` unless it contains non-const fields. Pass `super.key` rather than `Key? key` in the constructor signature.

```dart
// Good
class BeerCard extends StatelessWidget {
  const BeerCard({required this.beer, super.key});
  final Beer beer;
}
```

### Forms and text fields

- Use `TextEditingController` in `ConsumerStatefulWidget`, dispose in `dispose()`
- Validate in the notifier (domain logic), not in `FormField` validators — validators are for format only (empty check, length)
- For the pseudo entry on join and beer name/brewery fields, trim input before passing to the notifier

### Loading states

Show a loading indicator while `AsyncValue.isLoading`. After an action (e.g. submitting a vote), set the button to disabled + show an inline spinner rather than replacing the full screen with a loader.

---

## Error Handling

Two categories — handle them differently:

**Business errors** (session not found, code invalid, session expired, user kicked): catch in the notifier, surface via state, show inline UI message. Do not send to Sentry.

**Unexpected errors** (Appwrite exceptions, parse failures, network errors): catch and call `Sentry.captureException` before re-surfacing via `AsyncValue.error`.

```dart
try {
  await repository.joinSession(code);
} on SessionNotFoundException {
  // Business error — no Sentry
  state = AsyncError(SessionNotFoundError(), StackTrace.current);
} on AppwriteException catch (e, st) {
  // Unexpected — report to Sentry
  Sentry.captureException(e, stackTrace: st);
  state = AsyncError(e, st);
}
```

---

## Naming Conventions

| Thing | Convention | Example |
|---|---|---|
| Screens | `PascalCaseScreen` | `LobbyScreen` |
| Notifiers | `PascalCaseNotifier` | `LobbyNotifier` |
| Providers (generated) | `camelCaseProvider` | `lobbyProvider` |
| Private sub-widgets | `_PascalCase` | `_ParticipantList` |
| Repository interfaces | `PascalCaseRepository` (abstract) | `SessionRepository` |
| DTOs | `PascalCaseDto` | `SessionDto` |
| Entities | `PascalCase` | `Session`, `Beer` |
| Enums | `PascalCase` values `camelCase` | `SessionStatus.waiting` |

---

## Blind Mode — Data Filtering

Filter `name` and `brewery` at the **infra layer** (repository implementation), not in the UI. The infra layer checks `isBlind && beer.status != revealed` and nulls those fields before returning the entity. No screen should contain blind-mode conditional logic on beer fields.
