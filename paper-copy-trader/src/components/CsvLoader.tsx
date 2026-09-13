"use client";

import { parseCsvCandles } from "@/engine/data/sampleProvider";
import type { AssetSeries } from "@/engine/types";
import { useSimulatorStore } from "@/store/simulatorStore";

export function CsvLoader() {
  const setCustomSeries = useSimulatorStore((s) => s.setCustomSeries);
  const customSeries = useSimulatorStore((s) => s.customSeries);

  async function onFiles(files: FileList | null) {
    if (!files || files.length === 0) return;
    const series: AssetSeries[] = [];
    for (const file of Array.from(files)) {
      const text = await file.text();
      const candles = parseCsvCandles(text).filter((c) => Number.isFinite(c.timestamp) && c.close > 0);
      if (candles.length < 30) continue;
      const symbol = file.name.replace(/\.csv$/i, "").toUpperCase();
      series.push({
        info: { symbol, name: `${symbol} (csv)`, currency: "EUR" },
        candles,
      });
    }
    if (series.length) setCustomSeries(series);
  }

  return (
    <div className="card space-y-2 p-4 text-sm">
      <div className="font-bold">Load sample / CSV history</div>
      <p style={{ color: "var(--muted)" }}>
        Default run uses bundled sample bars. Optionally load one or more CSV files named like{" "}
        <code>BTC-EUR.csv</code> with columns timestamp,open,high,low,close,volume. Parsed only in
        this browser — nothing is uploaded and no API key is used.
      </p>
      <input
        type="file"
        accept=".csv,text/csv"
        multiple
        onChange={(e) => void onFiles(e.target.files)}
      />
      <div className="flex flex-wrap gap-2">
        <button type="button" className="soft-btn" onClick={() => setCustomSeries(null)}>
          Use bundled sample data
        </button>
        {customSeries ? (
          <span className="self-center text-xs" style={{ color: "var(--muted)" }}>
            Custom files: {customSeries.map((s) => s.info.symbol).join(", ")}
          </span>
        ) : (
          <span className="self-center text-xs" style={{ color: "var(--muted)" }}>
            Using bundled sample data
          </span>
        )}
      </div>
    </div>
  );
}
