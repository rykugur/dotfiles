# Task 1 Report

## Changed files

- `modules/nixos/vasher-dashboard/package.json` — added the required deterministic `npm test` script.
- `modules/nixos/vasher-dashboard/src/date-format.ts` — added `formatTimestamp(timestamp: string): string` using `Intl.DateTimeFormat` with US date order and a 24-hour clock.
- `modules/nixos/vasher-dashboard/test/date-format.test.ts` — added the focused formatter contract test.

## Verification

- Failing test command: `npm test` (from `modules/nixos/vasher-dashboard`)
  - Outcome: FAIL, as expected. Node reported `ERR_MODULE_NOT_FOUND` because `src/date-format.ts` did not yet exist; 0 passing, 1 failing.
- Passing test command: `npm test` (from `modules/nixos/vasher-dashboard`)
  - Outcome: PASS. Node test runner reported 1 test, 1 pass, 0 failures.

## Commit

`8919eb1f` — `feat: format Vasher ledger dates in US order`

## Concerns

None.

## Boundary fix

### Changed files

- `modules/nixos/vasher-dashboard/src/date-format.ts` — switched to `formatToParts()` and zero-padded only the year part to four digits.
- `modules/nixos/vasher-dashboard/test/date-format.test.ts` — added the `0001-01-01T00:00:00Z` UTC assertion.

### Verification

- Command: `npm test` (from `modules/nixos/vasher-dashboard`)
- Output: 1 test, 1 pass, 0 failures.

- Commit: `d4987774`
