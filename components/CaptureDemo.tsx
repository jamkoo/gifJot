"use client";

import { useEffect, useState } from "react";

const steps = [
  {
    label: "Select",
    detail: "Drag around the part that matters.",
  },
  {
    label: "Record",
    detail: "Capture a few seconds. Stop when it’s clear.",
  },
  {
    label: "Paste",
    detail: "Your GIF is saved locally and ready to paste.",
  },
] as const;

export function CaptureDemo() {
  const [activeStep, setActiveStep] = useState(0);

  useEffect(() => {
    const reduceMotion = window.matchMedia(
      "(prefers-reduced-motion: reduce)",
    ).matches;

    if (reduceMotion) {
      return;
    }

    const interval = window.setInterval(() => {
      setActiveStep((current) => (current + 1) % steps.length);
    }, 3200);

    return () => window.clearInterval(interval);
  }, []);

  return (
    <div className="capture-demo" data-step={activeStep}>
      <div className="demo-chrome" aria-hidden="true">
        <span className="traffic-light red" />
        <span className="traffic-light yellow" />
        <span className="traffic-light green" />
        <span className="demo-title">Product update</span>
      </div>

      <div className="demo-workspace">
        <div className="demo-sidebar" aria-hidden="true">
          <span className="sidebar-dot active" />
          <span className="sidebar-dot" />
          <span className="sidebar-dot" />
          <span className="sidebar-dot" />
        </div>

        <div className="demo-content">
          <div className="demo-kicker">This week</div>
          <div className="demo-heading">A clearer recording flow</div>
          <div className="demo-lines" aria-hidden="true">
            <span />
            <span />
          </div>

          <div className="demo-feature">
            <div className="feature-nav">
              <span className="feature-avatar">G</span>
              <span className="feature-title">Preview panel</span>
              <span className="feature-status">Ready</span>
            </div>
            <div className="feature-canvas">
              <div className="feature-command">⌥⌘G</div>
              <div className="feature-copy">
                <strong>Choose an area</strong>
                <span>Then record only what you want to show.</span>
              </div>
              <div className="feature-button">Record</div>
            </div>
          </div>
        </div>

        <div className="selection-frame" aria-hidden="true">
          <span className="capture-corner top-left" />
          <span className="capture-corner top-right" />
          <span className="capture-corner bottom-right" />
          <span className="capture-corner bottom-left" />
          <span className="selection-size">688 × 388</span>
        </div>

        <div className="record-controller" aria-hidden="true">
          <span className="record-state">
            <span className="record-dot" />
            <span className="stop-mark" />
          </span>
          <span className="record-time">
            {activeStep === 0 ? "Ready" : activeStep === 1 ? "00:06" : "Done"}
          </span>
          <span className="controller-rule" />
          <span className="finish-label">
            {activeStep === 2 ? "Copied" : "Finish"}
          </span>
        </div>

        <div className="paste-result" aria-hidden="true">
          <span className="paste-check">✓</span>
          <span>
            <strong>GIF ready to paste</strong>
            <small>Saved locally · 688 × 388</small>
          </span>
          <kbd>⌘V</kbd>
        </div>
      </div>

      <div className="demo-controls" aria-label="GifJot workflow demonstration">
        {steps.map((step, index) => (
          <button
            type="button"
            className="demo-step"
            aria-pressed={activeStep === index}
            key={step.label}
            onClick={() => setActiveStep(index)}
          >
            <span className="step-index">{index + 1}</span>
            <span>
              <strong>{step.label}</strong>
              <small>{step.detail}</small>
            </span>
          </button>
        ))}
      </div>
    </div>
  );
}
