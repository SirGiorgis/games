import type { Candle } from "./types";

export function sma(values: number[], period: number, index: number): number | null {
  if (index + 1 < period) return null;
  let sum = 0;
  for (let i = index - period + 1; i <= index; i += 1) sum += values[i];
  return sum / period;
}

export function rsi(values: number[], period: number, index: number): number | null {
  if (index < period) return null;
  let gain = 0;
  let loss = 0;
  for (let i = 1; i <= period; i += 1) {
    const change = values[i] - values[i - 1];
    if (change >= 0) gain += change;
    else loss -= change;
  }
  let avgGain = gain / period;
  let avgLoss = loss / period;
  for (let i = period + 1; i <= index; i += 1) {
    const change = values[i] - values[i - 1];
    const g = Math.max(change, 0);
    const l = Math.max(-change, 0);
    avgGain = (avgGain * (period - 1) + g) / period;
    avgLoss = (avgLoss * (period - 1) + l) / period;
  }
  if (avgLoss === 0) return 100;
  const rs = avgGain / avgLoss;
  return 100 - 100 / (1 + rs);
}

export function closesThrough(candles: Candle[], index: number): number[] {
  return candles.slice(0, index + 1).map((c) => c.close);
}

export function crossedAbove(
  fastPrev: number,
  fastNow: number,
  slowPrev: number,
  slowNow: number,
): boolean {
  return fastPrev <= slowPrev && fastNow > slowNow;
}

export function crossedBelow(
  fastPrev: number,
  fastNow: number,
  slowPrev: number,
  slowNow: number,
): boolean {
  return fastPrev >= slowPrev && fastNow < slowNow;
}
