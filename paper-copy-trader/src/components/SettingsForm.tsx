"use client";

import { DEFAULT_SETTINGS } from "@/engine/defaults";
import { useSimulatorStore } from "@/store/simulatorStore";

const FIELDS: {
  key: keyof typeof DEFAULT_SETTINGS;
  label: string;
  hint: string;
  min: number;
  max: number;
  step: number;
}[] = [
  { key: "startingBalance", label: "Starting balance (€)", hint: "Virtual cash only. Default €500.", min: 1, max: 1_000_000, step: 10 },
  { key: "copyPercentage", label: "Copy percentage (%)", hint: "Share of account allocated to each copied trade.", min: 0.1, max: 100, step: 0.5 },
  { key: "maxPositionSize", label: "Maximum position size (€)", hint: "Hard cap on notional per paper trade.", min: 1, max: 1_000_000, step: 10 },
  { key: "maxDailyLoss", label: "Maximum daily loss (€)", hint: "No new copies after this realized loss in a day.", min: 1, max: 1_000_000, step: 5 },
  { key: "maxTotalDrawdownPct", label: "Maximum total drawdown (%)", hint: "Peak-to-trough equity limit.", min: 1, max: 99, step: 1 },
  { key: "stopLossPct", label: "Stop-loss (%)", hint: "Follower stop from fill price.", min: 0.1, max: 90, step: 0.1 },
  { key: "takeProfitPct", label: "Take-profit (%)", hint: "Follower target from fill price.", min: 0.1, max: 500, step: 0.1 },
  { key: "maxSimultaneousPositions", label: "Maximum simultaneous positions", hint: "Open paper positions allowed at once.", min: 1, max: 20, step: 1 },
  { key: "feeBps", label: "Trading fee (bps)", hint: "10 bps = 0.10% per side.", min: 0, max: 200, step: 1 },
  { key: "slippageBps", label: "Slippage (bps)", hint: "Adverse fill vs. signal price.", min: 0, max: 200, step: 1 },
];

export function SettingsForm() {
  const settings = useSimulatorStore((s) => s.settings);
  const setSettings = useSimulatorStore((s) => s.setSettings);
  const resetSettings = useSimulatorStore((s) => s.resetSettings);
  return (
    <form className="grid grid-cols-1 gap-3 md:grid-cols-2" onSubmit={(e) => e.preventDefault()}>
      {FIELDS.map((field) => (
        <label key={field.key} className="card space-y-1 p-3">
          <div className="text-sm font-semibold">{field.label}</div>
          <div className="hint">{field.hint}</div>
          <input
            type="number"
            min={field.min}
            max={field.max}
            step={field.step}
            value={settings[field.key]}
            onChange={(e) => {
              const value = Number(e.target.value);
              if (Number.isFinite(value)) setSettings({ [field.key]: value });
            }}
          />
        </label>
      ))}
      <div className="md:col-span-2">
        <button type="button" className="soft-btn" onClick={resetSettings}>
          Reset to €500 defaults
        </button>
      </div>
    </form>
  );
}
