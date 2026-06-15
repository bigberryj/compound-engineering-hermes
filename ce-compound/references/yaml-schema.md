# YAML Frontmatter Rules for Solution Docs

Loaded by `ce-compound` and `ce-compound-refresh` at write time. Two layers of rules apply:

1. **Parser-safety** (silent-corruption prevention) — enforced by the bundled `scripts/validate-frontmatter.py` script and by the manual checklist in the `ce-compound` Phase 2 step 8.
2. **Schema compliance** (required fields, enum values) — enforced manually against `schema.yaml`.

This file covers both, with emphasis on the quoting rules that strict YAML 1.2 parsers (`yq`, `js-yaml` strict, PyYAML strict) will reject.

## Delimiters

Frontmatter is fenced with two lines whose stripped content is exactly `---`. Trailing whitespace is fine; `----` or `---extra` is not a valid delimiter. The opening line is line 1 of the file.

## YAML Safety Rules (array-of-strings fields)

Strict YAML 1.2 parsers reject array items that start with a reserved indicator character as unquoted scalars. When writing items for any array-of-strings field (`symptoms`, `applies_when`, `tags`, `related_components`, or any future array field), wrap the value in double quotes if it starts with any of:

`` ` ``, `[`, `*`, `&`, `!`, `|`, `>`, `%`, `@`, `?`

Also quote if the value contains the substring `": "` — that punctuation confuses flow-style parsers.

**Example — before (breaks strict YAML):**

```yaml
symptoms:
  - `sudo dscacheutil -flushcache` does not restore in-container mDNS
```

**Example — after (parses cleanly):**

```yaml
symptoms:
  - "`sudo dscacheutil -flushcache` does not restore in-container mDNS"
```

This rule applies to all array-of-strings frontmatter fields.

## Scalar field quoting (`title`, `description`, `module`, etc.)

For top-level scalar string fields (not arrays), quote the whole value with double quotes if it contains:

- a space followed by `#` (silent comment truncation: `value # comment` becomes just `value`)
- a colon followed by a space (silent mapping confusion: `key: value` may be read as nested mapping)
- a leading backtick, asterisk, ampersand, exclamation, pipe, or greater-than

Nested values, array items, and already-quoted values follow separate rules (the array rule above).

## Reserved frontmatter fields

`title`, `date`, `category`, `module`, `problem_type`, `component`, `severity`, `tags`, `symptoms`, `root_cause`, `resolution_type`, `applies_when`, `related_components`, `rails_version`, `last_updated`, `status`, `stale_reason`, `stale_date`, `supersedes`.

Do not invent additional fields without updating `schema.yaml`.

## Date format

`date`, `last_updated`, and `stale_date` must match `YYYY-MM-DD` (ISO 8601 date only, no time).
