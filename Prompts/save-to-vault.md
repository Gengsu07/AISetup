---
description: Save the current conversation as a well-formatted Obsidian note with YAML frontmatter, clean question-answer structure, preserved code blocks and Mermaid diagrams.
---
Save this conversation as a well-formatted Obsidian note.

FORMATTING RULES:
1. Strip out the long system/template prompt — keep only:
   - The user's core question (as a heading or blockquote)
   - The assistant's answer (cleaned, no boilerplate/preamble)
2. Preserve and correctly format any special content blocks:
   - Code snippets → fenced code blocks with language tag (```python, ```js, etc.)
   - Mermaid diagrams → fenced ```mermaid blocks (keep syntax valid, don't flatten to plain text)
   - Tables → proper Markdown tables
   - Lists → proper Markdown bullet/numbered lists
3. Add YAML frontmatter:

```---
   title: <short descriptive title from the question>
   date: <today's date, YYYY-MM-DD>
   source: <file(s)/note(s) used as context>
   tags: [copilot-conversation]
   ---
```
4. Structure the note as:
   # <Title>

   ## Question
   <core user question, cleaned>

   ## Answer
   <cleaned answer with code/mermaid/tables intact>

SAVE LOCATION:
- If the answer used one or more notes as context, save the .md file in the same directory as the primary/first-referenced source note.
- If there is no source note (general question, no context used), save it to the Copilot plugin's default conversation folder (Copilot for Obsidian's configured chat-history directory).
- Filename: <short-title-kebab-case>.md

Do not include the raw system prompt, retrieval instructions, or any internal reasoning — only the final clean question + answer pair.