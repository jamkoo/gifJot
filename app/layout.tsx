import type { Metadata } from "next";
import { Analytics } from "@vercel/analytics/next";
import appIcon from "@/assets/GifJot-Icon.png";
import "./globals.css";

export const metadata: Metadata = {
  metadataBase: new URL("https://gifjot.com"),
  title: "GifJot — Turn any part of your Mac screen into a GIF",
  description:
    "A free native macOS menu-bar app for recording any screen region as a paste-ready GIF. Local only, with no accounts, uploads, telemetry, or watermarks.",
  applicationName: "GifJot",
  icons: {
    icon: appIcon.src,
    apple: appIcon.src,
  },
  openGraph: {
    title: "GifJot — Show it. Don’t explain it.",
    description:
      "Turn any part of your Mac screen into a paste-ready GIF. Free, native, and local only.",
    type: "website",
    url: "/",
    siteName: "GifJot",
    images: [
      {
        url: "/og.png",
        width: 1200,
        height: 630,
        alt: "GifJot — Show it. Don’t explain it.",
      },
    ],
  },
  twitter: {
    card: "summary_large_image",
    title: "GifJot — Show it. Don’t explain it.",
    description:
      "Turn any part of your Mac screen into a paste-ready GIF.",
    images: ["/og.png"],
  },
  robots: {
    index: true,
    follow: true,
  },
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <body>
        {children}
        <Analytics />
      </body>
    </html>
  );
}
