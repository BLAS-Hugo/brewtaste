# BrewTaste — Product Requirements Document

**Version** : 1.0 — MVP
**Plateforme** : Android, iOS
**Statut** : En cours de spécification

---

## 1. Vue d'ensemble

### 1.1 Concept

BrewTaste est une application mobile de dégustation de bières en groupe. Un hôte crée une session, invite des participants via code ou QR code, et présente des bières une par une. Chaque participant note chaque bière et tente de deviner ses caractéristiques. Les résultats sont révélés simultanément à la clôture de la session par l'hôte.

### 1.2 Problème adressé

Il n'existe pas d'outil mobile simple et dédié pour organiser une dégustation de bières en groupe. Les solutions existantes (Untappd, etc.) sont orientées réseau social et ne supportent pas le flow en temps réel d'une soirée dégustation structurée.

### 1.3 Cible utilisateur

Amateurs de bières craft souhaitant organiser des dégustations entre amis, de manière ludique et structurée, sans contrainte de compte ou d'inscription.

---

## 2. Objectifs MVP

- Permettre à un hôte de créer et piloter une session de dégustation en moins de 2 minutes
- Permettre à des participants de rejoindre sans création de compte
- Collecter les notes et guesses de chaque participant par bière
- Révéler les résultats de manière simultanée et lisible à la fin

---

## 3. Rôles

| Rôle | Description |
|---|---|
| **Hôte** | Crée la session, ajoute les bières, pilote le déroulé, clôture la session |
| **Participant** | Rejoint une session existante, note et tente de deviner les bières |

Aucun compte requis. L'authentification est anonyme et automatique (Appwrite Auth).

---

## 4. Fonctionnalités

### 4.1 Création de session

L'hôte configure la session avant de la partager.

**Champs requis :**
- Mode aveugle (`isBlind`) — booléen, global pour toute la session
  - `true` : nom et brasserie masqués pendant le vote
  - `false` : nom et brasserie visibles, guess sur brasserie désactivé automatiquement
- Guess fields actifs — sélection parmi : Style, Brasserie *(mode aveugle uniquement)*, Houblons, Arômes

**Résultat :**
- Un code court unique est généré automatiquement (`BREW-XXXX`, 4 chiffres)
- Un QR code est généré côté client depuis ce code
- La session est créée en statut `waiting`

---

### 4.2 Rejoindre une session

**Méthodes d'accès :**
- Saisie manuelle du code `BREW-XXXX`
- Scan du QR code affiché par l'hôte
- Deep link `brewtaste://join/BREW-XXXX`

**À l'arrivée :**
- Le participant choisit un pseudo affiché dans le lobby
- L'authentification anonyme est effectuée automatiquement si non existante

**Contraintes :**
- Un code n'est valide que si la session est en statut `waiting` ou `tasting` et a été créée il y a moins de 24h
- Un participant ne peut pas rejoindre une session en statut `revealed`

---

### 4.3 Lobby

**Hôte :**
- Voit la liste des participants arriver en temps réel
- Peut kicker un participant (suppression de son document + de tous ses votes dans la session)
- Lance la session quand il le souhaite → statut passe à `tasting`

**Participant :**
- Voit la liste des participants connectés en temps réel
- Attend que l'hôte lance la session
- Si kické : redirigé vers l'accueil

---

### 4.4 Déroulé de la session

La session avance bière par bière, entièrement pilotée par l'hôte.

#### Côté hôte

Pour chaque bière :
1. Ajoute une bière
   - Via scan code-barre → enrichissement automatique Open Food Facts (best-effort)
   - Via saisie manuelle
   - Champs : Nom *(obligatoire)*, Brasserie *(obligatoire)*, Style, Houblons, Arômes *(nullable)*
2. Lance le vote → statut bière passe à `voting`
3. Voit le nombre de votes reçus en temps réel
4. Peut passer à la bière suivante à tout moment, même sans votes complets
5. Peut modifier les informations d'une bière entre deux rounds
6. Clôture la session pour révéler les résultats → statut session passe à `revealed`

#### Côté participant

Pour chaque bière :
- Donne une note via slider (1–10, entiers)
- Remplit les guess fields activés par l'hôte pour la session :
  - Mode aveugle : Style, Brasserie, Houblons, Arômes (selon activation)
  - Mode non-aveugle : Style, Houblons, Arômes (selon activation)
- Peut skipper ("je n'ai pas goûté cette bière")
- Vote locké après validation — non modifiable
- Voit un écran d'attente entre les rounds

#### États de session

```
waiting → tasting → revealed
```

| État | Hôte | Participants |
|---|---|---|
| `waiting` | Lobby, peut lancer | Lobby, attente |
| `tasting` | Gestion des rounds | Vote / attente entre rounds |
| `revealed` | Résultats | Résultats |

#### États d'une bière

```
pending → voting → revealed
```

---

### 4.5 Résultats

Révélés simultanément à tous les participants à la clôture de la session.

