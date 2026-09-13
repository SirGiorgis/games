import { SampleMarketDataProvider } from "./data/sampleProvider";
import { SimulatedExecution, closingAction, feeOnNotional, slippedPrice } from "./execution";
import { roundCash } from "./money";
import { dayKey, exitPriceForHit, stopHitOnCandle, tradePnl } from "./pnl";
import { sizeFollowerPosition, stopTakePrices } from "./positionSizing";
import { currentDrawdownPct, evaluateEntryRisk, exposureOf, markToMarket } from "./risk";
import { STRATEGIES, type LeaderStrategy } from "./strategies";
import type {
  AssetSeries,
  ClosedTrade,
  EquityPoint,
  LeaderTrade,
  OpenPosition,
  PerformanceMetrics,
  RejectedTrade,
  Side,
  SimulationResult,
  SimulatorSettings,
  StrategyId,
} from "./types";
import { REAL_EXECUTION_ENABLED } from "./types";
import { computeMetrics } from "./metrics";

export interface RunOptions {
  settings: SimulatorSettings;
  strategyId: StrategyId;
  series?: AssetSeries[];
  stopCopying?: boolean;
  strategy?: LeaderStrategy;
}

interface LeaderPos {
  id: string;
  asset: string;
  side: Side;
  qty: number;
  entry: number;
  entryTime: number;
  stopLoss: number;
  takeProfit: number;
  reason: string;
}

interface PendingLeader {
  asset: string;
  side: Side;
  reason: string;
  stopPct: number;
  takePct: number;
  qty: number;
  signalTime: number;
}

interface PendingExit {
  asset: string;
  reason: string;
  signalTime: number;
}

function cloneSettings(settings: SimulatorSettings): SimulatorSettings {
  return { ...settings };
}

