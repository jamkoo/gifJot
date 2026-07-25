"use client";

import { track } from "@vercel/analytics";

type FounderSetupLinkProps = {
  className?: string;
};

export function FounderSetupLink({ className }: FounderSetupLinkProps) {
  return (
    <a
      className={className}
      href="mailto:hi@gifjot.com?subject=Help%20me%20make%20my%20first%20GifJot%20GIF&body=Hi%2C%0A%0AI%27d%20like%20a%2010-minute%20GifJot%20setup.%0A%0AWhat%20I%20want%20to%20show%3A%20"
      onClick={() =>
        track("founder_setup_intent", {
          location: "hero",
        })
      }
    >
      Want help? Get a 10-minute setup with the maker
      <span aria-hidden="true"> →</span>
    </a>
  );
}
