# Vasher ledger US date format

## Problem

The Vasher dashboard renders `updatedAt` with `Date.prototype.toLocaleString()` without a locale. The desktop deliberately sets `LC_TIME = "en_GB.UTF-8"` to retain a 24-hour clock, so Zen renders dashboard dates as `DD/MM/YYYY`.

## Decision

Add one shared dashboard formatter that explicitly uses `en-US` with two-digit month and day and a four-digit year. It also requests a 24-hour clock so the dashboard keeps its current time convention and local timezone.

The formatter will replace both current implicit date conversions:

- the current candidate's **Updated** value;
- every timestamp in **Recent runs**.

The displayed form is `MM/DD/YYYY, HH:MM:SS`, for example `08/10/2026, 22:48:48`.

## Scope

- Change only `modules/nixos/vasher-dashboard/src/main.tsx`.
- Do not change system `LC_TIME`, Zen configuration, JSON timestamps, polling, or server behavior.

## Verification

- Add a deterministic formatter test covering zero padding, US date order, four-digit year, and the 24-hour clock.
- Run the dashboard's TypeScript/Vite production build.
