# Pulse Report Template

Loaded by `ce-product-pulse` at Phase 2.3. Fill it in using the query results from Phase 2.1.

Keep the total to 30-40 lines. If a section is thin, leave it thin; do not pad.

```markdown
---
product: <pulse_product_name>
window: <lookback window, e.g. "24h">
generated: <ISO timestamp>
---

# Pulse — <product name>, last <window>

## Headlines

- <one line: primary engagement trend>
- <one line: value-realization trend>
- <one line: system health signal, positive or concerning>

## Usage

- **Primary engagement:** <N> <primary event> events (<delta> vs prior window)
- **Value realization:** <N> <value event> events (<delta> vs prior window)
- **Completions:**
  - <completion event 1>: <N> (<delta>)
  - <completion event 2>: <N> (<delta>)
- **Conversion:** <N value events> / <N primary events> = <ratio>
- **Quality sample** (if enabled): <distribution, e.g. "8x 5, 1x 4, 1x 2"> on <dimension>

## System performance

- **Latency:** p50 <Xms>, p95 <Xms>, p99 <Xms>
- **Top errors:**
  1. <error signature>: <count> — <one-line cause>
  2. <error signature>: <count> — <one-line cause>
  3. <error signature>: <count> — <one-line cause>
  4. <error signature>: <count> — <one-line cause>
  5. <error signature>: <count> — <one-line cause>

## Followups

1. <one thing worth investigating, with the signal that prompted it>
2. <another>
3. <another>

<!-- 1-5 followups. Pick what stands out, not everything. -->
```

## Section notes

**Headlines:** three lines max. Each one is a sentence fragment, not a sentence — let the reader's brain do the connecting. Mix: one usage signal, one quality/error signal, one operational signal.

**Usage:** present the numbers, not the verdict. The reader interprets. Always include the delta vs prior window when available.

**System performance:** the top 5 errors are by count, not by severity. The reader picks which to investigate.

**Followups:** pick 1-5, not all of them. "Worth investigating" means it has a signal (anomaly, regression, sudden change) — not "we should eventually look at this".

## PII rules

Never include in this report:

- User emails
- Account IDs (use anonymous identifiers only)
- Message content (conversation text, error messages that contain user data)
- IP addresses
- API keys or tokens (even partial)

If a top error includes user data in its message, redact it to the error type only.
