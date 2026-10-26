---
name: pr
description: Crée ou met à jour une Pull Request GitHub sur un repo Carviz (GetCarviz/*) : branche, lint, commit, push, titre, description au format Marketing (ticket Jira CVZ, description, PR liées, comment tester), labels, assignee, draft/ready. Déduit tout et ne pose qu'une seule question de confirmation, à la fin. À utiliser quand l'utilisateur veut committer et/ou ouvrir une PR dans un repo Carviz.
---

# Skill : Créer ou mettre à jour une Pull Request (Carviz)

Adaptée de la skill `/pr` d'OF-Marketing (`OF-Marketing/api/.claude/skills/pr/SKILL.md`). Différences : multi-repo (27 repos `GetCarviz/*`), pas de template dans les repos (structure définie ici), ticket par défaut `CVZ-540`, opérations GitHub via `gh` (pas de MCP GitHub), branche cible = branche d'intégration du repo.

Aucune action locale ou distante (commit, push, création de PR, labels, assignee, passage en ready) n'est exécutée sans la confirmation unique de l'Étape 5.

## Étape 1 — Analyse initiale (toujours)

1. Repo : celui du dossier courant (`git rev-parse --show-toplevel`) ou celui nommé par l'utilisateur, sous `~/dev/Carviz/<Repo>`. Repo GitHub : `GetCarviz/<Repo>`. Ignorer les repos du dossier `[DELETE]/`.
2. Branche d'intégration (base des PR) : `dev` si elle existe sur `origin`, sinon `development`, sinon la branche par défaut (`gh api repos/GetCarviz/<Repo> --jq .default_branch`). Ne jamais viser `main`/`master` directement sauf demande explicite.
3. Branche courante, `git status`, `git diff` (et `git diff origin/<base>...HEAD` si des commits existent déjà) pour comprendre ce qui a été fait.
4. PR existante pour la branche : `gh pr list -R GetCarviz/<Repo> --head <branche> --json number,isDraft,url`.
5. Lint : lancer le linter du repo **seulement s'il est déjà disponible localement** (ex. Engine : `ruff` ; fronts Nuxt : `eslint` si `node_modules` présent). Ne jamais lancer d'install (`npm install`, `uv sync`, `pip install`) pour linter : règle du `CLAUDE.md` Carviz (relire scripts et dépendances avant toute install). Corrections auto possibles → les appliquer et le noter ; problèmes persistants ou lint non lancé → le signaler dans le récapitulatif.
6. Signaler dans le récapitulatif : nouvelle migration (Models : Alembic ; Supabase : `supabase/migrations`), changement de `pyproject.toml`/`uv.lock`/`package.json`/lockfile, de workflow `.github/`, de secret ou de variable d'env.
7. Contrôle sécu du diff (règle §2 du `CLAUDE.md` Carviz) : aucun secret, URL inconnue ou code suspect ne doit partir dans la PR. Trouvaille → notifier immédiatement, sans attendre l'Étape 5.

## Étape 2 — Nouvelle branche ou pas (déduit, jamais demandé)

- Sur la branche d'intégration ou sur `main`/`master` → nouvelle branche obligatoire, créée depuis `origin/<base>` à jour (Étape 3).
- Sur une autre branche → rester dessus par défaut (Étape 4), sauf si la conversation indique clairement d'empiler une branche enfant (Étape 3, base = branche courante, PR parente ajoutée en « PR liée »).
- Plusieurs PR demandées d'un coup (ex. « fais en 2 PR ») → une branche par PR, chacune depuis `origin/<base>`, un seul récapitulatif à l'Étape 5 qui les présente toutes.

## Étape 3 — Parcours « nouvelle branche »

### 3.1 — Ticket Jira

Ticket mentionné dans la conversation, sinon **`CVZ-540`** par défaut (ticket de reprise). Lien : `https://log-ita.atlassian.net/browse/<TICKET>`.

### 3.2 — Titre de la PR (anglais)

Format Marketing : `Feature/Fix/Chore : Context - Short description`, toujours en anglais (ex. `Chore : Dependencies - Bump boto3, requests, pillow, python-dotenv`).

### 3.3 — Branche

`<type>/<TICKET>-<résumé-kebab-anglais>` (ex. `chore/CVZ-540-bump-python-deps`), convention déjà utilisée sur les repos Carviz.

### 3.4 — Commit

Conventional Commits en anglais, ticket en fin de sujet : `chore(deps): bump boto3, requests, pillow, python-dotenv (CVZ-540)`. Corps si le « pourquoi » n'est pas évident. Terminer par la ligne `Co-Authored-By` demandée par le harness.

### 3.5 — Description de la PR

Pas de template dans les repos Carviz : utiliser cette structure (reprise du template Marketing), contenu en anglais comme les tickets CVZ :

```markdown
# Ticket(s) Jira

- https://log-ita.atlassian.net/browse/CVZ-xxx

# Description

<Domaine fonctionnel/technique concerné et ce qui a été fait. Points d'attention pour le reviewer (migration, lockfile, breaking change, déploiement).>

# PR GitHub liée(s)

- <https://github.com/GetCarviz/<Repo>/pull/<n>> ou _None_

# Comment tester ?

- <Instructions concrètes : endpoint + payload (Engine), page + action (App/Dashboard), commande (tests, nox)…>

🤖 Generated with [Claude Code](https://claude.com/claude-code)
```

- PR liées : PR parente (branche enfant), PR sœurs créées dans le même `/pr`, PR remplacées (ex. PR Dependabot), ou mention explicite.
- Pas de valeur de secret dans la description : citer l'ID `S-xx` de `docs/SECURITE.md`.

### 3.6 — Assignee et labels

- Assignee : `gh api user --jq .login`.
- Labels : **uniquement des labels existants** (`gh label list -R GetCarviz/<Repo>`), ne jamais en créer. Correspondance : `Fix` → `bug`, `Feature` → `enhancement`, dépendances → `dependencies` (+ `python`/`javascript` si présents). `Chore` sans label correspondant → aucun label.

## Étape 4 — Parcours « pas de nouvelle branche »

- Message de commit comme en 3.4 s'il y a des changements non commités.
- PR existante → commit + push suffisent.
- Pas de PR → créer comme en 3.1, 3.2, 3.5, 3.6 ; type déduit du préfixe de la branche (`feat`/`feature`, `fix`, `chore`…). Préfixe non reconnaissable → le signaler avec le doute dans le récapitulatif.

## Étape 5 — Récapitulatif et confirmation unique

Afficher, pour chaque PR : repo, branche source → base, statut du lint, points signalés (migration, lockfile, workflow, sécu), titre, description complète, message de commit, ticket, PR liées, labels, assignee, statut draft/ready proposé. Si des PR sont à fermer (ex. Dependabot remplacées), les lister avec le commentaire prévu.

Puis **une seule question** (`AskUserQuestion`) :

- Nouvelle(s) PR : « Oui, crée en draft » / « Oui, crée et ouvre à la review » / « Non, j'ai quelque chose à modifier ».
- PR existante en draft : « Oui, pousse (reste en draft) » / « Oui, pousse et passe en ready » / « Non… ».
- PR existante ready : « Oui, pousse » / « Non… ».

« Non… » → demander quoi changer, ajuster, réafficher le récapitulatif, reposer la question.

## Étape 6 — Exécution

En local :
1. `git fetch origin` puis `git checkout -b <branche> origin/<base>` (nouvelle branche).
2. `git add <fichiers concernés>` (pas de `git add .` aveugle : ne pas embarquer de `.env` ou de fichiers parasites).
3. `git commit`, puis `git push -u origin <branche>` (premier push) ou `git push`.

Via `gh` :
1. `gh pr create -R GetCarviz/<Repo> --base <base> --head <branche> --draft --title … --body-file …`.
2. `gh pr edit <n> --add-assignee @me [--add-label …]`.
3. Si choisi : `gh pr ready <n>`.
4. PR à fermer : `gh pr close <n> --comment "Superseded by #<m> …"` (une PR Dependabot fermée peut garder sa branche ; ne pas supprimer de branche sans demande).

## Étape 7 — Résultat et suivi

- Lien(s) des PR, résumé (branche, base, labels, assignee, draft/ready).
- Si passée en ready : bloc Teams en texte brut :

```text
<REPO> - <Short description>
<lien-de-la-PR>
```

`<REPO>` en majuscules (`ENGINE`, `APP`, `DASHBOARD`…) ; type `Fix` → préfixer `FIX - `. Restée en draft → pas de bloc, le générer au passage en ready.
- Mettre à jour `~/dev/TEMPS.md` (ligne ticket × `PR`, repo `Carviz/<Repo>`) et la doc `~/dev/Carviz/docs/` concernée (fiche repo, TODO) si la PR change quelque chose de documenté.

## Notes

- Titre et description de PR en anglais ; doc locale `docs/` en français.
- Rien n'est poussé ni créé sur GitHub sans la confirmation de l'Étape 5 : c'est la seule question de `/pr`.
- Élément ambigu → le signaler dans le récapitulatif avec le doute, pas de question séparée.
