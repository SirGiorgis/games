import { describe, expect, it } from "vitest";
import { desiredCopyNotional, sizeFollowerPosition, stopTakePrices } from "../positionSizing";
import { DEFAULT_SETTINGS } from "../defaults";
import { slippedPrice, feeOnNotional } from "../execution";
import { tradePnl, stopHitOnCandle } from "../pnl";
import { evaluateEntryRisk, currentDrawdownPct, markToMarket } from "../risk";
import { runCopyBacktest } from "../backtest";
import { DisabledRealExecution, SimulatedExecution } from "../execution";
import { REAL_EXECUTION_ENABLED } from "../types";
import type { Candle, SimulatorSettings } from "../types";
import { roundCash } from "../money";
import { sma } from "../indicators";
import type { LeaderStrategy } from "../strategies";

const testLongStrategy: LeaderStrategy = {
  id: "aggressive",
  warmup: 1,
  leaderStopPct: 50,
  leaderTakePct: 80,
  leaderQty: 1,
  evaluate(_candles, index, currentSide) {
    if (index < 1) return { entries: [], exit: false };
    if (currentSide) return { entries: [], exit: false };
    return {
      exit: false,
      entries: [{ side: "buy", reason: "Test leader buy" }],
    };
  },
};

const testAlwaysEnterStrategy: LeaderStrategy = {
  id: "aggressive",
  warmup: 0,
  leaderStopPct: 80,
  leaderTakePct: 80,
  leaderQty: 1,
  evaluate(_candles, index, currentSide) {
    if (index < 0) return { entries: [], exit: false };
    if (currentSide) return { entries: [], exit: false };
    return {
      exit: false,
      entries: [{ side: "buy", reason: "Test repeated buy" }],
    };
  },
};

function settings(partial: Partial<SimulatorSettings> = {}): SimulatorSettings {
  return { ...DEFAULT_SETTINGS, ...partial };
}

function candle(ts: number, price: number, high = price, low = price): Candle {
  return { timestamp: ts, open: price, high, low, close: price, volume: 1 };
}

function seriesFrom(prices: number[], symbol = "TEST-EUR", stepMs = 86_400_000) {
  const start = Date.UTC(2024, 0, 1);
  return [
    {
      info: { symbol, name: "Test", currency: "EUR" as const },
      candles: prices.map((p, i) => candle(start + i * stepMs, p)),
    },
  ];
}

describe("paper trading safety", () => {
  it("keeps real execution hardcoded off", () => {
    expect(REAL_EXECUTION_ENABLED).toBe(false);
  });

  it("disabled real broker refuses orders", () => {
    const exec = new DisabledRealExecution();
    expect(() =>
      exec.placeOrder({
        asset: "BTC-EUR",
        side: "buy",
        quantity: 1,
        price: 100,
        timestamp: 0,
      }),
    ).toThrow(/paper trading only/i);
  });

  it("simulated fills are marked paper", () => {
    const exec = new SimulatedExecution(10, 5);
    const fill = exec.placeOrder({
      asset: "BTC-EUR",
      side: "buy",
      quantity: 1,
      price: 100,
      timestamp: 1,
    });
    expect(fill.paper).toBe(true);
  });
});

describe("position sizing", () => {
  it("allocates copy percentage of equity, capped by max position size", () => {
    expect(desiredCopyNotional(500, { copyPercentage: 10, maxPositionSize: 150 })).toBe(50);
    expect(desiredCopyNotional(500, { copyPercentage: 50, maxPositionSize: 150 })).toBe(150);
  });

  it("sizes quantity from copy percent, fees and slippage", () => {
    const s = settings({ copyPercentage: 10, maxPositionSize: 200, feeBps: 10, slippageBps: 50 });
    const result = sizeFollowerPosition({
      equity: 500,
      cash: 500,
      price: 100,
      side: "buy",
      settings: s,
    });
    expect(result.accepted).toBe(true);
    expect(result.requestedNotional).toBe(50);
    const expectedFill = slippedPrice(100, "buy", 50);
    expect(result.fillPrice).toBe(expectedFill);
    expect(result.notional).toBeCloseTo(result.quantity * result.fillPrice, 2);
    expect(result.fee).toBe(feeOnNotional(result.notional, 10));
    expect(result.cashRequired).toBe(roundCash(result.notional + result.fee));
    expect(result.cashRequired).toBeLessThanOrEqual(500);
  });

  it("reduces size when cash is insufficient for the full copy amount", () => {
    const result = sizeFollowerPosition({
      equity: 500,
      cash: 20,
      price: 100,
      side: "buy",
      settings: settings({ copyPercentage: 10, maxPositionSize: 200, feeBps: 10, slippageBps: 0 }),
    });
    expect(result.accepted).toBe(true);
    expect(result.reduced).toBe(true);
    expect(result.cashRequired).toBeLessThanOrEqual(20.01);
    expect(result.notional).toBeLessThan(50);
  });

  it("rejects when cash cannot fund a meaningful position", () => {
    const result = sizeFollowerPosition({
      equity: 500,
      cash: 0.001,
      price: 100,
      side: "buy",
      settings: settings({ copyPercentage: 10 }),
    });
    expect(result.accepted).toBe(false);
    expect(result.rejectReason).toBe("insufficient_cash");
  });
});

