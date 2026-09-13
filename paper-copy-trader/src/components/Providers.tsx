"use client";

import { useSimulatorStore } from "@/store/simulatorStore";
import { useEffect, useState } from "react";

export function Providers({ children }: { children: React.ReactNode }) {
  const theme = useSimulatorStore((s) => s.theme);
  const [ready, setReady] = useState(false);

  useEffect(() => {
    setReady(true);
  }, []);

  useEffect(() => {
    const root = document.documentElement;
    root.classList.remove("dark", "light");
    root.classList.add(theme);
  }, [theme, ready]);

  return <>{children}</>;
}
