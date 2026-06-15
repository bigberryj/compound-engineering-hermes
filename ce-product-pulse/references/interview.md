# Pulse Interview

Loaded by `ce-product-pulse` at the start of Phase 1.1. Each section maps one-to-one to a `pulse_*` config key.

For each section: ask the opening question, evaluate the answer against the quality bar, push back when it falls into a named anti-pattern, capture the final answer, and write the captured key into the config file.

## Overall Rules

1. **SMART bar for every metric and event** — Specific, Measurable, Actionable, Relevant, Timely. Push back on anything vague, vanity, or unactionable.
2. **Push back once, maybe twice.** Same pattern as `ce-strategy`. If the first answer is weak, name the issue and ask a sharper question. If the second is still weak, capture and move on.
3. **Ask one question at a time.** Stacking questions dilutes answers.
4. **Quote the user back at them** when challenging.

## 1. Product Name (confirm or edit)

Confirm the seeded value from `STRATEGY.md` if present, otherwise ask: "What's the product or initiative name to use in pulse reports?"

Anti-pattern: a tagline as a name ("The Fastest Notes App" — that's marketing, not a name). Push back: "Is the name a product name, or a tagline? Pulse reports should show a stable product name so they're diffable over time."

## 2. Primary Engagement Event

"What's the event name that means 'a user showed up'? The thing fires when someone actually engaged with the product, not just loaded a page."

Examples (good): `session_started`, `user_logged_in`, `conversation_opened`, `editor_focused`. Bad: `page_view` (any bot triggers it), `app_installed` (captures pre-engagement).

Anti-patterns:

- **Vanity** ("page_view" — fires for any page hit) → "What's the signal that fires only when the user actually did something? page_view can fire for crawler traffic and you can't trust it."
- **Pre-engagement** ("signed_up" — captures intent, not engagement) → "That's intent, not engagement. What event fires after they're in and actually using the product?"

## 3. Value-Realization Event

"What's the event that means 'the user got value'? This is the moment they got what they came for."

Examples (good): `task_completed`, `document_exported`, `report_generated`, `purchase_completed`. Bad: `button_clicked` (too coarse — they clicked, but did they succeed?).

Anti-patterns:

- **Coarse** (`button_clicked`) → "Clicking is a step, not the value. What event fires when the user actually got the outcome they came for?"
- **Inverse** (`error_occurred`) → "That's the anti-value. Find the success event — the one that means it worked."

## 4. Completions or Conversions (0-3)

"What 0-3 events mark successful completions of high-value flows? Things like 'onboarded', 'first_purchase', 'first_export', 'invited_a_teammate'. Skip if you don't track these yet."

Max 3 — push back on a longer list.

## 5. Quality Scoring (opt-in, AI products only)

"Should pulse sample sessions and score them on a quality dimension? Only useful for AI products where output quality varies. If you don't know what dimension to score on, skip."

If yes: "What's the dimension to score 1-5?" Examples: `answer accuracy`, `response relevance`, `code correctness`, `tone appropriateness`. Push back on vague dimensions like "user satisfaction".

## 6. Data Sources

For each agreed metric and event, wire up a data source. Walk through them one at a time. For each: "Where does this data live? PostHog? Mixpanel? Sentry? A read-only DB? Custom?"

**Hermes note:** in upstream, PostHog/Sentry/Stripe are MCP servers. In Hermes, the user wires up whatever they have. Common setups:
- `posthog`, `mixpanel`, `amplitude` — analytics CLIs or pre-fetched JSON dumps
- `sentry`, `datadog`, `honeycomb` — error/trace CLIs or pre-fetched JSON
- `stripe` — Stripe CLI or pre-fetched JSON
- `custom` — a JSON file path the user references

If the user is unsure how to wire up a source, suggest `custom` with a JSON file path and tell them they can revisit it later. The skill does not fail when sources are missing — it renders `not configured at runtime` and the user can iterate.

**Reject read-write database access.** If the user offers to give the pulse a writeable DB connection: "Pulse only reads. If the data you need is in a writeable DB, give me a read-only role or pre-fetch a JSON dump. I will not write to your production database." Then offer:
- A read-only DB user (best for live data)
- A scheduled JSON dump to disk (best for hermes-on-laptop workflows)
- A CSV export run on a cadence (simplest, slightly stale)

## 7. System Performance (errors + latency)

Users rarely have strong opinions here. Present defaults and accept:
- Top 5 errors by count from the tracing source
- Latency p50 / p95 / p99 from the tracing source
- Default time window: same as the pulse window

Anti-pattern: don't ask users to invent custom latency thresholds. The pulse presents numbers; the reader interprets.

## 8. Default Lookback Window

"What's the default time window for a pulse when you don't pass one? Common defaults: 24h (most common), 7d (weekly review), 1h (during a launch)."

If the user is unsure, default to 24h.

## 9. Scheduling Recommendation

After the config is written, offer to set up a recurring run. The point of the pulse is to get it on a cadence so you don't have to remember to run it. Three options:

1. **Yes, schedule it (recommended)** — schedule the pulse with `cronjob` on the cadence the user picks (e.g., `0 9 * * *` for daily at 9am, `0 9 * * 1` for Monday morning). Hand off to Hermes's cron primitive.
2. **Not yet** — proceed to Phase 2 this once; user can decide later
3. **Don't ask me again** — set a config flag like `pulse_dismissed_scheduling: true` so the skill doesn't re-surface this

If the user says yes, propose a specific schedule, get confirmation, then hand off to `cronjob` with a self-contained prompt that loads `ce-product-pulse` and runs the pulse. Do not schedule inline.

## Config File Shape

Write flat `pulse_*` keys into `.compound-engineering/config.local.yaml`:

```yaml
pulse_product_name: "MyProduct"
pulse_lookback_default: 24h
pulse_primary_event: "session_started"
pulse_value_event: "task_completed"
pulse_completion_events: "onboarded,first_purchase"
pulse_quality_scoring: false
pulse_analytics_source: posthog
pulse_tracing_source: sentry
pulse_payments_source: stripe
pulse_db_enabled: false
pulse_metric_sources: "retention_d7=posthog,nps=delighted"
pulse_pending_metrics: "retention_d7,nps"
pulse_excluded_metrics: "north_star"
```

If the file already exists, **merge** the new keys in (don't overwrite existing non-pulse keys like `work_delegate_*`). Preserve user comments when possible.

If the file doesn't exist and `.compound-engineering/` doesn't exist, create the directory and write the file.
