---
name: review-my-pr
description: Use when asked to "review my PR" or self-review a PR. Critically reviews the PR diff, addresses existing comments, fixes CI failures, and produces an action plan — all before requesting human review.
argument-hint: "[PR number (optional, defaults to current branch PR)]"
disable-model-invocation: true
---

# Self-Review PR

Critically review your own PR before requesting human review. Combines code review, comment resolution, and CI fixing into one workflow.

## Phase 1: Gather Context

Fetch everything in parallel:

```bash
BRANCH=$(git branch --show-current)
PR_NUMBER=$(gh pr view $BRANCH --json number --jq '.number')

# PR metadata + diff
gh pr view $PR_NUMBER --json title,body,url,state,author,reviewDecision,baseRefName
gh pr diff $PR_NUMBER

# CI status
gh pr checks $PR_NUMBER

# Comments — general, inline, and review summaries
gh pr view $PR_NUMBER --json comments --jq '.comments[] | {author: .author.login, body: .body, url: .url}'
gh api repos/:owner/:repo/pulls/$PR_NUMBER/comments --jq '.[] | {author: .user.login, body: .body, path: .path, line: .line, diff_hunk: .diff_hunk, url: .html_url}'
gh pr view $PR_NUMBER --json reviews --jq '.reviews[] | {author: .author.login, state: .state, body: .body}'
```

If `$ARGUMENTS` contains a PR number, use that instead. If no PR exists, inform the user and stop.

## Phase 2: Critical Code Review

Dispatch a subagent (Task tool, subagent_type: "code-review") to scrutinize the diff. Include in the prompt:
- The full diff
- PR description
- Base branch context

The review must evaluate:
- **Bugs**: Logic errors, off-by-one, nil/null handling, race conditions
- **Security**: Input validation, auth checks, secrets exposure, injection risks
- **Design**: Does the approach make sense? Are there simpler alternatives?
- **Tests**: Are changes adequately tested? Missing edge cases?
- **Naming/clarity**: Would a teammate understand this code without explanation?

Be harsh. The point is to catch issues before teammates see them.

## Phase 3: Address Existing Feedback

### 3a: Comments

If there are existing review comments, categorize them:

| Type | How to identify | Action |
|------|----------------|--------|
| **Blocking** | `CHANGES_REQUESTED` reviews, "must fix" language | Fix with code changes |
| **Human feedback** | `user.type == "User"` | Must address — code change or reply |
| **Bot/agent** | `user.type == "Bot"` | Validate, fix if legitimate |
| **Questions** | Clarification requests | Prepare reply text |

For each actionable comment:
1. Locate the code using path/line from inline comments
2. Make the fix using the Edit tool
3. Note what was changed and which comment it addresses

### 3b: CI Failures

If any checks failed:

```bash
# Get failed run details
RUN_ID=$(gh run list --branch $BRANCH --status failure --limit 1 --json databaseId --jq '.[0].databaseId')
gh run view $RUN_ID --log-failed
```

Fix failures following repo conventions:
- **Frontend**: `pnpm lint:fix`, `pnpm type-check`, `pnpm format:fix`
- **Go**: `gofmt -w .`, `golangci-lint run`
- **Python**: `cd backend/oncall && ruff check --fix . && ruff format .`
- **Codegen**: `make flags/gen`

Verify fixes locally before committing.

## Phase 4: Commit Fixes

Group related changes into logical commits with conventional commit format:

```bash
git commit -m "fix(pr): address review feedback on <topic>

- <specific fix 1>
- <specific fix 2>

Addresses: <comment-url or CI run #id>"
```

IMPORTANT: Do NOT commit on `main`. Do NOT push without asking.

## Phase 5: Action Plan

Present a structured summary:

```markdown
## Self-Review: PR #<number> — <title>
**URL:** <url>
**Base:** <base branch>

### Code Review Findings
- **Critical:** <issues that must be fixed>
- **Warnings:** <issues worth addressing>
- **Suggestions:** <nice-to-have improvements>

### Comments Addressed
- [x] @reviewer — <summary> (fixed in <sha>)
- [x] @bot — <summary> (fixed in <sha>)
- [ ] @reviewer — <question> (reply needed: `gh pr comment ...`)

### CI Status
- [x] <passing job>
- [x] <fixed job> (was failing, fixed in <sha>)
- [ ] <still failing job> — <reason/next steps>

### Not Addressed
- <item> — <reason>

### Verdict
**Ready for human review?** Yes / No
**Remaining work:** <list if No>
```

## Guidelines

- Read ALL comments and CI output before making any changes
- Be critical — you're trying to catch problems, not confirm the code is fine
- If comments conflict, note the conflict and ask the user
- If a fix isn't clear, explain the issue rather than guessing
- If CI still fails after fixes, note it and suggest next steps