describe("fees and slippage", () => {
  it("buys slip up and sells slip down", () => {
    expect(slippedPrice(100, "buy", 100)).toBeCloseTo(101, 8);
    expect(slippedPrice(100, "sell", 100)).toBeCloseTo(99, 8);
  });

  it("fees are a percent of notional", () => {
    expect(feeOnNotional(1000, 25)).toBe(2.5);
  });

  it("round-trip fees reduce net pnl versus gross", () => {
    const { grossPnl, netPnl } = tradePnl({
      side: "buy",
      quantity: 1,
      entryFill: 100,
      exitFill: 110,
      entryFee: 1,
      exitFee: 1.1,
    });
    expect(grossPnl).toBe(10);
    expect(netPnl).toBe(7.9);
  });
});

describe("profit and loss", () => {
  it("computes long and short pnl", () => {
    expect(
      tradePnl({
        side: "buy",
        quantity: 2,
        entryFill: 50,
        exitFill: 55,
        entryFee: 0,
        exitFee: 0,
      }).netPnl,
    ).toBe(10);
    expect(
      tradePnl({
        side: "sell",
        quantity: 2,
        entryFill: 50,
        exitFill: 45,
        entryFee: 0,
        exitFee: 0,
      }).netPnl,
    ).toBe(10);
  });
});

describe("stop loss and take profit", () => {
  it("places long and short stops from user percentages", () => {
    expect(stopTakePrices("buy", 100, 3, 6)).toEqual({ stopLoss: 97, takeProfit: 106 });
    expect(stopTakePrices("sell", 100, 3, 6)).toEqual({ stopLoss: 103, takeProfit: 94 });
  });

  it("detects long stop from the bar low without using future bars", () => {
    expect(
      stopHitOnCandle("buy", 97, 106, {
        timestamp: 1,
        open: 100,
        high: 101,
        low: 96.5,
        close: 99,
        volume: 1,
      }),
    ).toBe("stop_loss");
  });

  it("detects long take-profit from the bar high", () => {
    expect(
      stopHitOnCandle("buy", 97, 106, {
        timestamp: 1,
        open: 100,
        high: 107,
        low: 99,
        close: 105,
        volume: 1,
      }),
    ).toBe("take_profit");
  });

  it("assumes stop-loss if both would hit in the same bar", () => {
    expect(
      stopHitOnCandle("buy", 97, 106, {
        timestamp: 1,
        open: 100,
        high: 110,
        low: 90,
        close: 100,
        volume: 1,
      }),
    ).toBe("stop_loss");
  });

  it("detects short stops and targets", () => {
    expect(
      stopHitOnCandle("sell", 103, 94, {
        timestamp: 1,
        open: 100,
        high: 104,
        low: 99,
        close: 102,
        volume: 1,
      }),
    ).toBe("stop_loss");
    expect(
      stopHitOnCandle("sell", 103, 94, {
        timestamp: 1,
        open: 100,
        high: 101,
        low: 93,
        close: 95,
        volume: 1,
      }),
    ).toBe("take_profit");
  });
});

