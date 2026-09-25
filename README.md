# Player Gaming Habit & Behavior Analyzer

A working personal gaming journal built from the supplied plan with Node.js, Express 5, mysql2, MySQL 8, and one HTML/CSS/JavaScript frontend file. The dashboard is branded Playwise.

## Run on this Windows machine

From this project directory in PowerShell:

```powershell
.\start-local.cmd
```

Then open http://127.0.0.1:5000/dashboard/. The root `/` intentionally returns the API running message from the plan.

Use the `.cmd` launcher if PowerShell reports that running scripts is disabled. It runs Node.js directly and does not require changing PowerShell execution policy. It also recognizes when the dashboard is already running.

The launcher uses your existing local MySQL service at **127.0.0.1:3306** with user **root**. Credentials are saved in the ignored `.env` file. The app uses its own **playwise_analyzer** database because the pre-existing `gaming_analyzer` schema is incompatible. No separate MySQL process is started. Keep your MySQL80 service running.

The application is a local personal project with player selection, not authentication. The earlier isolated database in `.local/mysql` is retained but is no longer used.
## Use an existing MySQL database

Requires Node.js 22.9+ and MySQL 8.0.16+. Copy `.env.example` to `.env`, set DB_HOST, DB_PORT, DB_USER, DB_PASSWORD, and DB_NAME, then:

```powershell
npm.cmd ci
npm.cmd run db:setup
npm.cmd start
```

`db:setup` creates the named database, ten tables, six analytical views, and sample profiles if PLAYERS is empty. It does not delete existing records. Use a fresh database for this schema. Initial setup needs CREATE DATABASE/TABLE/VIEW privileges; a production runtime account should have only necessary data permissions. If port 5000 is occupied, set PORT in `.env`; use the printed dashboard address. The frontend calls same-origin APIs.

## Features

- Profile-specific overview; real MySQL persistence, no browser mock store.
- Start/end sessions for games and platforms in the selected player's library. A database unique constraint allows only one active session per player, including concurrent requests.
- Daily, Monday-based weekly, monthly and all-time analytics; longest session, game shares, active-day frequency, average playtime, and late-night starts.
- Purchase recording, totals, monthly trends, and the most spent-on game.
- Daily/weekly playtime and monthly spending limits, progress comparisons, and transactional history of changes.
- Achievement recording, duplicate prevention, points, and progress.
- Empty, loading, error, and success states; responsive layout and keyboard-accessible dialogs.
- Sample profiles Alex and Jordan, plus an empty New player profile. Sample purchases and sessions are fictional and seeded relative to setup time. Achievements are manual journal entries, not verified game integrations.

## Time and analytics definitions

Database timestamps are UTC. Each player has a fixed `timezone_offset_minutes` (sample default +330). The dashboard clips sessions at local midnight, so a session crossing days contributes to both days. Active sessions count through the current instant and refresh every 30 seconds. Fixed offsets do not automatically handle daylight saving time; edit the profile offset or extend this to IANA time zones when needed.

Daily average and active days use the last 30 calendar days, including zero-play days. Engagement uses daily average: Low <60 minutes; Moderate 60–119.99; High 120–239.99; Very high ≥240. These are transparent product heuristics, not medical classifications. Late-night patterns classify session **start time**: daytime 06:00–17:59, evening 18:00–21:59, late night 22:00–23:59, after midnight 00:00–05:59. They do not measure overnight overlap.

Week change compares week-to-date with the complete previous Monday–Sunday week; monthly spending change compares month-to-date with the complete previous month. With no previous activity, the percentage is null. Spending uses each player's single currency (INR for samples); no currency conversion is performed.

`VW_PLAYER_PLAYTIME_SUMMARY` and `VW_GAME_POPULARITY` are completed-session, whole-minute summaries; summary average is over the calendar span since first session. `VW_BEHAVIOR_TRENDS` demonstrates LAG across **recorded UTC start dates**, assigning the completed session to its start date; its previous value is the previous recorded date, not necessarily yesterday. The live dashboard uses the more precise day-splitting query in `backend/analytics.js`. Limit compliance view uses local boundaries. SQL examples demonstrate CTEs, window ranking, running totals, subqueries, HAVING, and a rolled-back DELETE.

## API

| Method | Path | Purpose |
| --- | --- | --- |
| GET | `/`, `/health` | API and MySQL health |
| GET | `/players`, `/games` | Lists |
| GET | `/library/:playerId` | Player games and platforms |
| GET | `/dashboard/:playerId` | Complete dashboard |
| GET | `/sessions/:playerId` | Session history |
| POST | `/sessions/start` | `{player_id, game_id, platform_id?}` |
| POST | `/sessions/end` | `{player_id}` |
| GET | `/analysis/{metric}/:playerId` | today, week, month, spending, most-played, longest-session |
| POST | `/purchases` | `{player_id, game_id, amount, purchase_type, note}`; type Game or In-game |
| PUT | `/limits/:playerId` | `{daily_playtime_limit, weekly_playtime_limit, monthly_spending_limit, change_reason}` |
| POST | `/achievements/earn` | `{player_id, achievement_id}` |

## Verification

```powershell
npm.cmd run build
npm.cmd test
```

Integration tests require a configured, initialized MySQL database. They create an isolated test player and remove that player's records afterward. Tests cover real SQL, session concurrency, cross-midnight accounting, validation, spending, limits/history, achievements, empty states, and all planned analytical endpoints/views. No bundling is required for the single-file frontend.

## Project layout

```text
backend/app.js          Express routes and validation
backend/store.js        Pool and transaction helpers
backend/analytics.js    Live SQL analytics and calendar boundaries
frontend/index.html    Complete dashboard with inline CSS and JS
database/schema.sql    Ten normalized tables and indexes
database/views.sql     Analytical views
database/examples.sql  Additional SQL demonstrations
database/setup.js      Idempotent schema/sample setup
tests/app.test.js      MySQL integration tests
start-local.ps1        Local Windows launcher
```

This is delivered as the requested Express/MySQL project. Sites' hosted Workers runtime cannot run the required raw MySQL TCP connection; publishing there would require a backend architecture change. No cloud deployment or game-platform account integration is included.
