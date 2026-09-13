import type { SimulatorSettings } from "./types";

export const DEFAULT_STARTING_BALANCE = 500;

export const DEFAULT_SETTINGS: SimulatorSettings = {
  startingBalance: DEFAULT_STARTING_BALANCE,
  copyPercentage: 10,
  maxPositionSize: 150,
  maxDailyLoss: 40,
  maxTotalDrawdownPct: 25,
  stopLossPct: 3,
  takeProfitPct: 6,
  maxSimultaneousPositions: 3,
  feeBps: 10,
  slippageBps: 5,
};

export const STRATEGY_META: Record<
  "conservative" | "balanced" | "aggressive",
  { title: string; summary: string; disclaimer: string }
> = {
  conservative: {
    title: "Conservative",
    summary:
      "Slow moving-average crossover. Fewer simulated trades, wider targets, longer warmup.",
    disclaimer:
      "Hypothetical rules only. This is not a recommendation and is not claimed to be profitable.",
  },
  balanced: {
    title: "Balanced",
    summary:
      "Medium moving-average crossover with an RSI filter. Moderate simulated trade frequency.",
    disclaimer:
      "Hypothetical rules only. This is not a recommendation and is not claimed to be profitable.",
  },
  aggressive: {
    title: "Aggressive",
    summary:
      "Fast moving averages and RSI swings. More simulated trades and tighter stops.",
    disclaimer:
      "Hypothetical rules only. This is not a recommendation and is not claimed to be profitable.",
  },
};
