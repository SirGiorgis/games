"use client";

import { useSimulatorStore } from "@/store/simulatorStore";
import { OctagonX } from "lucide-react";

export function StopCopyingButton({ compact = false }: { compact?: boolean }) {
  const stopCopying = useSimulatorStore((s) => s.stopCopying);
  const setStopCopying = useSimulatorStore((s) => s.setStopCopying);
  return (
    <button
      type="button"
      onClick={() => setStopCopying(!stopCopying)}
      className="inline-flex min-h-11 items-center justify-center gap-2 rounded-xl px-4 text-sm font-black tracking-wide"
      style={{
        background: stopCopying ? "var(--accent-soft)" : "#7f1d1d",
        color: stopCopying ? "var(--banner-fg)" : "#fff5f5",
        border: "1px solid var(--line)",
      }}
    >
      <OctagonX size={16} />
      {compact ? (stopCopying ? "Stopped" : "STOP") : stopCopying ? "Resume copying" : "STOP COPYING"}
    </button>
  );
}
