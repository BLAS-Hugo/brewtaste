# Git Guidelines

## Branches

```
main          # production-ready, protected
develop       # integration branch — PRs merge here
feature/*     # new features
fix/*         # bug fixes
chore/*       # tooling, deps, config, refactors with no behavior change
```

Branch names use kebab-case: `feature/session-creation`, `fix/vote-lock-permissions`, `chore/add-riverpod`.

Always branch from `develop`. PRs target `develop`. `main` is only updated from `develop` via a release merge.

---

## Commits

Follow [Conventional Commits](https://www.conventionalcommits.org/).

```
<type>(<scope>): <short description>
```

**Types:**

| Type | When to use |
|---|---|
| `feat` | New user-facing feature |
| `fix` | Bug fix |
| `chore` | Dependencies, tooling, config, file moves |
| `refactor` | Code restructure with no behavior change |
| `test` | Adding or updating tests |
| `docs` | Documentation only |
| `style` | Formatting, lints (no logic change) |

**Scopes** (optional, use the feature name):
`session`, `voting`, `results`, `beer`, `router`, `appwrite`, `auth`, `sentry`

**Examples:**
```
feat(session): generate BREW-XXXX code and create session in Appwrite
fix(voting): filter blind beer fields before returning from repository
chore: add riverpod_annotation and build_runner dependencies
refactor(results): extract score calculation to use case
docs: add flutter guidelines
```

Rules:
- Subject line in lowercase, no trailing period, imperative mood ("add" not "added")
- Keep subject under 72 characters
- Body is optional — use it to explain *why*, not *what*

---

## Pull Requests

- One logical change per PR. Avoid mixing features with refactors.
- PRs should be reviewable in one sitting — split large features into sequential PRs if needed.
- PR title follows the same Conventional Commits format as commit messages.
- Include a short description of what changed and why. For UI changes, attach a screenshot or recording.
- Squash-merge into `develop` to keep history linear.

---

## What Not to Commit

Already covered by `.gitignore`, but never commit:
- `.env` — Appwrite endpoint/project ID, Sentry DSN
- `google-services.json`, `GoogleService-Info.plist`
- Any file under `android/app/` or `ios/` that contains API keys or signing configs

---

## Release Flow

```
develop → (manual merge) → main
```

Tag releases on `main` using semantic versioning: `v1.0.0`, `v1.1.0`, `v1.0.1`. Tag message summarises what's in the release.
