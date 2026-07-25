"use client";

import { useGSAP } from "@gsap/react";
import gsap from "gsap";
import { ScrollTrigger } from "gsap/ScrollTrigger";

gsap.registerPlugin(useGSAP, ScrollTrigger);

type MotionConditions = {
  isDesktop: boolean;
  isMobile: boolean;
  reduceMotion: boolean;
};

export function MotionSystem() {
  useGSAP(() => {
    const media = gsap.matchMedia();

    media.add(
      {
        isDesktop: "(min-width: 701px)",
        isMobile: "(max-width: 700px)",
        reduceMotion: "(prefers-reduced-motion: reduce)",
      },
      (context) => {
        const { isMobile, reduceMotion } =
          context.conditions as MotionConditions;

        if (reduceMotion) {
          return;
        }

        const heroTimeline = gsap.timeline({
          defaults: {
            ease: "expo.out",
          },
        });

        heroTimeline
          .from(
            ".site-header > *",
            {
              autoAlpha: 0,
              clearProps: "transform,opacity,visibility",
              duration: 0.42,
              stagger: 0.045,
              y: -10,
            },
            0,
          )
          .from(
            ".hero-note",
            {
              autoAlpha: 0,
              clearProps: "transform,opacity,visibility",
              duration: 0.38,
              x: -10,
            },
            0.04,
          )
          .from(
            ".hero h1",
            {
              autoAlpha: 0.2,
              clearProps: "transform,opacity,visibility,clipPath",
              clipPath: "inset(0 0 22% 0)",
              duration: 0.7,
              yPercent: 10,
            },
            0.05,
          )
          .from(
            [".hero-lede", ".hero-actions", ".compatibility"],
            {
              autoAlpha: 0.18,
              clearProps: "transform,opacity,visibility",
              duration: 0.46,
              stagger: 0.055,
              y: 14,
            },
            0.2,
          )
          .from(
            ".hero-demo-stage",
            {
              autoAlpha: 0.2,
              clearProps: "transform,opacity,visibility,clipPath",
              clipPath: "inset(4% 5% 8% 6% round 24px)",
              duration: 0.72,
              scale: 0.965,
            },
            0.06,
          )
          .from(
            ".hero .selection-frame",
            {
              clearProps: "clipPath",
              clipPath: "inset(0 100% 100% 0)",
              duration: 0.52,
            },
            0.42,
          )
          .from(
            ".hero .frame-handle, .hero .frame-move-grip",
            {
              autoAlpha: 0,
              clearProps: "opacity,visibility",
              duration: 0.24,
              stagger: 0.025,
            },
            0.64,
          )
          .from(
            ".hero .hud-ready > *",
            {
              autoAlpha: 0,
              clearProps: "transform,opacity,visibility",
              duration: 0.3,
              stagger: 0.03,
              y: 5,
            },
            0.68,
          );

        const workflowTimeline = gsap.timeline({
          scrollTrigger: {
            trigger: ".workflow",
            start: "top 74%",
            once: true,
          },
        });

        workflowTimeline
          .from(".workflow .section-heading > *", {
            autoAlpha: 0,
            clearProps: "transform,opacity,visibility",
            duration: 0.54,
            ease: "power3.out",
            stagger: 0.07,
            y: 18,
          })
          .fromTo(
            ".workflow-list",
            { "--motion-progress": 0 },
            {
              "--motion-progress": 1,
              duration: 0.74,
              ease: "power2.out",
            },
            0.04,
          )
          .from(
            ".workflow-list li",
            {
              autoAlpha: 0,
              clearProps: "transform,opacity,visibility",
              duration: 0.5,
              ease: "power3.out",
              stagger: 0.09,
              x: isMobile ? 10 : 22,
            },
            0.12,
          );

        const useCaseTimeline = gsap.timeline({
          scrollTrigger: {
            trigger: ".use-cases",
            start: "top 72%",
            once: true,
          },
        });

        useCaseTimeline
          .from(".example-clip", {
            autoAlpha: 0,
            clearProps: "transform,opacity,visibility",
            duration: 0.58,
            ease: "power3.out",
            stagger: 0.09,
            y: 20,
          })
          .from(
            ".mini-cursor",
            {
              autoAlpha: 0,
              clearProps: "transform,opacity,visibility",
              duration: 0.72,
              ease: "expo.out",
              rotation: -30,
              stagger: 0.1,
              x: (index) => [-62, -46, -58][index] ?? -52,
              y: (index) => [-36, -28, -32][index] ?? -32,
            },
            "-=0.34",
          );

        const privacyTimeline = gsap.timeline({
          scrollTrigger: {
            trigger: ".privacy",
            start: "top 70%",
            once: true,
          },
        });

        privacyTimeline
          .from(".privacy-frame", {
            autoAlpha: 0.58,
            clearProps: "transform,opacity,visibility,clipPath",
            clipPath: "inset(10% 8% 14% 7%)",
            duration: 0.72,
            ease: "expo.out",
            scale: 0.975,
          })
          .from(
            ".privacy-frame img",
            {
              clearProps: "transform",
              duration: 0.55,
              ease: "expo.out",
              scale: 0.88,
            },
            "-=0.45",
          )
          .from(
            ".local-path",
            {
              autoAlpha: 0,
              clearProps: "transform,opacity,visibility",
              duration: 0.42,
              ease: "power3.out",
              y: 10,
            },
            "-=0.3",
          )
          .from(
            ".blocked-cloud",
            {
              autoAlpha: 0,
              clearProps: "transform,opacity,visibility",
              duration: 0.5,
              ease: "expo.out",
              x: -30,
            },
            "-=0.38",
          );

        const closingTimeline = gsap.timeline({
          scrollTrigger: {
            trigger: ".closing",
            start: "top 72%",
            once: true,
          },
        });

        closingTimeline
          .from(".closing-frame", {
            autoAlpha: 0.3,
            clearProps: "transform,opacity,visibility",
            duration: 0.7,
            ease: "expo.out",
            scale: 1.045,
          })
          .from(
            ".closing > img, .closing > h2, .closing > p, .closing > .button",
            {
              autoAlpha: 0,
              clearProps: "transform,opacity,visibility",
              duration: 0.52,
              ease: "power3.out",
              stagger: 0.065,
              y: 14,
            },
            "-=0.42",
          );
      },
    );

    return () => media.revert();
  });

  return null;
}
