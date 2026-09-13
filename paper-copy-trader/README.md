# Paper Copy Trader

**PAPER TRADING — NO REAL ORDERS**

A local copy-trading simulator for testing whether a *hypothetical* follower account would have made or lost virtual money. It uses a simulated €500 starting balance, simulated fills, simulated fees/slippage, and bundled sample market data.

This application:

- Never places real trades
- Never talks to a broker or exchange for order execution
- Never stores API keys
- Uses virtual cash and simulated orders only

Hypothetical Conservative / Balanced / Aggressive leaders are **not** claimed to be profitable. They exist so you can compare simulated outcomes. This is not financial advice.

## Phone use

This is a responsive web app, not a native App Store / Play Store install.

- On a phone browser it uses a bottom navigation bar, large tap targets, and horizontally scrollable tables.
- Run it on your Windows PC, then open `http://YOUR-PC-LAN-IP:3000` on the phone (same Wi-Fi).
- You can also add it to the phone home screen from the browser (Progressive Web App manifest).
- Charts and wide trade logs are usable on a phone, but a desktop/laptop is more comfortable for the full table.

Limitation: the phone does not run the engine by itself unless you host the app. There is no iOS/Android native binary in this version.

## Stack

Next.js 15 + TypeScript + Tailwind CSS + Vitest.

The trading math lives in `src/engine` as plain TypeScript so it can later sit in front of a read-only market-data API. Real execution is a stub that always throws.

## Windows setup

### 1. Install prerequisites

1. Install [Node.js LTS](https://nodejs.org) (includes npm).
2. Open **Command Prompt** or **PowerShell**.

```bat
node -v
npm -v
```

### 2. Create / open the project

If you already have this repository:

```bat
cd path\to\games\paper-copy-trader
```

### 3. Install dependencies

```bat
npm install
```

### 4. Run the application

One command after install:

```bat
start.bat
```

Or:

```bat
npm run dev
```

Then open [http://localhost:3000](http://localhost:3000).

### 5. Run tests

```bat
npm test
```

### 6. Build the application

```bat
npm run build
npm start
```

`npm start` serves the static `out/` folder. There is still no live trading endpoint.

## How the simulator works

1. Sample OHLCV bars are generated locally (deterministic seed).
2. A leader strategy may emit a signal using **only bars up to the current close**.
3. The simulated fill is the **next bar’s open**, with slippage.
4. The follower sizes the copy from your copy %, max position, cash, and fees.
5. Risk rules can reject or reduce the copy.
6. Stop-loss / take-profit use that bar’s high/low. If both would hit in the same bar, stop-loss wins (pessimistic).

## Adding real market data later

Implement `MarketDataProvider` in `src/engine/types.ts`. CSV loading is already sketched in `src/engine/data/sampleProvider.ts`. Do not add order-routing keys. Keep `REAL_EXECUTION_ENABLED = false` until you deliberately build a separate, clearly labeled live adapter — this repo’s disabled adapter will still refuse live orders.
