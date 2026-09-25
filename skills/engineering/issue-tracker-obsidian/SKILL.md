---
name: issue-tracker-obsidian
description: Issue tracker backed by an Obsidian vault, where issues, specs, and wayfinder maps live as notes. Use when a skill says "publish to the issue tracker" or "fetch the relevant ticket", or when /wayfinder needs its tracker operations.
---

# Issue tracker: Obsidian

Issues and specs live as notes in an Obsidian vault, driven through the `obsidian` CLI (Obsidian must be running). Call the Skill tool with "obsidian-cli" for CLI syntax.

## Where things live

- **Vault**: the most recently focused one. Its absolute path is `obsidian vault info=path`.
- **Root**: `00 - Agents/Issues/<project>/`, where `<project>` is the basename of the repo's git toplevel (`git rev-parse --show-toplevel`). One folder per repo, so efforts from different repos never collide.
- **Feature / effort**: one folder per feature, `<root>/<feature-slug>/`.
- **Spec**: `<root>/<feature-slug>/Spec - <Title>.md`
- **Issue**: `<root>/<feature-slug>/Issues/NN - <Title>.md`, one file per ticket, numbered from `01`, never a single combined tickets file.

A note's **name** is its title: the file basename minus the `NN - ` prefix. Strip `* " \ / < > : | ? # ^ [ ]` from titles before using them as file names.

## Conventions

- **Links**: path-qualified wikilinks with the title as alias, `[[00 - Agents/Issues/<project>/<feature>/Issues/03 - Pick a queue|Pick a queue]]`. Bare names are ambiguous across efforts.
- **State lives in frontmatter properties**, not body lines, so Bases can query it. Triage state is the `status` property; `ready-for-agent` means an agent can pick it up.
- **Blocking**: `blocked_by` is a list of path-qualified wikilinks to the blocking tickets (Obsidian renders them as links and backlinks, so the graph shows the edges). Wire edges in a second pass after every ticket exists, by editing the frontmatter:

  ```yaml
  blocked_by:
    - "[[00 - Agents/Issues/<project>/<feature-slug>/Issues/01 - Pick a queue|Pick a queue]]"
  ```
- **Tags stand in for labels**: `wayfinder:map` becomes the tag `wayfinder/map` (tags can't contain `:`).
- **Comments** append to the bottom of the note under a `## Comments` heading, each entry prefixed with the date.
- **Writing**:
  - New notes: `obsidian create path="<path>" content="..." silent`. For long bodies, write the file directly at `<vault path>/<path>` with the write tool.
  - Single property changes: `obsidian property:set path="<path>" name=status value=claimed`.
  - Mid-body edits (a map section, a list property): re-read the note, then use the edit tool on `<vault path>/<path>`. Other sessions may be editing concurrently; exact-match edits fail loudly instead of clobbering.
  - Always target by `path=`, never `file=`: every effort has notes with similar names.

## When a skill says "publish to the issue tracker"

Create a new note under `<root>/<feature-slug>/` (the CLI creates missing folders). A spec or implementation ticket carries this frontmatter above its body:

```yaml
tags:
  - issue          # `spec` for a spec
status: ready-for-agent
spec: "[[<spec path without .md>|<Spec title>]]"   # tickets only, when a spec exists
blocked_by: []   # tickets only
```

## When a skill says "fetch the relevant ticket"

`obsidian read path="<path>"`. The user normally passes the path, the title, or the issue number; resolve a title or number with `obsidian files folder="<root>/<feature-slug>/Issues"`.

## Wayfinding operations

Used by `/wayfinder`. The **map** is a note; each **child** ticket is a note in the effort's `Issues/` folder; a per-effort **Frontier base** is the native, UI-visible view of what's takeable.

### Map

`<root>/<effort-slug>/Map - <Effort title>.md`:

```markdown
---
tags:
  - wayfinder/map
project: <project>
status: open
---
![[00 - Agents/Issues/<project>/<effort-slug>/Frontier.base#Frontier]]

<the map body from /wayfinder: Destination, Notes, Decisions so far, Not yet specified, Out of scope>
```

The embed renders the frontier live in Obsidian; it is a query, not a list of tickets, so the map still never lists open tickets. When charting, also create `<root>/<effort-slug>/Frontier.base` from [frontier.base](frontier.base), replacing `<ISSUES_FOLDER>` with `00 - Agents/Issues/<project>/<effort-slug>/Issues`. Bases can't resolve `this.file.folder` from the CLI, so the folder path must be literal.

### Child ticket

`<root>/<effort-slug>/Issues/NN - <Title>.md`, numbered from `01`:

```markdown
---
tags:
  - wayfinder/<type>
map: "[[<map path without .md>|<Effort title>]]"
status: open
assignee:
blocked_by: []
---
## Question

<the question>
```

- `<type>` is `research`, `prototype`, `grilling`, or `task`.
- **Research location**: a `research` ticket's findings go to `<root>/<effort-slug>/Research/<Title>.md`; pass that path to the "research" skill.
- `status` is one of `open`, `claimed`, `resolved`, `out-of-scope`. A ticket is **closed** when `resolved` or `out-of-scope`.

### Blocking

Per the `blocked_by` convention above. A ticket is **unblocked** when every ticket it lists is closed.

### Frontier query

```bash
obsidian base:query path="<root>/<effort-slug>/Frontier.base" view=Frontier format=paths
```

Returns open, unblocked, unclaimed tickets; the lowest `NN` wins. If it errors `Base file not found` right after creating the base, the index hasn't caught up: wait a second and retry. The `All` view shows every ticket with its open-blocker count.

### Claim

The session's first write. Re-read the ticket's status (`obsidian property:read path="<path>" name=status`); if it is no longer `open`, another session took it, so re-run the frontier query. Otherwise:

```bash
obsidian property:set path="<path>" name=status value=claimed
obsidian property:set path="<path>" name=assignee value="<git config user.name>"
```

### Resolve

1. Append the answer: `obsidian append path="<path>" content="## Answer\n\n<answer>"`. Link assets created while resolving (prototype notes, research files) from the answer.
2. `obsidian property:set path="<path>" name=status value=resolved`
3. Append a context pointer to the map's **Decisions so far** (edit tool, mid-body): `- [[<ticket path without .md>|<Title>]]: <one-line gist>`.

### Out of scope

`obsidian property:set path="<path>" name=status value=out-of-scope`, then add the line (gist, why, wikilink) to the map's **Out of scope** section.

### Map done

When no tickets remain and the way is clear, set the map's `status` to `resolved`.
