export function roundCash(value: number): number {
  return Math.round((value + Number.EPSILON) * 100) / 100;
}

export function roundQty(value: number): number {
  return Math.round((value + Number.EPSILON) * 1e8) / 1e8;
}

export function roundPx(value: number): number {
  return Math.round((value + Number.EPSILON) * 1e8) / 1e8;
}

export function clamp(value: number, min: number, max: number): number {
  return Math.min(max, Math.max(min, value));
}

export function almostZero(value: number, epsilon = 1e-10): boolean {
  return Math.abs(value) < epsilon;
}
