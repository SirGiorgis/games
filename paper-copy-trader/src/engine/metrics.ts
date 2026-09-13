import { roundCash } from "./money";
import { exposureOf } from "./risk";
import type {
  ClosedTrade,
  EquityPoint,
  OpenPosition,
  PerformanceMetrics,
  SimulatorSettings,
} from "./types";

export function computeMetrics(input: {
  settings: SimulatorSettings;
  cash: number;
  endingEquity: number;
  equityCurve: EquityPoint[];
  closedTrades: ClosedTrade[];
  openPositions: OpenPosition[];
  lastMarks: Record<string, number>;
  lastTimestamp: number;
}): PerformanceMetrics {
  const { settings, cash, endingEquity, equityCurve, closedTrades, openPositions, lastMarks } =
    input;
  const start = settings.startingBalance;
  const totalPnl = roundCash(endingEquity - start);
  const returnPct = start === 0 ? 0 : (totalPnl / start) * 100;

  const firstTs = equityCurve[0]?.timestamp;
  const lastTs = equityCurve[equityCurve.length - 1]?.timestamp;
  let annualizedReturnPct: number | null = null;
  if (firstTs && lastTs && lastTs > firstTs && endingEquity > 0 && start > 0) {
    const years = (lastTs - firstTs) / (365.25 * 24 * 3600 * 1000);
    if (years > 0.05) {
      annualizedReturnPct = (Math.pow(endingEquity / start, 1 / years) - 1) * 100;
    }
  }

  const wins = closedTrades.filter((t) => t.netPnl > 0);
  const losses = closedTrades.filter((t) => t.netPnl < 0);
  const flats = closedTrades.filter((t) => t.netPnl === 0);
  const winRatePct =
    closedTrades.length === 0
      ? null
      : ((wins.length + 0 * flats.length) / closedTrades.length) * 100;
  const averageWin =
    wins.length === 0 ? null : roundCash(wins.reduce((s, t) => s + t.netPnl, 0) / wins.length);
  const averageLoss =
    losses.length === 0 ? null : roundCash(losses.reduce((s, t) => s + t.netPnl, 0) / losses.length);
  const averageTrade =
    closedTrades.length === 0
      ? null
      : roundCash(closedTrades.reduce((s, t) => s + t.netPnl, 0) / closedTrades.length);
  const largestWin =
    closedTrades.length === 0 ? null : roundCash(Math.max(...closedTrades.map((t) => t.netPnl)));
  const largestLoss =
    closedTrades.length === 0 ? null : roundCash(Math.min(...closedTrades.map((t) => t.netPnl)));

  const grossWins = wins.reduce((s, t) => s + t.netPnl, 0);
  const grossLosses = Math.abs(losses.reduce((s, t) => s + t.netPnl, 0));
  const profitFactor =
    closedTrades.length === 0 ? null : grossLosses === 0 ? (grossWins > 0 ? Number.POSITIVE_INFINITY : null) : grossWins / grossLosses;

  let maxDrawdownPct = 0;
  let maxDrawdownEur = 0;
  let peak = start;
  for (const pt of equityCurve) {
    peak = Math.max(peak, pt.equity);
    const ddEur = peak - pt.equity;
    const ddPct = peak <= 0 ? 0 : (ddEur / peak) * 100;
    if (ddPct > maxDrawdownPct) maxDrawdownPct = ddPct;
    if (ddEur > maxDrawdownEur) maxDrawdownEur = ddEur;
  }

  const daily = new Map<string, number>();
  for (const pt of equityCurve) {
    daily.set(new Date(pt.timestamp).toISOString().slice(0, 10), pt.equity);
  }
  const eq = [...daily.values()];
  const rets: number[] = [];
  for (let i = 1; i < eq.length; i += 1) {
    if (eq[i - 1] !== 0) rets.push((eq[i] - eq[i - 1]) / eq[i - 1]);
  }
  let sharpeRatio: number | null = null;
  if (rets.length >= 30) {
    const mean = rets.reduce((s, r) => s + r, 0) / rets.length;
    const variance = rets.reduce((s, r) => s + (r - mean) ** 2, 0) / (rets.length - 1);
    const std = Math.sqrt(variance);
    if (std > 1e-12) sharpeRatio = (mean / std) * Math.sqrt(365);
  }

  return {
    startingBalance: start,
    endingBalance: roundCash(cash),
    endingEquity: roundCash(endingEquity),
    availableCash: roundCash(cash),
    totalPnl,
    returnPct,
    annualizedReturnPct,
    tradeCount: closedTrades.length,
    winningTrades: wins.length,
    losingTrades: losses.length,
    winRatePct,
    averageWin,
    averageLoss,
    averageTrade,
    largestWin,
    largestLoss,
    maxDrawdownPct,
    maxDrawdownEur: roundCash(maxDrawdownEur),
    profitFactor,
    sharpeRatio,
    currentExposure: roundCash(exposureOf(openPositions, lastMarks)),
    openPositionCount: openPositions.length,
  };
}
