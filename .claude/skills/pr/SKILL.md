---
name: pr
description: Use when opening, drafting or updating a GitHub pull request on a Carviz repo (GetCarviz/*) — writing its title or description, pushing a branch for review, or reviewing a branch before handing it to a reviewer.
---

# Opening Pull Requests on Carviz (GitHub)

Port of the Team IO GitLab conventions (`opening-merge-requests` +
`reviewing-branch-before-merge-request`, Confluence IO page 1853587477) to the
`GetCarviz/*` repos: GitHub via `gh`, integration branch `dev` (`development` on Dashboard), Jira project `CVZ`.

Nothing local or remote (commit, push, PR, labels, ready) runs before the single
confirmation of step 5.

## 1. Scope

```bash
REPO=$(basename "$(git rev-parse --show-toplevel)")        # GitHub: GetCarviz/$REPO
BASE=$(for b in dev development; do
  git ls-remote --exit-code --heads origin "$b" >/dev/null && echo "$b" && break
done)
BASE=${BASE:-$(gh api "repos/GetCarviz/$REPO" --jq .default_branch)}
BRANCH=$(git branch --show-current)   # or a branch named by your partner
TIP=HEAD                              # origin/$BRANCH when it is not checked out
TICKET=CVZ-540                        # see the Ticket rule below
git fetch origin
git log --oneline "origin/$BASE..$TIP"
git diff --stat "origin/$BASE...$TIP"
gh pr list -R "GetCarviz/$REPO" --head "$BRANCH" --json number,isDraft,url
# Related PRs: sibling branches on the same ticket, here and in the other Carviz repos
git branch -r | grep -i "$TICKET"
gh pr list -R "GetCarviz/$REPO" --search "$TICKET" --json number,headRefName,url
```

* `BASE` is `dev` when it exists, else `development` (Dashboard), else the default branch. Never `main` unless asked.
* Reviewing a branch that is not checked out: work on `origin/$BRANCH` with `git -C`,
  never check it out over your partner's working tree.
* On `$BASE`/`main` with changes → new branch from `origin/$BASE`:
  `<type>/<TICKET>-<kebab-summary>` (e.g. `fix/CVZ-540-reporting-providers-deadline`).
* Ticket: the one named in the conversation, else **`CVZ-540`** (takeover ticket).
* No `gh`? Stop and ask for `brew install gh` then `! gh auth login`; you may still
  write the title and description to a file for a manual paste.

## 2. Review the whole branch first

The PR is judged on **the whole branch against its intent**, never on the last commit.

1. **Spec**: fetch the Jira ticket (Atlassian MCP, cloud `log-ita.atlassian.net`). If it is
   generic (`CVZ-540` is an onboarding spike), derive the intent from the commits and state
   it as an assumption.
2. **Evidence**: run the repo's lint/typecheck/tests **only with tooling already installed**
   (`ruff`, `pytest`, `deno check`, `eslint` when `node_modules` exists). Never run an install
   to lint — Carviz rule: read scripts and dependencies before any install. Quote the real
   output; a check that did not run is reported as not run, with why.
3. **Axes**: spec compliance · correctness (error handling, timeouts, retries, auth) ·
   security (no secret, unknown URL or suspicious code in the diff — report at once) ·
   simplification (dead code, duplication) · commit hygiene (atomic, Conventional Commits).
4. **Flag**: migrations (Alembic, `supabase/migrations`), lockfile or dependency changes,
   `.github/workflows`, new secrets or env vars.

Report to your human partner in French, verdict first:

```markdown
## Revue de branche — <branch> → <BASE>
**Spec** : <CVZ-XXX — title | intention déduite : …>
**Vérifications** : <check> <✅|❌|non lancé (raison)> · …
### 🔴 Bloquants   ### 🟠 À corriger   ### 🔵 Nits      (`aucun` when empty)
### Verdict
<PRÊT POUR PR | CORRIGER D'ABORD — <n> bloquant(s)>
```

🔴 = broken build, failing check, secret in the diff, ticket requirement missing. A 🔴 blocks
the PR. Key Considerations takes, in this order: unfixed 🟠, checks not run, then 🔵 if room
is left. What does not fit its 5 bullets goes into a PR comment, never a sixth bullet.

**Deploy**: read the function's README / `deploy.sh` / `.github/workflows` to name the real
deploy action, instead of guessing it from the diff.

## 3. Title

English. `CVZ-XXX type(scope): concise-description`, no brackets.
`type` = Conventional Commit type; `scope` = the component (`reporting`, `scheduler`, `ci`…).
Example: `CVZ-540 fix(reporting): per-entity OpenFlex collection, providers override, time budget`.

Commits keep the Carviz form: `fix(reporting): … (CVZ-540)`, body only for the *why*.

## 4. Description

English, readable in under a minute. Intent and the decisions a reviewer would otherwise
reverse-engineer — the diff shows the rest.

```markdown
## Summary

<2–3 sentences, 350 characters max: what changes, why, the decisions that matter.>

## References

- [CVZ-XXX](https://log-ita.atlassian.net/browse/CVZ-XXX)

## Related PRs

- [<Repo>#<n>](https://github.com/GetCarviz/<Repo>/pull/<n>)

## Deploy

- [ ] <action: function/stack to redeploy, secret or env var (name + where), migration>

## Key Considerations

- <5 bullets max, one line each: risks, unfixed review findings, checks not run and why>

🤖 Generated with [Claude Code](https://claude.com/claude-code)
```

Only Summary is mandatory: a section with nothing to say is dropped, heading included.
A link (References, Related PRs) stands alone; text follows it only when it carries a fact
the reviewer needs — a required merge order, how the two PRs interact. Never a filler
like "merge in any order" or "same change".
Overflow goes to the Jira ticket. Secrets are cited by their `S-xx` id from
`docs/SECURITE.md`, never by value.

Write it to a file, then count and cut:

```bash
wc -m < "$BODY"
sed -n '/^## Summary/,/^## /p' "$BODY" | sed '1d;$d' | wc -m   # ≤ 350
```

Cut in this order: how you got there, what the diff shows, justifications nobody asked for,
any sentence that survives deletion. Never write "This PR introduces…", filler adjectives
(comprehensive, robust, seamless), "leverage/utilize", a closing recap, or a list of files.

## 5. Recap and single confirmation

Show: repo, branch → `BASE`, review verdict, flagged items, title, full description, commit
message, labels, assignee, proposed draft/ready. Then **one** `AskUserQuestion`:

* New PR: "Create as draft" / "Create, ready for review" / "No, change something".
* Existing PR: "Push (and update description)" / "Push and mark ready" / "No…".

Ambiguities are listed in the recap, never asked separately.

## 6. Execute

```bash
git add <files>            # never `git add .`: no .env, no stray files
git commit && git push -u origin <branch>
gh pr create -R "GetCarviz/$REPO" --base "$BASE" --head <branch> --draft \
  --title "…" --body-file "$BODY"            # or: gh pr edit <n> --body-file "$BODY"
gh pr edit <n> --add-assignee @me --add-label <label>   # existing labels only
gh pr ready <n>                              # if chosen
```

Labels: only ones listed by `gh label list -R GetCarviz/$REPO`, never created —
`fix` → `bug`, `feat` → `enhancement`, deps → `dependencies`, plus `claude` if it exists.

Once ready, give the Teams block as plain text (`<REPO>` uppercase, `FIX - ` prefix for a fix):

```text
<REPO> - <Short description>
<PR URL>
```

## Common mistakes

| Mistake | Fix |
| --- | --- |
| PR opened without reviewing the whole branch | Step 2 first; clear the 🔴 |
| Base `main` | `dev`, else `development`, when it exists |
| `[CVZ-540] fix: …` or no ticket in the title | `CVZ-540 fix(scope): …` |
| "Context / Changes / How to test" layout, or a file list | Summary + optional sections above |
| Summary over 350 characters | Count it, cut it |
| Bare `CVZ-540` under References | Markdown link |
| A check reported green that never ran | "not run (reason)" in Key Considerations |
| `npm install` / `uv sync` just to lint | Lint only with tooling already present |
| Label created on the fly | Existing labels only |
