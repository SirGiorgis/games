"use client";

import { runCopyBacktest } from "@/engine/backtest";
import { useSimulatorStore } from "@/store/simulatorStore";
import { useMemo } from "react";

export function useSimulation() {
  const settings = useSimulatorStore((s) => s.settings);
  const strategyId = useSimulatorStore((s) => s.strategyId);
  const stopCopying = useSimulatorStore((s) => s.stopCopying);
  const customSeries = useSimulatorStore((s) => s.customSeries);
  return useMemo(
    () =>
      runCopyBacktest({
        settings,
        strategyId,
        stopCopying,
        series: customSeries ?? undefined,
      }),
    [settings, strategyId, stopCopying, customSeries],
  );
}
