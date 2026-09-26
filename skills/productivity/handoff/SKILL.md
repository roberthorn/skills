---
name: handoff
description: Compact the current conversation into a handoff document for another agent to pick up.
argument-hint: "What will the next session be used for?"
disable-model-invocation: true
---

Write a handoff document summarising the current conversation so a fresh agent can continue the work.

Save it as a single Obsidian note at `00 - Agents/Handoffs/<project>/<YYYY-MM-DD HHmmss - Title>.md`, where `<project>` is the basename of the git toplevel (drop the `<project>/` segment outside a repo) and `<Title>` is a short, filesystem-safe description of the work. Call the Skill tool with "obsidian-cli" for how to write it. Report the note's path as a path-qualified wikilink.

Include a "suggested skills" section in the document, naming which skills the next agent should call the Skill tool for.

Do not duplicate content already captured in other artifacts (specs, plans, ADRs, issues, commits, diffs). Reference them by path or URL instead.

Redact any sensitive information, such as API keys, passwords, or personally identifiable information.

If the user passed arguments, treat them as a description of what the next session will focus on and tailor the doc accordingly.
