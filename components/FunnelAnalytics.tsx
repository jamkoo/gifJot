"use client";

import { useEffect } from "react";
import { track } from "@vercel/analytics";

export function FunnelAnalytics() {
  useEffect(() => {
    const productProof = document.querySelector(".use-cases");
    if (!productProof) {
      return;
    }

    const observer = new IntersectionObserver(
      ([entry]) => {
        if (!entry?.isIntersecting) {
          return;
        }

        track("product_proof_viewed", { section: "use_cases" });
        observer.disconnect();
      },
      {
        rootMargin: "0px 0px -20% 0px",
        threshold: 0.35,
      },
    );

    observer.observe(productProof);
    return () => observer.disconnect();
  }, []);

  return null;
}
