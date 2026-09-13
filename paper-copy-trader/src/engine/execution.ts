import { roundCash, roundPx, roundQty } from "./money";
import type { ExecutionPort, Fill, OrderRequest, Side } from "./types";
import { REAL_EXECUTION_ENABLED } from "./types";

export function slippedPrice(
  price: number,
  action: Side,
  slippageBps: number,
): number {
  const slip = slippageBps / 10_000;
  const filled = action === "buy" ? price * (1 + slip) : price * (1 - slip);
  return roundPx(filled);
}

export function feeOnNotional(notional: number, feeBps: number): number {
  return roundCash(Math.abs(notional) * (feeBps / 10_000));
}

export function closingAction(side: Side): Side {
  return side === "buy" ? "sell" : "buy";
}

export class SimulatedExecution implements ExecutionPort {
  readonly kind = "simulated" as const;

  constructor(
    private readonly feeBps: number,
    private readonly slippageBps: number,
  ) {}

  placeOrder(order: OrderRequest): Fill {
    if (REAL_EXECUTION_ENABLED) {
      throw new Error("Refusing to place an order: real execution flag is true.");
    }
    const qty = roundQty(order.quantity);
    const fillPrice = slippedPrice(order.price, order.side, this.slippageBps);
    const notional = qty * fillPrice;
    const fee = feeOnNotional(notional, this.feeBps);
    const slippage = roundPx(Math.abs(fillPrice - order.price));
    return {
      paper: true,
      asset: order.asset,
      side: order.side,
      quantity: qty,
      requestedPrice: order.price,
      fillPrice,
      fee,
      slippage,
      timestamp: order.timestamp,
    };
  }
}

export class DisabledRealExecution implements ExecutionPort {
  readonly kind = "disabled-real" as const;

  placeOrder(order: OrderRequest): Fill {
    throw new Error(
      `Refusing real order for ${order.asset}. This application is paper trading only and will never send live orders.`,
    );
  }
}

export function assertPaperOnly(): void {
  if (REAL_EXECUTION_ENABLED) {
    throw new Error("Real execution is not allowed in this project.");
  }
}
