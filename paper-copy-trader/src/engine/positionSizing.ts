import { feeOnNotional, slippedPrice } from "./execution";
import { almostZero, roundCash, roundQty } from "./money";
import type { Side, SimulatorSettings } from "./types";

export interface SizeRequest {
  equity: number;
  cash: number;
  price: number;
  side: Side;
  settings: SimulatorSettings;
}

export interface SizeResult {
  accepted: boolean;
  reduced: boolean;
  quantity: number;
  fillPrice: number;
  notional: number;
  fee: number;
  cashRequired: number;
  requestedNotional: number;
  rejectReason?: "insufficient_cash" | "zero_size" | "max_position_size";
  detail: string;
}

export function desiredCopyNotional(
  equity: number,
  settings: Pick<SimulatorSettings, "copyPercentage" | "maxPositionSize">,
): number {
  const raw = equity * (settings.copyPercentage / 100);
  return roundCash(Math.min(raw, settings.maxPositionSize));
}

export function sizeFollowerPosition(request: SizeRequest): SizeResult {
  const { equity, cash, price, side, settings } = request;
  const requested = desiredCopyNotional(equity, settings);
  const fillPrice = slippedPrice(price, side, settings.slippageBps);

  if (requested <= 0 || price <= 0 || fillPrice <= 0) {
    return {
      accepted: false,
      reduced: false,
      quantity: 0,
      fillPrice,
      notional: 0,
      fee: 0,
      cashRequired: 0,
      requestedNotional: requested,
      rejectReason: "zero_size",
      detail: "Requested position size is zero.",
    };
  }

  const feeRate = settings.feeBps / 10_000;
  const cashBudget = Math.max(0, cash);
  const maxAffordableNotional = cashBudget / (1 + feeRate);
  const cappedNotional = Math.min(
    requested,
    settings.maxPositionSize,
    maxAffordableNotional,
  );

  let reduced = cappedNotional + 1e-9 < requested;
  let quantity = roundQty(cappedNotional / fillPrice);
  let notional = roundCash(quantity * fillPrice);
  let fee = feeOnNotional(notional, settings.feeBps);
  let cashRequired = roundCash(notional + fee);

  if (cashRequired > cashBudget + 1e-9 && fillPrice > 0) {
    const affordableQty = roundQty(cashBudget / (fillPrice * (1 + feeRate)));
    quantity = affordableQty;
    notional = roundCash(quantity * fillPrice);
    fee = feeOnNotional(notional, settings.feeBps);
    cashRequired = roundCash(notional + fee);
    reduced = true;
  }

  if (almostZero(quantity) || notional < 0.01 || cashRequired > cashBudget + 0.01) {
    return {
      accepted: false,
      reduced,
      quantity: 0,
      fillPrice,
      notional: 0,
      fee: 0,
      cashRequired,
      requestedNotional: requested,
      rejectReason: "insufficient_cash",
      detail: `Need €${cashRequired.toFixed(2)} but only €${cashBudget.toFixed(2)} cash is available.`,
    };
  }

  if (notional > settings.maxPositionSize + 0.01) {
    return {
      accepted: false,
      reduced,
      quantity: 0,
      fillPrice,
      notional,
      fee,
      cashRequired,
      requestedNotional: requested,
      rejectReason: "max_position_size",
      detail: `Notional €${notional.toFixed(2)} exceeds max position size €${settings.maxPositionSize.toFixed(2)}.`,
    };
  }

  return {
    accepted: true,
    reduced,
    quantity,
    fillPrice,
    notional,
    fee,
    cashRequired,
    requestedNotional: requested,
    detail: reduced
      ? "Position reduced to fit cash or max position size."
      : "Position sized from copy percentage.",
  };
}

export function stopTakePrices(
  side: Side,
  entryFill: number,
  stopLossPct: number,
  takeProfitPct: number,
): { stopLoss: number; takeProfit: number } {
  const sl = stopLossPct / 100;
  const tp = takeProfitPct / 100;
  if (side === "buy") {
    return {
      stopLoss: roundCash(entryFill * (1 - sl)),
      takeProfit: roundCash(entryFill * (1 + tp)),
    };
  }
  return {
    stopLoss: roundCash(entryFill * (1 + sl)),
    takeProfit: roundCash(entryFill * (1 - tp)),
  };
}
