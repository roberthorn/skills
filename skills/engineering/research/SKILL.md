---
name: research
description: Investigate a question against high-trust primary sources and capture the findings as a note in the Obsidian vault. Use when the user wants a topic researched, docs or API facts gathered, or reading legwork delegated to a background agent.
---

Spin up a **background agent** to do the research, so you keep working while it reads.

Its job:

1. Investigate the question against **primary sources** (official docs, source code, specs, first-party APIs), not a secondary write-up of them. Follow every claim back to the source that owns it.
2. Write the findings to a single Obsidian note, citing each claim's source with a link. Research changes no code in the repo; the note is its only output.
3. Save the note at the path the caller named. With no path given, use `00 - Agents/Research/<project>/<Title>.md`, where `<project>` is the basename of the git toplevel (drop the `<project>/` segment outside a repo). Call the Skill tool with "obsidian-cli" for how to write it.
4. Report the note's path back as a wikilink, `[[<path without .md>|<Title>]]`, so the caller can point at it.

The note:

```markdown
---
tags:
  - research
question: "<the question>"
created: <YYYY-MM-DD>
---
## Answer

<the short answer the question waits on>

## Findings

<the detail, each claim cited>

## Sources

- [<source title>](<url>)
```
