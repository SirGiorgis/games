import { crossedAbove, crossedBelow, rsi, sma } from "../indicators";
import type { Candle, Side } from "../types";

export interface LeaderIntent {
  entries: { side: Side; reason: string }[];
  exit: boolean;
  exitReason?: string;
}

export interface LeaderStrategy {
  id: "conservative" | "balanced" | "aggressive";
  warmup: number;
  leaderStopPct: number;
  leaderTakePct: number;
  leaderQty: number;
  evaluate(candles: Candle[], index: number, currentSide: Side | null): LeaderIntent;
}

function hold(): LeaderIntent {
  return { entries: [], exit: false };
}

export const conservativeStrategy: LeaderStrategy = {
  id: "conservative",
  warmup: 200,
  leaderStopPct: 4,
  leaderTakePct: 8,
  leaderQty: 1,
  evaluate(candles, index, currentSide) {
    if (index < this.warmup) return hold();
    const closes = candles.map((c) => c.close);
    const fastPrev = sma(closes, 50, index - 1);
    const fastNow = sma(closes, 50, index);
    const slowPrev = sma(closes, 200, index - 1);
    const slowNow = sma(closes, 200, index);
    if (
      fastPrev === null ||
      fastNow === null ||
      slowPrev === null ||
      slowNow === null
    ) {
      return hold();
    }
    if (crossedAbove(fastPrev, fastNow, slowPrev, slowNow)) {
      if (currentSide === "buy") return hold();
      if (currentSide === "sell") {
        return {
          exit: true,
          exitReason: "SMA 50 crossed above SMA 200",
          entries: [{ side: "buy", reason: "Conservative golden cross (SMA 50/200)" }],
        };
      }
      return {
        exit: false,
        entries: [{ side: "buy", reason: "Conservative golden cross (SMA 50/200)" }],
      };
    }
    if (crossedBelow(fastPrev, fastNow, slowPrev, slowNow)) {
      if (currentSide === "sell") return hold();
      if (currentSide === "buy") {
        return {
          exit: true,
          exitReason: "SMA 50 crossed below SMA 200",
          entries: [{ side: "sell", reason: "Conservative death cross (SMA 50/200)" }],
        };
      }
      return {
        exit: false,
        entries: [{ side: "sell", reason: "Conservative death cross (SMA 50/200)" }],
      };
    }
    return hold();
  },
};

export const balancedStrategy: LeaderStrategy = {
  id: "balanced",
  warmup: 50,
  leaderStopPct: 3,
  leaderTakePct: 6,
  leaderQty: 1,
  evaluate(candles, index, currentSide) {
    if (index < this.warmup) return hold();
    const closes = candles.map((c) => c.close);
    const fastPrev = sma(closes, 20, index - 1);
    const fastNow = sma(closes, 20, index);
    const slowPrev = sma(closes, 50, index - 1);
    const slowNow = sma(closes, 50, index);
    const rsiNow = rsi(closes, 14, index);
    if (
      fastPrev === null ||
      fastNow === null ||
      slowPrev === null ||
      slowNow === null ||
      rsiNow === null
    ) {
      return hold();
    }
    if (crossedAbove(fastPrev, fastNow, slowPrev, slowNow) && rsiNow < 65) {
      if (currentSide === "buy") return hold();
      const entry = {
        side: "buy" as const,
        reason: "Balanced SMA 20/50 cross up with RSI < 65",
      };
      if (currentSide === "sell") {
        return { exit: true, exitReason: "Opposite SMA cross", entries: [entry] };
      }
      return { exit: false, entries: [entry] };
    }
    if (crossedBelow(fastPrev, fastNow, slowPrev, slowNow) && rsiNow > 35) {
      if (currentSide === "sell") return hold();
      const entry = {
        side: "sell" as const,
        reason: "Balanced SMA 20/50 cross down with RSI > 35",
      };
      if (currentSide === "buy") {
        return { exit: true, exitReason: "Opposite SMA cross", entries: [entry] };
      }
      return { exit: false, entries: [entry] };
    }
    return hold();
  },
};

export const aggressiveStrategy: LeaderStrategy = {
  id: "aggressive",
  warmup: 21,
  leaderStopPct: 2.5,
  leaderTakePct: 5,
  leaderQty: 1,
  evaluate(candles, index, currentSide) {
    if (index < this.warmup) return hold();
    const closes = candles.map((c) => c.close);
    const fastPrev = sma(closes, 8, index - 1);
    const fastNow = sma(closes, 8, index);
    const slowPrev = sma(closes, 21, index - 1);
    const slowNow = sma(closes, 21, index);
    const rsiPrev = rsi(closes, 7, index - 1);
    const rsiNow = rsi(closes, 7, index);
    if (
      fastPrev === null ||
      fastNow === null ||
      slowPrev === null ||
      slowNow === null ||
      rsiPrev === null ||
      rsiNow === null
    ) {
      return hold();
    }
    const longSignal =
      (crossedAbove(fastPrev, fastNow, slowPrev, slowNow) && rsiNow < 70) ||
      (rsiPrev <= 30 && rsiNow > 30);
    const shortSignal =
      (crossedBelow(fastPrev, fastNow, slowPrev, slowNow) && rsiNow > 30) ||
      (rsiPrev >= 70 && rsiNow < 70);

    if (longSignal && !shortSignal) {
      if (currentSide === "buy") return hold();
      const entry = {
        side: "buy" as const,
        reason: "Aggressive fast MA/RSI long signal",
      };
      if (currentSide === "sell") {
        return { exit: true, exitReason: "Aggressive reverse to long", entries: [entry] };
      }
      return { exit: false, entries: [entry] };
    }
    if (shortSignal && !longSignal) {
      if (currentSide === "sell") return hold();
      const entry = {
        side: "sell" as const,
        reason: "Aggressive fast MA/RSI short signal",
      };
      if (currentSide === "buy") {
        return { exit: true, exitReason: "Aggressive reverse to short", entries: [entry] };
      }
      return { exit: false, entries: [entry] };
    }
    return hold();
  },
};

export const STRATEGIES = {
  conservative: conservativeStrategy,
  balanced: balancedStrategy,
  aggressive: aggressiveStrategy,
} as const;
