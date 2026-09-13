"use client";

import { useSimulatorStore } from "@/store/simulatorStore";
import { Moon, Sun } from "lucide-react";

export function ThemeToggle() {
  const theme = useSimulatorStore((s) => s.theme);
  const toggleTheme = useSimulatorStore((s) => s.toggleTheme);
  return (
    <button
      type="button"
      className="soft-btn inline-flex items-center gap-2 text-sm"
      onClick={toggleTheme}
      aria-label="Toggle color theme"
    >
      {theme === "dark" ? <Sun size={16} /> : <Moon size={16} />}
      <span className="hidden sm:inline">{theme === "dark" ? "Light" : "Dark"}</span>
    </button>
  );
}