describe("risk controls", () => {
  const baseSnap = {
    cash: 400,
    equity: 500,
    peakEquity: 500,
    openCount: 0,
    realizedPnlToday: 0,
    stopCopying: false,
  };

  it("rejects when STOP COPYING is active", () => {
    const d = evaluateEntryRisk({ ...baseSnap, stopCopying: true }, settings());
    expect(d.allowed).toBe(false);
    expect(d.reason).toBe("stop_copying");
  });

  it("rejects when max simultaneous positions is reached", () => {
    const d = evaluateEntryRisk({ ...baseSnap, openCount: 3 }, settings({ maxSimultaneousPositions: 3 }));
    expect(d.allowed).toBe(false);
    expect(d.reason).toBe("max_simultaneous_positions");
  });

  it("rejects when the daily loss limit is reached", () => {
    const d = evaluateEntryRisk({ ...baseSnap, realizedPnlToday: -40 }, settings({ maxDailyLoss: 40 }));
    expect(d.allowed).toBe(false);
    expect(d.reason).toBe("max_daily_loss");
  });

  it("rejects when max drawdown is reached", () => {
    const d = evaluateEntryRisk(
      { ...baseSnap, equity: 70, peakEquity: 100 },
      settings({ maxTotalDrawdownPct: 25 }),
    );
    expect(currentDrawdownPct(70, 100)).toBe(30);
    expect(d.allowed).toBe(false);
    expect(d.reason).toBe("max_drawdown");
  });

  it("rejects when virtual cash is empty", () => {
    const d = evaluateEntryRisk({ ...baseSnap, cash: 0 }, settings());
    expect(d.allowed).toBe(false);
    expect(d.reason).toBe("insufficient_cash");
  });
});

describe("mark to market", () => {
  it("values a long from remaining cash plus market value", () => {
    const equity = markToMarket(400, [
      {
        id: "1",
        asset: "EQ",
        side: "buy",
        quantity: 1,
        entryPrice: 100,
        entryTime: 0,
        stopLoss: 90,
        takeProfit: 120,
        entryFee: 0,
        entrySlippage: 0,
        notional: 100,
        entryReason: "t",
        leaderTradeId: "L",
        reservedCash: 0,
      },
    ], { EQ: 110 });
    expect(equity).toBe(510);
  });
});

