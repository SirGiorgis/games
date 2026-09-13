"use client";

import { SettingsForm } from "@/components/SettingsForm";
import { REAL_EXECUTION_ENABLED } from "@/engine/types";
import { useSimulatorStore } from "@/store/simulatorStore";

export default function SettingsPage() {
  const strategyId = useSimulatorStore((s) => s.strategyId);
  return (
    <div className="space-y-4">
      <div>
        <h1 className="text-2xl font-black">Settings</h1>
        <p className="mt-1 max-w-3xl text-sm" style={{ color: "var(--muted)" }}>
          All values apply to the virtual follower account. Nothing here stores API keys, and nothing
          can place a live order.
        </p>
      </div>
      <section className="card space-y-2 p-4 text-sm">
        <div>
          Real execution enabled:{" "}
          <strong className="tabular">{String(REAL_EXECUTION_ENABLED)}</strong>
        </div>
        <div>
          Selected hypothetical leader: <strong>{strategyId}</strong>
        </div>
        <div style={{ color: "var(--muted)" }}>
          Market data: bundled sample OHLCV (no credentials). A MarketDataProvider interface is ready
          for a later read-only data API. Order execution adapters other than SimulatedExecution throw.
        </div>
      </section>
      <SettingsForm />
    </div>
  );
}
