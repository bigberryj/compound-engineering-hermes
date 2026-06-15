# ce-execute stop conditions

This is the cheat sheet for when to stop and when to keep going.

## KEEP GOING (no user check)

- Step is complete, verification is green → ship, capture evidence, move on
- Step fails, fix is obvious and within plan's intent → apply, continue
- Step is slow (build, test, install) → wait for it, don't narrate
- Step requires reading more code → read it, don't ask permission
- Step requires running another tool → run it

## STOP AND ASK (one `clarify` call, then continue)

- Plan is genuinely ambiguous / contradicts itself
- Goal is unclear (e.g. user said "improve it" — improve what specifically?)
- A step is destructive with no rollback (see below)

## STOP AND HARD-BLOCK (no continuation)

- Force pushes without explicit user OK
- Mass deletes (rm -rf on a directory tree, dropping a database)
- Production deploys without explicit user OK
- Schema migrations on real user data without a backup taken
- Paid service signup / paid API call without explicit user OK
- Sending email to anyone other than the pre-approved recipient list
- Publishing a public repo / making a public commit that exposes secrets

## Failure loop (verify, debug, re-verify)

- Test fails → read error, fix, re-run
- Lint fails → fix the lint error, re-run
- Smoke test fails → debug, fix, re-run
- Verification still fails after 3 reasonable attempts → STOP and report what was tried
