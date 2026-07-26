"use client";

import { track } from "@vercel/analytics";

type FeedbackLinkProps = {
  children: React.ReactNode;
  className?: string;
  location: "nav" | "privacy" | "footer";
};

export function FeedbackLink({
  children,
  className,
  location,
}: FeedbackLinkProps) {
  return (
    <a
      className={className}
      href="mailto:hi@gifjot.com?subject=GifJot%20feedback"
      onClick={() => track("feedback_intent", { location })}
    >
      {children}
    </a>
  );
}
