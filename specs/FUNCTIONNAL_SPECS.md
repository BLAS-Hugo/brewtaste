# BrewTaste — Specs fonctionnelles

## Concept

Application mobile de dégustation de bières en groupe. Un hôte crée une session, les participants rejoignent via code ou QR code, notent chaque bière présentée par l'hôte, et les résultats sont révélés simultanément à la clôture de la session.

---

## Rôles

| Rôle | Description |
|---|---|
| **Hôte** | Crée et pilote la session, ajoute les bières, contrôle le déroulé |
| **Participant** | Rejoint une session existante, note et devine les bières |

Aucun compte requis. Authentification anonyme automatique (Appwrite).

---

## Création de session

L'hôte configure la session avant de la partager :

- **Mode aveugle** (`isBlind: bool`) — choix global pour toute la session
  - `true` : nom et brasserie masqués aux participants pendant le vote
  - `false` : nom et brasserie visibles, guess sur brasserie désactivé
- **Guess fields actifs** — l'hôte coche ce qu'il active parmi :
  - Style de bière
  - Brasserie *(disponible uniquement en mode aveugle)*
  - Houblons
  - Arômes

Un code court unique est généré automatiquement (`BREW-XXXX`, 4 chiffres, actif 24h).

---

## Rejoindre une session

Deux méthodes :

- **Code court** — le participant tape `BREW-XXXX` manuellement
- **QR code** — scan depuis l'app ou deep link `brewtaste://join/BREW-XXXX`

À l'arrivée, le participant choisit un **pseudo** affiché dans le lobby.

---

## Lobby

- L'hôte voit les participants arriver en temps réel
- L'hôte peut **kicker** un participant (il est redirigé vers l'accueil)
- L'hôte lance la session quand il le souhaite

---

## Déroulé de la session

La session avance **bière par bière**, pilotée par l'hôte.

### Côté hôte

Pour chaque bière :
1. Ajoute une bière (scan code-barre ou saisie manuelle)
   - Champs : nom, brasserie, style, houblons, arômes
   - Scan via code-barre → enrichissement auto Open Food Facts (best-effort)
2. Lance le vote
3. Voit le compteur de votes reçus en temps réel
4. Passe à la bière suivante quand il le souhaite (pas d'obligation d'attendre tous les votes)
5. Peut modifier les infos d'une bière **entre deux rounds**

L'hôte peut **clôturer la session** à tout moment pour révéler les résultats.

### Côté participant

Pour chaque bière :
- **Note** via slider (1–10)
- **Guess** sur les champs activés par l'hôte :
  - Mode aveugle : style, brasserie, houblons, arômes
  - Mode non-aveugle : style, houblons, arômes
- **Skip** possible ("je n'ai pas goûté cette bière")
- Vote **locké après validation** — non modifiable

Entre les bières, le participant voit un écran d'attente.

### États de session

```
waiting → tasting → revealed
```

| État | Hôte | Participants |
|---|---|---|
| `waiting` | Lobby, peut lancer | Lobby, attente |
| `tasting` | Gestion des rounds | Vote / attente entre rounds |
| `revealed` | Résultats | Résultats |

---

## Résultats

Révélés **simultanément** à tous les participants à la clôture.

### Écran principal
- Classement des bières par **note moyenne** décroissante
- En cas d'égalité : départagé par nombre de votes valides
- Indicateur `X/Y ont goûté` par bière

### Modal détail (par bière)
- Informations complètes de la bière révélées (nom, brasserie, style, houblons, arômes)
- Notes individuelles par participant
- Guesses de chaque participant vs réalité (✓ / ✗)
- Les skips affichés avec tirets (—)

---

## Règles métier

- Un vote est locké côté Appwrite après création (pas d'update possible)
- Les skips sont exclus du calcul de moyenne
- Une session et son code sont actifs pendant **24h maximum**
- Un code `BREW-XXXX` n'est réutilisable que si la session associée est expirée ou révélée
- Les votes des participants kickés ou déconnectés sont conservés

---

## Hors scope MVP

- Export des résultats (PDF / image)
- Notifications push
- Nettoyage automatique des sessions expirées (Appwrite Function)
- Base de données bières craft propre (Open Food Facts uniquement en best-effort)
- Universal Links / App Links (custom scheme suffisant)
- Mode multijoueur asynchrone