import { DEFAULT_SETTINGS } from "@/engine/defaults";
import type { AssetSeries, SimulationResult, SimulatorSettings, StrategyId } from "@/engine/types";
import { create } from "zustand";
import { persist } from "zustand/middleware";

interface SimulatorState {
  settings: SimulatorSettings;
  strategyId: StrategyId;
  stopCopying: boolean;
  theme: "dark" | "light";
  lastResult: SimulationResult | null;
  customSeries: AssetSeries[] | null;
  setSettings: (patch: Partial<SimulatorSettings>) => void;
  replaceSettings: (settings: SimulatorSettings) => void;
  setStrategyId: (id: StrategyId) => void;
  setStopCopying: (value: boolean) => void;
  toggleTheme: () => void;
  setLastResult: (result: SimulationResult | null) => void;
  setCustomSeries: (series: AssetSeries[] | null) => void;
  resetSettings: () => void;
}

export const useSimulatorStore = create<SimulatorState>()(
  persist(
    (set) => ({
      settings: { ...DEFAULT_SETTINGS },
      strategyId: "balanced",
      stopCopying: false,
      theme: "dark",
      lastResult: null,
      customSeries: null,
      setSettings: (patch) =>
        set((state) => ({ settings: { ...state.settings, ...patch } })),
      replaceSettings: (settings) => set({ settings }),
      setStrategyId: (strategyId) => set({ strategyId }),
      setStopCopying: (stopCopying) => set({ stopCopying }),
      toggleTheme: () =>
        set((state) => ({ theme: state.theme === "dark" ? "light" : "dark" })),
      setLastResult: (lastResult) => set({ lastResult }),
      setCustomSeries: (customSeries) => set({ customSeries }),
      resetSettings: () => set({ settings: { ...DEFAULT_SETTINGS }, stopCopying: false }),
    }),
    {
      name: "paper-copy-trader-v1",
      partialize: (state) => ({
        settings: state.settings,
        strategyId: state.strategyId,
        stopCopying: state.stopCopying,
        theme: state.theme,
      }),
    },
  ),
);