**Écran principal :**
- Classement des bières par note moyenne décroissante
- Indicateur `X/Y ont goûté` par bière
- Égalité de moyenne : départagée par nombre de votes valides

**Modal détail par bière :**
- Informations complètes révélées : nom, brasserie, style, houblons, arômes
- Notes individuelles par participant avec leur pseudo
- Guesses de chaque participant comparés à la réalité (✓ / ✗)
- Participants ayant skipé affichés avec tirets (—)

---

## 5. Règles métier

| Règle | Détail |
|---|---|
| Vote locké | Aucune modification possible après validation — garanti par les permissions Appwrite (pas d'update sur `votes`) |
| Skip exclu de la moyenne | Les votes `hasSkipped: true` ne sont pas comptabilisés dans la note moyenne |
| Kick en cascade | Le kick d'un participant supprime son document ET tous ses votes dans la session |
| Validité du code | Code actif uniquement si session non révélée et créée il y a moins de 24h |
| Unicité du code | Vérification en DB avant création, retry jusqu'à 5 fois en cas de collision |
| Champs sensibles | `name` et `brewery` filtrés côté app tant que `beer.status != revealed` en mode aveugle |
| Bière 0 vote | Affichée sans moyenne ("Personne n'a goûté") |
| Votes post-kick | Les votes d'un participant kické sont supprimés |

---

## 6. Architecture technique

### 6.1 Stack

| Couche | Choix |
|---|---|
| Framework | Flutter — Android + iOS |
| State management | Riverpod |
| Navigation | GoRouter |
| Backend | Appwrite (DB, Auth anonyme, Realtime) |
| Monitoring | Sentry |
| Enrichissement bière | Open Food Facts API (best-effort) |

### 6.2 Structure projet

Organisation feature-first avec clean architecture par feature.

```
lib/
├── core/
│   ├── appwrite/
│   ├── router/
│   └── errors/
├── features/
│   ├── session/        { presentation, domain, data, infra }
│   ├── voting/         { presentation, domain, data, infra }
│   ├── results/        { presentation, domain, data, infra }
│   └── beer/           { presentation, domain, data, infra }
└── shared/
    ├── widgets/
    ├── domain/
    └── infra/
```

### 6.3 Routes

```
/                          → HomeScreen
/session/create            → CreateSessionScreen
/session/:id/lobby         → LobbyScreen
/session/:id/voting        → VotingScreen
/session/:id/waiting       → WaitingScreen
/session/:id/results       → ResultsScreen
/join/:code                → deep link → redirect LobbyScreen
```

### 6.4 Collections Appwrite

#### `sessions`
| Champ | Type | Obligatoire |
|---|---|---|
| `hostId` | string | ✓ |
| `status` | enum (`waiting` / `tasting` / `revealed`) | ✓ |
| `code` | string | ✓ |
| `isBlind` | boolean | ✓ |
| `guessFields` | string[] | ✓ |
| `createdAt` | datetime | ✓ |

#### `participants`
| Champ | Type | Obligatoire |
|---|---|---|
| `sessionId` | string | ✓ |
| `userId` | string | ✓ |
| `pseudo` | string | ✓ |
| `isHost` | boolean | ✓ |
| `joinedAt` | datetime | ✓ |

#### `beers`
| Champ | Type | Obligatoire |
|---|---|---|
| `sessionId` | string | ✓ |
| `name` | string | ✓ |
| `brewery` | string | ✓ |
| `style` | string? | — |
| `hops` | string? | — |
| `aromas` | string? | — |
| `status` | enum (`pending` / `voting` / `revealed`) | ✓ |
| `addedAt` | datetime | ✓ |

#### `votes`
| Champ | Type | Obligatoire |
|---|---|---|
| `sessionId` | string | ✓ |
| `beerId` | string | ✓ |
| `userId` | string | ✓ |
| `score` | integer (1–10) | — (null si skip) |
| `guesses` | string (JSON) | — |
| `hasSkipped` | boolean | ✓ |

### 6.5 Permissions Appwrite

| Collection | Create | Read | Update | Delete |
|---|---|---|---|---|
| `sessions` | Auth | Auth | hostId | hostId |
| `participants` | Auth | Auth | userId = self | hostId |
| `beers` | hostId | Auth | hostId | hostId |
| `votes` | userId = self | hostId + self | ❌ | hostId |

### 6.6 Realtime subscriptions

| Subscription | Consommateur | Utilité |
|---|---|---|
| `sessions/{id}` | Tous | Changement de statut |
| `participants` | Hôte | Arrivées / kicks en live |
| `votes` | Hôte | Compteur votes reçus |

---

## 7. Hors scope MVP

- Export résultats (PDF / image)
- Notifications push
- Nettoyage automatique sessions expirées (Appwrite Function)
- Suppression en cascade votes lors d'un kick via Appwrite Function (côté client pour le MVP)
- Universal Links / App Links (custom scheme `brewtaste://` suffisant)
- Support Web
- Base de données bières craft communautaire