describe("copy engine integration", () => {
  it("does not open follower trades when STOP COPYING is on", () => {
    const prices = [100, 101, 102, 103, 104];
    const result = runCopyBacktest({
      settings: settings({ copyPercentage: 20, maxSimultaneousPositions: 5 }),
      strategyId: "aggressive",
      strategy: testLongStrategy,
      series: seriesFrom(prices),
      stopCopying: true,
    });
    expect(result.realOrders).toBe(false);
    expect(result.openPositions).toHaveLength(0);
    expect(result.closedTrades).toHaveLength(0);
    expect(result.leaderTrades.length).toBeGreaterThan(0);
    expect(result.rejectedTrades.some((r) => r.reason === "stop_copying")).toBe(true);
  });

  it("copies a leader long with position size, fees and slippage instead of scaling profit", () => {
    const prices = [100, 100, 100, 110, 120];
    const result = runCopyBacktest({
      settings: settings({
        startingBalance: 500,
        copyPercentage: 10,
        maxPositionSize: 80,
        feeBps: 10,
        slippageBps: 20,
        stopLossPct: 90,
        takeProfitPct: 200,
        maxSimultaneousPositions: 5,
        maxDailyLoss: 400,
        maxTotalDrawdownPct: 90,
      }),
      strategyId: "aggressive",
      strategy: testLongStrategy,
      series: seriesFrom(prices),
    });
    expect(result.paperTrading).toBe(true);
    const activity = result.closedTrades.length + result.openPositions.length;
    expect(activity).toBeGreaterThan(0);
    const pos = result.openPositions[0] ?? result.closedTrades[0];
    expect(pos).toBeTruthy();
    if ("notional" in pos) {
      expect(pos.notional).toBeLessThanOrEqual(80.05);
      expect(pos.entryFee).toBeGreaterThan(0);
      expect(pos.entrySlippage).toBeGreaterThan(0);
    }
    for (const trade of result.closedTrades) {
      expect(trade.positionSize).toBeLessThanOrEqual(80.05);
      expect(trade.fees).toBeGreaterThan(0);
      expect(trade.slippage).toBeGreaterThan(0);
    }
  });

  it("rejects additional entries after the simultaneous position cap", () => {
    const a = seriesFrom([100, 101, 102, 103, 104, 105], "AAA-EUR");
    const b = seriesFrom([50, 51, 52, 53, 54, 55], "BBB-EUR");
    const result = runCopyBacktest({
      settings: settings({
        maxSimultaneousPositions: 1,
        copyPercentage: 10,
        maxPositionSize: 100,
        stopLossPct: 50,
        takeProfitPct: 80,
        maxDailyLoss: 500,
        maxTotalDrawdownPct: 90,
      }),
      strategyId: "aggressive",
      strategy: testAlwaysEnterStrategy,
      series: [...a, ...b],
    });
    expect(result.rejectedTrades.some((r) => r.reason === "max_simultaneous_positions")).toBe(true);
  });

  it("rejects when cash cannot support the copy", () => {
    const prices = [100, 101, 102, 103];
    const result = runCopyBacktest({
      settings: settings({
        startingBalance: 0.01,
        copyPercentage: 100,
        maxPositionSize: 1000,
        feeBps: 10,
        slippageBps: 5,
        maxDailyLoss: 1000,
        maxTotalDrawdownPct: 99,
      }),
      strategyId: "aggressive",
      strategy: testLongStrategy,
      series: seriesFrom(prices),
    });
    expect(
      result.rejectedTrades.some((r) => r.reason === "insufficient_cash" || r.reason === "zero_size"),
    ).toBe(true);
  });

  it("signals only from history available at that bar (no look-ahead)", () => {
    const prices = [...Array.from({ length: 20 }, () => 100), 100, 100, 140];
    const closes = prices;
    const idx = 19;
    const known = sma(closes.slice(0, idx + 1), 8, idx);
    const withFuture = sma(closes, 8, closes.length - 1);
    expect(known).not.toBeNull();
    expect(withFuture).not.toEqual(known);

    const peeking: LeaderStrategy = {
      id: "aggressive",
      warmup: 0,
      leaderStopPct: 50,
      leaderTakePct: 50,
      leaderQty: 1,
      evaluate(candles, index, currentSide) {
        if (candles[index + 1]) {
          throw new Error("Look-ahead: strategy received a future bar");
        }
        if (currentSide || index < 1) return { entries: [], exit: false };
        return { exit: false, entries: [{ side: "buy", reason: "no lookahead" }] };
      },
    };

    const result = runCopyBacktest({
      settings: settings({ maxSimultaneousPositions: 4, stopLossPct: 80, takeProfitPct: 80 }),
      strategyId: "aggressive",
      strategy: peeking,
      series: seriesFrom(prices),
    });
    expect(result.leaderTrades.length).toBeGreaterThan(0);
    for (const trade of result.closedTrades) {
      expect(trade.exitTime).toBeGreaterThan(trade.dateTime);
    }
    for (const leader of result.leaderTrades) {
      if (leader.exitTime) expect(leader.exitTime).toBeGreaterThanOrEqual(leader.entryTime);
    }
  });

  it("applies daily loss and drawdown limits to later copy entries", () => {
    const crash: LeaderStrategy = {
      id: "aggressive",
      warmup: 0,
      leaderStopPct: 1,
      leaderTakePct: 80,
      leaderQty: 1,
      evaluate(_candles, index, currentSide) {
        if (index === 1 && !currentSide) {
          return { exit: false, entries: [{ side: "buy", reason: "first" }] };
        }
        if (index === 4 && !currentSide) {
          return { exit: false, entries: [{ side: "buy", reason: "second" }] };
        }
        return { entries: [], exit: false };
      },
    };
    const prices = [100, 100, 100, 70, 70, 70, 70];
    const result = runCopyBacktest({
      settings: settings({
        startingBalance: 500,
        copyPercentage: 40,
        maxPositionSize: 250,
        stopLossPct: 5,
        takeProfitPct: 50,
        maxDailyLoss: 5,
        maxTotalDrawdownPct: 3,
        feeBps: 0,
        slippageBps: 0,
        maxSimultaneousPositions: 3,
      }),
      strategyId: "aggressive",
      strategy: crash,
      series: seriesFrom(prices, "TEST-EUR", 60 * 60 * 1000),
    });
    expect(
      result.rejectedTrades.some(
        (r) => r.reason === "max_daily_loss" || r.reason === "max_drawdown",
      ),
    ).toBe(true);
  });

  it("runs the bundled sample series as paper-only", () => {
    const result = runCopyBacktest({
      settings: settings({
        startingBalance: 500,
        copyPercentage: 10,
        maxPositionSize: 150,
        maxDailyLoss: 80,
        maxTotalDrawdownPct: 40,
        maxSimultaneousPositions: 3,
      }),
      strategyId: "aggressive",
    });
    expect(result.realOrders).toBe(false);
    expect(result.paperTrading).toBe(true);
    expect(result.equityCurve.length).toBeGreaterThan(100);
    expect(result.leaderTrades.length).toBeGreaterThan(0);
    expect(result.metrics.startingBalance).toBe(500);
    expect(result.metrics.maxDrawdownPct).toBeGreaterThanOrEqual(0);
  });
});
