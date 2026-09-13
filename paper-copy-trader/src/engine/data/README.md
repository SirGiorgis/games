# Sample / future market data

v1 ships a `SampleMarketDataProvider` that generates deterministic OHLCV locally. No API keys.

CSV columns for a later file loader:

```csv
timestamp,open,high,low,close,volume
2024-01-01T00:00:00.000Z,38500,39000,38100,38720,123.4
```

To add a public market-data HTTP API later:

1. Implement `MarketDataProvider` (`kind: "api"`).
2. Fetch **read-only** candles.
3. Do not send orders and do not persist secrets in this app.
