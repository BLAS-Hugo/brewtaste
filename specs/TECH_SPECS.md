# BrewTaste — Specs techniques

---

## Stack

| Couche | Choix | Justification |
|---|---|---|
| Framework | Flutter | Cible Android + iOS |
| State management | Riverpod | Expérience existante, productivité |
| Navigation | GoRouter | Deep links natifs, déclaratif |
| Backend | Appwrite | DB, Auth anonyme, Realtime |
| Monitoring | Sentry | Error tracking + traces |
| Bière enrichissement | Open Food Facts API | Gratuit, public, best-effort |

---

## Cibles

- Android
- iOS

---

## Structure du projet

Organisation **feature-first** avec **clean architecture** par feature.

```
lib/
├── core/
│   ├── appwrite/          # client Appwrite, constantes, config
│   ├── router/            # GoRouter — définition des routes
│   └── errors/            # Sentry, error handling global
├── features/
│   ├── session/
│   │   ├── presentation/  # screens, widgets, providers
│   │   ├── domain/        # entities, repository interfaces, use cases
│   │   ├── data/          # models, DTOs, datasources
│   │   └── infra/         # implémentations repositories (Appwrite)
│   ├── voting/
│   │   ├── presentation/
│   │   ├── domain/
│   │   ├── data/
│   │   └── infra/
│   ├── results/
│   │   ├── presentation/
│   │   ├── domain/
│   │   ├── data/
│   │   └── infra/
│   └── beer/
│       ├── presentation/
│       ├── domain/
│       ├── data/
│       └── infra/
└── shared/
    ├── widgets/            # composants UI réutilisables
    ├── domain/             # entities partagées entre features
    └── infra/              # utilitaires infra partagés
```

---

## Navigation — Routes

```
/                          → HomeScreen
/session/create            → CreateSessionScreen
/session/:id/lobby         → LobbyScreen
/session/:id/voting        → VotingScreen
/session/:id/waiting       → WaitingScreen
/session/:id/results       → ResultsScreen
/join/:code                → deep link → redirect LobbyScreen
```

Deep link scheme : `brewtaste://join/:code`

`/join/:code` effectue un lookup de la session par code puis redirige vers `/session/:id/lobby`. Si session introuvable ou expirée → redirect `/` avec message d'erreur.

---

## Appwrite — Collections

### `sessions`

| Champ | Type | Notes |
|---|---|---|
| `hostId` | string | userId Appwrite |
| `status` | enum | `waiting` / `tasting` / `revealed` |
| `code` | string | `BREW-XXXX`, unique, index |
| `isBlind` | boolean | Mode aveugle global |
| `guessFields` | string[] | Parmi : `style`, `brewery`, `hops`, `aromas` |
| `createdAt` | datetime | Pour expiration 24h |

### `participants`

| Champ | Type | Notes |
|---|---|---|
| `sessionId` | string | Relation `sessions` |
| `userId` | string | userId Appwrite anonyme |
| `pseudo` | string | Choisi à l'arrivée |
| `isHost` | boolean | |
| `joinedAt` | datetime | |

### `beers`

| Champ | Type | Notes |
|---|---|---|
| `sessionId` | string | Relation `sessions` |
| `name` | string | Obligatoire |
| `brewery` | string | Obligatoire, masqué si `isBlind` jusqu'à révélation |
| `style` | string? | Nullable |
| `hops` | string? | Nullable |
| `aromas` | string? | Nullable |
| `status` | enum | `pending` / `voting` / `revealed` |
| `addedAt` | datetime | Sert également à l'ordre de passage |

### `votes`

| Champ | Type | Notes |
|---|---|---|
| `sessionId` | string | |
| `beerId` | string | Relation `beers` |
| `userId` | string | |
| `score` | integer | 1–10, null si skip |
| `guesses` | string | JSON `{ style?, brewery?, hops?, aromas? }` |
| `hasSkipped` | boolean | |

---

## Règles métier Appwrite

- **Kick participant** — suppression en cascade côté client (MVP) : votes du `userId` dans la session supprimés avant suppression du document `participant`. À migrer en Appwrite Function post-MVP.

---

## Appwrite — Permissions

| Collection | Create | Read | Update | Delete |
|---|---|---|---|---|
| `sessions` | tout utilisateur auth | tout utilisateur auth | hostId uniquement | hostId uniquement |
| `participants` | tout utilisateur auth | tout utilisateur auth | userId = self ou hostId | hostId uniquement |
| `beers` | hostId uniquement | tout utilisateur auth | hostId uniquement | hostId uniquement |
| `votes` | userId = self | hostId + userId = self | ❌ jamais | ❌ jamais |

> Le lock des votes est garanti par l'absence de permission `update` sur la collection `votes`.

---

## Appwrite — Realtime subscriptions

| Subscription | Consommateur | Utilité |
|---|---|---|
| `databases.[db].collections.sessions.documents.[id]` | Tous | Détecter changement de `status` |
| `databases.[db].collections.participants.documents` | Hôte | Arrivées, départs, kicks en live |
| `databases.[db].collections.votes.documents` | Hôte | Compteur votes reçus par round |

---

## Génération du code session

- Format : `BREW-XXXX` (4 chiffres, `0001` → `9999`)
- Généré côté client via `Random().nextInt(9999) + 1`
- Vérification unicité avant création : lookup Appwrite sur `code` + `status != revealed` + `createdAt > now - 24h`
- En cas de collision : retry jusqu'à 5 fois, sinon erreur remontée à Sentry

---

## Calcul des résultats

Entièrement **côté client** au moment de la révélation.

- Fetch de tous les votes de la session en une requête
- Moyenne par bière : votes non-skippés uniquement
- Tri : note moyenne décroissante, égalité départagée par nombre de votes valides
- Comparaison guess : `guess.toLowerCase().trim() == truth.toLowerCase().trim()`

---

## Sentry

```dart
// main.dart
await SentryFlutter.init((options) {
  options.dsn = Env.sentryDsn;
  options.tracesSampleRate = 0.3;
}, appRunner: () => runApp(ProviderScope(child: App())));
```

- Erreurs **inattendues** (Appwrite exceptions, parsing errors) → remontées automatiquement
- Erreurs **métier** (session introuvable, code invalide, session expirée) → gérées en UI, non envoyées à Sentry

---

## Deep links

- Scheme custom : `brewtaste://`
- Package : `app_links`
- Android : intent filter dans `AndroidManifest.xml`
- iOS : scheme déclaré dans `Info.plist`
- Universal Links / App Links : hors scope MVP

---

## Open Food Facts

- API publique, aucune clé requise
- Endpoint : `https://world.openfoodfacts.org/api/v2/product/{barcode}`
- Champs utilisés : `product_name`, `brands`
- Couverture craft beer : limitée — fallback automatique vers saisie manuelle si `not found`

---

## Hors scope MVP

- Appwrite Functions (nettoyage sessions, calcul serveur)
- Export résultats PDF / image
- Notifications push
- Universal Links / App Links
- Base de données bières craft communautaire