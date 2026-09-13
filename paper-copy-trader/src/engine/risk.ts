import type { OpenPosition, RejectReason, SimulatorSettings } from "./types";

export interface RiskSnapshot {
  cash: number;
  equity: number;
  peakEquity: number;
  openCount: number;
  realizedPnlToday: number;
  stopCopying: boolean;
}

export interface RiskDecision {
  allowed: boolean;
  reason?: RejectReason;
  detail: string;
}

export function currentDrawdownPct(equity: number, peakEquity: number): number {
  if (peakEquity <= 0) return 0;
  return Math.max(0, ((peakEquity - equity) / peakEquity) * 100);
}

export function evaluateEntryRisk(
  snapshot: RiskSnapshot,
  settings: SimulatorSettings,
): RiskDecision {
  if (snapshot.stopCopying) {
    return {
      allowed: false,
      reason: "stop_copying",
      detail: "STOP COPYING is active. No new simulated trades will be opened.",
    };
  }

  if (snapshot.openCount >= settings.maxSimultaneousPositions) {
    return {
      allowed: false,
      reason: "max_simultaneous_positions",
      detail: `Already have ${snapshot.openCount} open paper positions (max ${settings.maxSimultaneousPositions}).`,
    };
  }

  if (snapshot.realizedPnlToday <= -Math.abs(settings.maxDailyLoss) + 1e-9) {
    return {
      allowed: false,
      reason: "max_daily_loss",
      detail: `Daily realized loss €${Math.abs(snapshot.realizedPnlToday).toFixed(2)} reached the €${settings.maxDailyLoss.toFixed(2)} limit.`,
    };
  }

  const dd = currentDrawdownPct(snapshot.equity, snapshot.peakEquity);
  if (dd >= settings.maxTotalDrawdownPct - 1e-9) {
    return {
      allowed: false,
      reason: "max_drawdown",
      detail: `Drawdown ${dd.toFixed(2)}% reached the ${settings.maxTotalDrawdownPct}% maximum.`,
    };
  }

  if (snapshot.cash <= 0.01) {
    return {
      allowed: false,
      reason: "insufficient_cash",
      detail: "No virtual cash available.",
    };
  }

  return { allowed: true, detail: "Risk checks passed." };
}

export function exposureOf(
  positions: OpenPosition[],
  marks: Record<string, number>,
): number {
  return positions.reduce((sum, pos) => {
    const px = marks[pos.asset] ?? pos.entryPrice;
    return sum + Math.abs(pos.quantity * px);
  }, 0);
}

export function markToMarket(
  cash: number,
  positions: OpenPosition[],
  marks: Record<string, number>,
): number {
  const openValue = positions.reduce((sum, pos) => {
    const mark = marks[pos.asset] ?? pos.entryPrice;
    if (pos.side === "buy") {
      return sum + pos.quantity * mark;
    }
    const unrealized = (pos.entryPrice - mark) * pos.quantity;
    return sum + pos.reservedCash + unrealized;
  }, 0);
  return cash + openValue;
}