export function runCopyBacktest(options: RunOptions): SimulationResult {
  if (REAL_EXECUTION_ENABLED) {
    throw new Error("Refusing to run: real execution is not allowed.");
  }

  const settings = cloneSettings(options.settings);
  const strategy = options.strategy ?? STRATEGIES[options.strategyId];
  const series = options.series ?? new SampleMarketDataProvider().getSeries();
  const execution = new SimulatedExecution(settings.feeBps, settings.slippageBps);

  const byAsset = new Map(series.map((s) => [s.info.symbol, s.candles]));
  const symbols = series.map((s) => s.info.symbol);
  const barCount = Math.min(...series.map((s) => s.candles.length));

  let cash = roundCash(settings.startingBalance);
  let peakEquity = cash;
  const openPositions: OpenPosition[] = [];
  const closedTrades: ClosedTrade[] = [];
  const rejectedTrades: RejectedTrade[] = [];
  const leaderTrades: LeaderTrade[] = [];
  const equityCurve: EquityPoint[] = [];
  const leaderOpen = new Map<string, LeaderPos>();
  const pendingEntries: PendingLeader[] = [];
  const pendingExits: PendingExit[] = [];
  const realizedByDay = new Map<string, number>();
  let idSeq = 1;

  const nextId = (prefix: string) => `${prefix}-${idSeq++}`;

  const marksFrom = (getter: (c: { open: number; close: number }) => number, i: number) => {
    const marks: Record<string, number> = {};
    for (const symbol of symbols) {
      const c = byAsset.get(symbol)?.[i];
      if (c) marks[symbol] = getter(c);
    }
    return marks;
  };

  const snapshot = (i: number, priceFn: (c: { open: number; close: number }) => number) => {
    const marks = marksFrom(priceFn, i);
    const equity = roundCash(markToMarket(cash, openPositions, marks));
    peakEquity = Math.max(peakEquity, equity);
    return { marks, equity };
  };

  const recordReject = (
    timestamp: number,
    asset: string,
    side: Side,
    reason: RejectedTrade["reason"],
    detail: string,
    requestedNotional: number,
  ) => {
    rejectedTrades.push({ timestamp, asset, side, reason, detail, requestedNotional });
  };

  const closeFollower = (
    pos: OpenPosition,
    timestamp: number,
    rawExit: number,
    reason: string,
  ) => {
    const action = closingAction(pos.side);
    const fill = execution.placeOrder({
      asset: pos.asset,
      side: action,
      quantity: pos.quantity,
      price: rawExit,
      timestamp,
    });
    const { grossPnl, netPnl } = tradePnl({
      side: pos.side,
      quantity: pos.quantity,
      entryFill: pos.entryPrice,
      exitFill: fill.fillPrice,
      entryFee: pos.entryFee,
      exitFee: fill.fee,
    });
    if (pos.side === "buy") {
      cash = roundCash(cash + pos.quantity * fill.fillPrice - fill.fee);
    } else {
      cash = roundCash(cash + pos.reservedCash + (pos.entryPrice - fill.fillPrice) * pos.quantity - fill.fee);
    }
    const day = dayKey(timestamp);
    realizedByDay.set(day, (realizedByDay.get(day) ?? 0) + netPnl);
    const idx = openPositions.findIndex((p) => p.id === pos.id);
    if (idx >= 0) openPositions.splice(idx, 1);
    closedTrades.push({
      id: pos.id,
      dateTime: pos.entryTime,
      exitTime: timestamp,
      asset: pos.asset,
      side: pos.side,
      entry: pos.entryPrice,
      exit: fill.fillPrice,
      positionSize: pos.notional,
      quantity: pos.quantity,
      fees: roundCash(pos.entryFee + fill.fee),
      slippage: roundCash(pos.entrySlippage + fill.slippage),
      grossPnl,
      netPnl,
      balanceAfter: cash,
      entryReason: pos.entryReason,
      exitReason: reason,
      leaderTradeId: pos.leaderTradeId,
    });
  };

  const closeLeader = (pos: LeaderPos, timestamp: number, rawExit: number, reason: string) => {
    const exitFill = slippedPrice(rawExit, closingAction(pos.side), settings.slippageBps);
    const { netPnl } = tradePnl({
      side: pos.side,
      quantity: pos.qty,
      entryFill: pos.entry,
      exitFill,
      entryFee: feeOnNotional(pos.qty * pos.entry, settings.feeBps),
      exitFee: feeOnNotional(pos.qty * exitFill, settings.feeBps),
    });
    const trade = leaderTrades.find((t) => t.id === pos.id);
    if (trade) {
      trade.status = "closed";
      trade.exitTime = timestamp;
      trade.exitPrice = exitFill;
      trade.profitLoss = netPnl;
      trade.exitReason = reason;
    }
    leaderOpen.delete(pos.asset);
    const follower = openPositions.find((p) => p.leaderTradeId === pos.id);
    if (follower) closeFollower(follower, timestamp, rawExit, `Leader exit: ${reason}`);
  };

  const openLeader = (pending: PendingLeader, timestamp: number, openPrice: number) => {
    const fillPx = slippedPrice(openPrice, pending.side, settings.slippageBps);
    const stops = stopTakePrices(pending.side, fillPx, pending.stopPct, pending.takePct);
    const id = nextId("L");
    const pos: LeaderPos = {
      id,
      asset: pending.asset,
      side: pending.side,
      qty: pending.qty,
      entry: fillPx,
      entryTime: timestamp,
      stopLoss: stops.stopLoss,
      takeProfit: stops.takeProfit,
      reason: pending.reason,
    };
    leaderOpen.set(pending.asset, pos);
    leaderTrades.push({
      id,
      asset: pending.asset,
      side: pending.side,
      entryPrice: fillPx,
      positionSize: pending.qty,
      stopLoss: stops.stopLoss,
      takeProfit: stops.takeProfit,
      entryTime: timestamp,
      exitTime: null,
      exitPrice: null,
      profitLoss: null,
      status: "open",
      entryReason: pending.reason,
      exitReason: null,
    });
    return pos;
  };

  const copyLeaderOpen = (leader: LeaderPos, timestamp: number, openPrice: number, i: number) => {
    const { equity } = snapshot(i, (c) => c.open);
    const risk = evaluateEntryRisk(
      {
        cash,
        equity,
        peakEquity,
        openCount: openPositions.length,
        realizedPnlToday: realizedByDay.get(dayKey(timestamp)) ?? 0,
        stopCopying: Boolean(options.stopCopying),
      },
      settings,
    );
    const requested = roundCash(equity * (settings.copyPercentage / 100));
    if (!risk.allowed) {
      recordReject(
        timestamp,
        leader.asset,
        leader.side,
        risk.reason ?? "stop_copying",
        risk.detail,
        requested,
      );
      return;
    }
    const sized = sizeFollowerPosition({
      equity,
      cash,
      price: openPrice,
      side: leader.side,
      settings,
    });
    if (!sized.accepted) {
      recordReject(
        timestamp,
        leader.asset,
        leader.side,
        sized.rejectReason ?? "zero_size",
        sized.detail,
        sized.requestedNotional,
      );
      return;
    }
    const fill = execution.placeOrder({
      asset: leader.asset,
      side: leader.side,
      quantity: sized.quantity,
      price: openPrice,
      timestamp,
    });
    const stops = stopTakePrices(
      leader.side,
      fill.fillPrice,
      settings.stopLossPct,
      settings.takeProfitPct,
    );
    cash = roundCash(cash - sized.cashRequired);
    const reserved = leader.side === "sell" ? fill.quantity * fill.fillPrice : 0;
    openPositions.push({
      id: nextId("F"),
      asset: leader.asset,
      side: leader.side,
      quantity: fill.quantity,
      entryPrice: fill.fillPrice,
      entryTime: timestamp,
      stopLoss: stops.stopLoss,
      takeProfit: stops.takeProfit,
      entryFee: fill.fee,
      entrySlippage: fill.slippage,
      notional: roundCash(fill.quantity * fill.fillPrice),
      entryReason: `Copy of leader ${leader.id}: ${leader.reason}`,
      leaderTradeId: leader.id,
      reservedCash: reserved,
    });
  };

  for (let i = 0; i < barCount; i += 1) {
    const timestamp = series[0].candles[i].timestamp;

    const exitsNow = pendingExits.splice(0, pendingExits.length);
    for (const exit of exitsNow) {
      const pos = leaderOpen.get(exit.asset);
      const candle = byAsset.get(exit.asset)?.[i];
      if (pos && candle) closeLeader(pos, timestamp, candle.open, exit.reason);
    }

    const entriesNow = pendingEntries.splice(0, pendingEntries.length);
    for (const entry of entriesNow) {
      if (leaderOpen.has(entry.asset)) continue;
      const candle = byAsset.get(entry.asset)?.[i];
      if (!candle) continue;
      const leader = openLeader(entry, timestamp, candle.open);
      copyLeaderOpen(leader, timestamp, candle.open, i);
    }

    for (const symbol of symbols) {
      const candle = byAsset.get(symbol)?.[i];
      if (!candle) continue;
      const followers = openPositions.filter((p) => p.asset === symbol);
      for (const pos of followers) {
        const hit = stopHitOnCandle(pos.side, pos.stopLoss, pos.takeProfit, candle);
        if (hit) {
          closeFollower(
            pos,
            timestamp,
            exitPriceForHit(hit, pos.stopLoss, pos.takeProfit),
            hit === "stop_loss" ? "Follower stop-loss" : "Follower take-profit",
          );
        }
      }
      const leader = leaderOpen.get(symbol);
      if (leader) {
        const hit = stopHitOnCandle(leader.side, leader.stopLoss, leader.takeProfit, candle);
        if (hit) {
          closeLeader(
            leader,
            timestamp,
            exitPriceForHit(hit, leader.stopLoss, leader.takeProfit),
            hit === "stop_loss" ? "Leader stop-loss" : "Leader take-profit",
          );
        }
      }
    }

    for (const symbol of symbols) {
      const candles = byAsset.get(symbol);
      if (!candles) continue;
      const current = leaderOpen.get(symbol);
      const intent = strategy.evaluate(candles.slice(0, i + 1), i, current?.side ?? null);
      if (intent.exit && current) {
        pendingExits.push({
          asset: symbol,
          reason: intent.exitReason ?? "Strategy exit",
          signalTime: timestamp,
        });
      }
      for (const entry of intent.entries) {
        pendingEntries.push({
          asset: symbol,
          side: entry.side,
          reason: entry.reason,
          stopPct: strategy.leaderStopPct,
          takePct: strategy.leaderTakePct,
          qty: strategy.leaderQty,
          signalTime: timestamp,
        });
      }
    }

    const { equity } = snapshot(i, (c) => c.close);
    const dd = currentDrawdownPct(equity, peakEquity);
    equityCurve.push({
      timestamp,
      balance: cash,
      equity,
      drawdownPct: dd,
      cash,
    });
  }

  const lastTs = equityCurve[equityCurve.length - 1]?.timestamp ?? 0;
  const lastMarks = marksFrom((c) => c.close, barCount - 1);
  const endingEquity = roundCash(markToMarket(cash, openPositions, lastMarks));
  const metrics: PerformanceMetrics = computeMetrics({
    settings,
    cash,
    endingEquity,
    equityCurve,
    closedTrades,
    openPositions,
    lastMarks,
    lastTimestamp: lastTs,
  });

  for (const pos of leaderOpen.values()) {
    const trade = leaderTrades.find((t) => t.id === pos.id);
    if (trade && trade.status === "open") {
      const mark = lastMarks[pos.asset] ?? pos.entry;
      const { netPnl } = tradePnl({
        side: pos.side,
        quantity: pos.qty,
        entryFill: pos.entry,
        exitFill: mark,
        entryFee: 0,
        exitFee: 0,
      });
      trade.profitLoss = netPnl;
    }
  }

  return {
    paperTrading: true,
    realOrders: false,
    strategyId: options.strategyId,
    settings,
    metrics,
    equityCurve,
    closedTrades,
    openPositions: [...openPositions],
    rejectedTrades,
    leaderTrades,
    tradeResults: closedTrades.map((t) => ({
      id: t.id,
      netPnl: t.netPnl,
      asset: t.asset,
      exitTime: t.exitTime,
    })),
  };
}

export function compareStrategies(
  settings: SimulatorSettings,
  series?: AssetSeries[],
): Record<StrategyId, SimulationResult> {
  return {
    conservative: runCopyBacktest({ settings, strategyId: "conservative", series }),
    balanced: runCopyBacktest({ settings, strategyId: "balanced", series }),
    aggressive: runCopyBacktest({ settings, strategyId: "aggressive", series }),
  };
}

export { exposureOf };
