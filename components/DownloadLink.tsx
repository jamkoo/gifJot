"use client";

import { track } from "@vercel/analytics";

const DOWNLOAD_URL =
  "https://github.com/jamkoo/gifJot/releases/latest/download/GifJot.dmg";
const RELEASE_VERSION = "0.1.2";

type DownloadLinkProps = {
  children: React.ReactNode;
  className?: string;
  location: "nav" | "hero" | "close";
};

export function DownloadLink({
  children,
  className,
  location,
}: DownloadLinkProps) {
  return (
    <a
      className={className}
      href={DOWNLOAD_URL}
      onClick={() =>
        track("download_click", {
          location,
          version: RELEASE_VERSION,
        })
      }
    >
      {children}
    </a>
  );
}
