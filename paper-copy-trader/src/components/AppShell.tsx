"use client";

import { PaperBanner } from "@/components/PaperBanner";
import { StopCopyingButton } from "@/components/StopCopyingButton";
import { ThemeToggle } from "@/components/ThemeToggle";
import {
  FlaskConical,
  LayoutDashboard,
  ListOrdered,
  Settings,
  ShieldAlert,
  Waypoints,
} from "lucide-react";
import Link from "next/link";
import { usePathname } from "next/navigation";

const NAV = [
  { href: "/", label: "Dashboard", short: "Home", icon: LayoutDashboard },
  { href: "/strategies", label: "Strategies", short: "Strat", icon: Waypoints },
  { href: "/backtest", label: "Backtest", short: "Test", icon: FlaskConical },
  { href: "/trades", label: "Trades", short: "Log", icon: ListOrdered },
  { href: "/risk", label: "Risk", short: "Risk", icon: ShieldAlert },
  { href: "/settings", label: "Settings", short: "Set", icon: Settings },
];

export function AppShell({ children }: { children: React.ReactNode }) {
  const pathname = usePathname();
  return (
    <div className="min-h-dvh" style={{ background: "var(--bg)", color: "var(--text)" }}>
      <PaperBanner />
      <div className="mx-auto flex max-w-7xl">
        <aside className="sticky top-[42px] hidden h-[calc(100dvh-42px)] w-56 shrink-0 flex-col border-r p-4 md:flex" style={{ borderColor: "var(--line)" }}>
          <div className="mb-6">
            <div className="text-xs font-bold uppercase tracking-[0.2em]" style={{ color: "var(--muted)" }}>
              Paper terminal
            </div>
            <div className="mt-1 text-lg font-black">Copy Sim</div>
          </div>
          <nav className="flex flex-1 flex-col gap-1">
            {NAV.map((item) => {
              const active = pathname === item.href;
              const Icon = item.icon;
              return (
                <Link
                  key={item.href}
                  href={item.href}
                  className="flex min-h-11 items-center gap-3 rounded-xl px-3 text-sm font-semibold"
                  style={{
                    background: active ? "var(--bg-elev)" : "transparent",
                    border: active ? "1px solid var(--line)" : "1px solid transparent",
                  }}
                >
                  <Icon size={18} />
                  {item.label}
                </Link>
              );
            })}
          </nav>
          <div className="space-y-2">
            <StopCopyingButton />
            <ThemeToggle />
          </div>
        </aside>
        <div className="min-w-0 flex-1">
          <header className="flex items-center justify-between gap-2 border-b px-3 py-3 md:hidden" style={{ borderColor: "var(--line)" }}>
            <div>
              <div className="text-[10px] font-bold uppercase tracking-[0.18em]" style={{ color: "var(--muted)" }}>
                Paper terminal
              </div>
              <div className="text-base font-black">Copy Sim</div>
            </div>
            <div className="flex items-center gap-2">
              <StopCopyingButton compact />
              <ThemeToggle />
            </div>
          </header>
          <main className="px-3 py-4 pb-28 sm:px-6 md:pb-8">{children}</main>
        </div>
      </div>
      <nav
        className="fixed inset-x-0 bottom-0 z-40 grid grid-cols-6 border-t md:hidden"
        style={{
          background: "var(--bg-elev)",
          borderColor: "var(--line)",
          paddingBottom: "max(0.4rem, env(safe-area-inset-bottom))",
        }}
      >
        {NAV.map((item) => {
          const active = pathname === item.href;
          const Icon = item.icon;
          return (
            <Link
              key={item.href}
              href={item.href}
              className="flex min-h-14 flex-col items-center justify-center gap-0.5 text-[10px] font-semibold"
              style={{ color: active ? "var(--accent)" : "var(--muted)" }}
            >
              <Icon size={18} />
              {item.short}
            </Link>
          );
        })}
      </nav>
    </div>
  );
}
