export const PAPER_TRADING_LABEL = "PAPER TRADING — NO REAL ORDERS";

export const REAL_EXECUTION_ENABLED = false as const;

export type Side = "buy" | "sell";

export type StrategyId = "conservative" | "balanced" | "aggressive";

export type RejectReason =
  | "stop_copying"
  | "max_position_size"
  | "max_daily_loss"
  | "max_drawdown"
  | "max_simultaneous_positions"
  | "insufficient_cash"
  | "real_execution_disabled"
  | "zero_size";

export interface Candle {
  timestamp: number;
  open: number;
  high: number;
  low: number;
  close: number;
  volume: number;
}

export interface AssetInfo {
  symbol: string;
  name: string;
  currency: "EUR";
}

export interface AssetSeries {
  info: AssetInfo;
  candles: Candle[];
}

export interface SimulatorSettings {
  startingBalance: number;
  copyPercentage: number;
  maxPositionSize: number;
  maxDailyLoss: number;
  maxTotalDrawdownPct: number;
  stopLossPct: number;
  takeProfitPct: number;
  maxSimultaneousPositions: number;
  feeBps: number;
  slippageBps: number;
}

export interface LeaderTrade {
  id: string;
  asset: string;
  side: Side;
  entryPrice: number;
  positionSize: number;
  stopLoss: number;
  takeProfit: number;
  entryTime: number;
  exitTime: number | null;
  exitPrice: number | null;
  profitLoss: number | null;
  status: "open" | "closed";
  entryReason: string;
  exitReason: string | null;
}

export interface OpenPosition {
  id: string;
  asset: string;
  side: Side;
  quantity: number;
  entryPrice: number;
  entryTime: number;
  stopLoss: number;
  takeProfit: number;
  entryFee: number;
  entrySlippage: number;
  notional: number;
  entryReason: string;
  leaderTradeId: string;
  reservedCash: number;
}

export interface ClosedTrade {
  id: string;
  dateTime: number;
  exitTime: number;
  asset: string;
  side: Side;
  entry: number;
  exit: number;
  positionSize: number;
  quantity: number;
  fees: number;
  slippage: number;
  grossPnl: number;
  netPnl: number;
  balanceAfter: number;
  entryReason: string;
  exitReason: string;
  leaderTradeId: string;
}

export interface RejectedTrade {
  timestamp: number;
  asset: string;
  side: Side;
  reason: RejectReason;
  detail: string;
  requestedNotional: number;
}

export interface EquityPoint {
  timestamp: number;
  balance: number;
  equity: number;
  drawdownPct: number;
  cash: number;
}

export interface PerformanceMetrics {
  startingBalance: number;
  endingBalance: number;
  endingEquity: number;
  availableCash: number;
  totalPnl: number;
  returnPct: number;
  annualizedReturnPct: number | null;
  tradeCount: number;
  winningTrades: number;
  losingTrades: number;
  winRatePct: number | null;
  averageWin: number | null;
  averageLoss: number | null;
  averageTrade: number | null;
  largestWin: number | null;
  largestLoss: number | null;
  maxDrawdownPct: number;
  maxDrawdownEur: number;
  profitFactor: number | null;
  sharpeRatio: number | null;
  currentExposure: number;
  openPositionCount: number;
}

export interface SimulationResult {
  paperTrading: true;
  realOrders: false;
  strategyId: StrategyId;
  settings: SimulatorSettings;
  metrics: PerformanceMetrics;
  equityCurve: EquityPoint[];
  closedTrades: ClosedTrade[];
  openPositions: OpenPosition[];
  rejectedTrades: RejectedTrade[];
  leaderTrades: LeaderTrade[];
  tradeResults: { id: string; netPnl: number; asset: string; exitTime: number }[];
}

export interface MarketDataProvider {
  readonly kind: "sample" | "csv" | "api";
  listAssets(): AssetInfo[];
  getHistory(symbol: string): Candle[];
  getSeries(): AssetSeries[];
}

export interface OrderRequest {
  asset: string;
  side: Side;
  quantity: number;
  price: number;
  timestamp: number;
}

export interface Fill {
  paper: true;
  asset: string;
  side: Side;
  quantity: number;
  requestedPrice: number;
  fillPrice: number;
  fee: number;
  slippage: number;
  timestamp: number;
}

export interface ExecutionPort {
  readonly kind: "simulated" | "disabled-real";
  placeOrder(order: OrderRequest): Fill;
}
