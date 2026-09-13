import { PAPER_TRADING_LABEL } from "@/engine/types";

export function PaperBanner() {
  return (
    <div
      role="status"
      className="sticky top-0 z-40 border-b px-3 py-2 text-center text-[11px] font-black tracking-[0.14em] sm:text-xs"
      style={{
        background: "var(--banner-bg)",
        color: "var(--banner-fg)",
        borderColor: "var(--line)",
      }}
    >
      {PAPER_TRADING_LABEL}
    </div>
  );
}
