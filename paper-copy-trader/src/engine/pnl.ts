import type { Candle, Side } from "./types";

export type StopHit = "stop_loss" | "take_profit" | null;

export function stopHitOnCandle(
  side: Side,
  stopLoss: number,
  takeProfit: number,
  candle: Candle,
): StopHit {
  if (side === "buy") {
    const slHit = candle.low <= stopLoss;
    const tpHit = candle.high >= takeProfit;
    if (slHit && tpHit) return "stop_loss";
    if (slHit) return "stop_loss";
    if (tpHit) return "take_profit";
    return null;
  }
  const slHit = candle.high >= stopLoss;
  const tpHit = candle.low <= takeProfit;
  if (slHit && tpHit) return "stop_loss";
  if (slHit) return "stop_loss";
  if (tpHit) return "take_profit";
  return null;
}

export function exitPriceForHit(
  hit: Exclude<StopHit, null>,
  stopLoss: number,
  takeProfit: number,
): number {
  return hit === "stop_loss" ? stopLoss : takeProfit;
}

export function tradePnl(params: {
  side: Side;
  quantity: number;
  entryFill: number;
  exitFill: number;
  entryFee: number;
  exitFee: number;
}): { grossPnl: number; netPnl: number } {
  const { side, quantity, entryFill, exitFill, entryFee, exitFee } = params;
  const gross =
    side === "buy"
      ? (exitFill - entryFill) * quantity
      : (entryFill - exitFill) * quantity;
  const net = gross - entryFee - exitFee;
  return {
    grossPnl: Math.round(gross * 100) / 100,
    netPnl: Math.round(net * 100) / 100,
  };
}

export function dayKey(timestamp: number): string {
  return new Date(timestamp).toISOString().slice(0, 10);
}
