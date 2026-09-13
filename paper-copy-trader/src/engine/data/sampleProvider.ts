import type { AssetInfo, AssetSeries, Candle, MarketDataProvider } from "../types";

function mulberry32(seed: number): () => number {
  let a = seed >>> 0;
  return () => {
    a |= 0;
    a = (a + 0x6d2b79f5) | 0;
    let t = Math.imul(a ^ (a >>> 15), 1 | a);
    t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

function gaussian(rand: () => number): number {
  const u = Math.max(rand(), 1e-12);
  const v = Math.max(rand(), 1e-12);
  return Math.sqrt(-2 * Math.log(u)) * Math.cos(2 * Math.PI * v);
}

interface SampleSpec {
  info: AssetInfo;
  startPrice: number;
  mu: number;
  sigma: number;
  seed: number;
}

const SPECS: SampleSpec[] = [
  {
    info: { symbol: "BTC-EUR", name: "Bitcoin (sample)", currency: "EUR" },
    startPrice: 38_500,
    mu: 0.00032,
    sigma: 0.024,
    seed: 202401,
  },
  {
    info: { symbol: "ETH-EUR", name: "Ethereum (sample)", currency: "EUR" },
    startPrice: 2_150,
    mu: 0.00028,
    sigma: 0.03,
    seed: 202402,
  },
  {
    info: { symbol: "XAU-EUR", name: "Gold (sample)", currency: "EUR" },
    startPrice: 1_880,
    mu: 0.0001,
    sigma: 0.009,
    seed: 202403,
  },
  {
    info: { symbol: "EQY-EUR", name: "Sample equity index", currency: "EUR" },
    startPrice: 96,
    mu: 0.00018,
    sigma: 0.013,
    seed: 202404,
  },
];

export const SAMPLE_DAY_COUNT = 730;
export const SAMPLE_START_UTC = Date.UTC(2024, 0, 1);

function generateCandles(spec: SampleSpec, days: number, startUtc: number): Candle[] {
  const rand = mulberry32(spec.seed);
  const candles: Candle[] = [];
  let close = spec.startPrice;
  for (let i = 0; i < days; i += 1) {
    const z = gaussian(rand);
    const regime = Math.floor(i / 70) % 2 === 0 ? 1 : -1;
    const drift = spec.mu * 6 * regime;
    const nextClose = close * Math.exp((drift - 0.5 * spec.sigma ** 2) + spec.sigma * z);
    const openJump = 0.002 * gaussian(rand);
    const open = close * Math.exp(openJump);
    const highExtra = Math.abs(gaussian(rand)) * spec.sigma * close * 0.6;
    const lowExtra = Math.abs(gaussian(rand)) * spec.sigma * close * 0.6;
    const high = Math.max(open, nextClose) + highExtra;
    const low = Math.max(0.01, Math.min(open, nextClose) - lowExtra);
    const volume = 100 + rand() * 900;
    candles.push({
      timestamp: startUtc + i * 86_400_000,
      open: Number(open.toFixed(4)),
      high: Number(high.toFixed(4)),
      low: Number(low.toFixed(4)),
      close: Number(nextClose.toFixed(4)),
      volume: Number(volume.toFixed(2)),
    });
    close = nextClose;
  }
  return candles;
}

let cached: AssetSeries[] | null = null;

export function generateSampleSeries(): AssetSeries[] {
  if (cached) return cached;
  cached = SPECS.map((spec) => ({
    info: spec.info,
    candles: generateCandles(spec, SAMPLE_DAY_COUNT, SAMPLE_START_UTC),
  }));
  return cached;
}

export class SampleMarketDataProvider implements MarketDataProvider {
  readonly kind = "sample" as const;
  private readonly series: AssetSeries[];

  constructor(series: AssetSeries[] = generateSampleSeries()) {
    this.series = series;
  }

  listAssets(): AssetInfo[] {
    return this.series.map((s) => s.info);
  }

  getHistory(symbol: string): Candle[] {
    const found = this.series.find((s) => s.info.symbol === symbol);
    return found ? found.candles : [];
  }

  getSeries(): AssetSeries[] {
    return this.series;
  }
}

export function parseCsvCandles(csv: string): Candle[] {
  const lines = csv.trim().split(/\r?\n/);
  const rows = lines.slice(1);
  return rows.map((line) => {
    const [timestamp, open, high, low, close, volume] = line.split(",");
    const ts = Date.parse(timestamp);
    return {
      timestamp: Number.isFinite(ts) ? ts : Number(timestamp),
      open: Number(open),
      high: Number(high),
      low: Number(low),
      close: Number(close),
      volume: Number(volume),
    };
  });
}

export class CsvMarketDataProvider implements MarketDataProvider {
  readonly kind = "csv" as const;
  constructor(private readonly series: AssetSeries[]) {}

  listAssets(): AssetInfo[] {
    return this.series.map((s) => s.info);
  }

  getHistory(symbol: string): Candle[] {
    return this.series.find((s) => s.info.symbol === symbol)?.candles ?? [];
  }

  getSeries(): AssetSeries[] {
    return this.series;
  }
}

/**
 * Future market-data APIs should implement MarketDataProvider.
 * They must only fetch public market data. They must never place orders
 * or store API keys in this first version.
 */
export class FutureApiMarketDataProvider implements MarketDataProvider {
  readonly kind = "api" as const;

  listAssets(): AssetInfo[] {
    throw new Error("Live market-data APIs are not wired in v1. Use sample or CSV data.");
  }

  getHistory(): Candle[] {
    throw new Error("Live market-data APIs are not wired in v1. Use sample or CSV data.");
  }

  getSeries(): AssetSeries[] {
    throw new Error("Live market-data APIs are not wired in v1. Use sample or CSV data.");
  }
}
