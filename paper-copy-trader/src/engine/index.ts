export { PAPER_TRADING_LABEL, REAL_EXECUTION_ENABLED } from "./types";
export { DEFAULT_SETTINGS, DEFAULT_STARTING_BALANCE, STRATEGY_META } from "./defaults";
export { runCopyBacktest, compareStrategies } from "./backtest";
export { SampleMarketDataProvider, CsvMarketDataProvider } from "./data/sampleProvider";
export { SimulatedExecution, DisabledRealExecution } from "./execution";
export { sizeFollowerPosition, desiredCopyNotional, stopTakePrices } from "./positionSizing";
export { evaluateEntryRisk, currentDrawdownPct } from "./risk";
export { tradePnl, stopHitOnCandle } from "./pnl";
export { STRATEGIES } from "./strategies";
