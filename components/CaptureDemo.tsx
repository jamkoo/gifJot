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

function ChevronDownIcon() {
  return (
    <svg aria-hidden="true" viewBox="0 0 12 12">
      <path d="m3 4.75 3 3 3-3" />
    </svg>
  );
}

function CursorIcon({ clicks = false }: { clicks?: boolean }) {
  return (
    <svg aria-hidden="true" viewBox="0 0 18 18">
      {clicks && (
        <>
          <path d="M11.4 2.5a5.2 5.2 0 0 1 4.1 4.1" />
          <path d="M12.1 5.3a2.3 2.3 0 0 1 1.6 1.6" />
        </>
      )}
      <path d="m3.1 2.2 8.5 8.1-4.1.3-2.3 3.5Z" />
      <path d="m8.4 9.9 2.6 4" />
    </svg>
  );
}

function PinIcon() {
  return (
    <svg aria-hidden="true" viewBox="0 0 18 18">
      <path d="m6.1 2.8 5.8 1.6-1.7 2.1.6 3.1-3.2-.9-2.5 1.2Z" />
      <path d="m7.8 8.8-2 6.4" />
    </svg>
  );
}

function CloseIcon() {
  return (
    <svg aria-hidden="true" viewBox="0 0 16 16">
      <path d="m4.5 4.5 7 7m0-7-7 7" />
    </svg>
  );
}

function MoveIcon() {
  return (
    <svg aria-hidden="true" viewBox="0 0 18 18">
      <path d="M9 2.3v13.4M2.3 9h13.4" />
      <path d="M6.8 4.5 9 2.3l2.2 2.2M6.8 13.5 9 15.7l2.2-2.2M4.5 6.8 2.3 9l2.2 2.2M13.5 6.8 15.7 9l-2.2 2.2" />
    </svg>
  );
}

function CheckIcon() {
  return (
    <svg aria-hidden="true" viewBox="0 0 18 18">
      <circle cx="9" cy="9" r="7" />
      <path d="m5.8 9.1 2 2 4.4-4.4" />
    </svg>
  );
}

function DragDots() {
  return (
    <span className="hud-dots" aria-hidden="true">
      {Array.from({ length: 6 }, (_, index) => (
        <i key={index} />
      ))}
    </span>
  );
}

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
          <span className="frame-handle frame-corner frame-north-west" />
          <span className="frame-handle frame-rail frame-north" />
          <span className="frame-handle frame-corner frame-north-east" />
          <span className="frame-handle frame-rail frame-east" />
          <span className="frame-handle frame-corner frame-south-east" />
          <span className="frame-handle frame-rail frame-south" />
          <span className="frame-handle frame-corner frame-south-west" />
          <span className="frame-handle frame-rail frame-west" />
          <span className="frame-move-grip">
            <MoveIcon />
          </span>
          <span className="selection-size">
            <i />
            688 × 388 px
          </span>
        </div>

        <div className="hud-shell hud-ready" aria-hidden="true">
          <span className="hud-options">
            <span className="hud-size-segment">
              688 × 388 px
              <ChevronDownIcon />
            </span>
            <i className="hud-divider" />
            <span className="hud-option is-selected">
              <CursorIcon />
            </span>
            <i className="hud-divider" />
            <span className="hud-option hud-clicks">
              <CursorIcon clicks />
            </span>
            <i className="hud-divider hud-clicks" />
            <span className="hud-countdown">Off</span>
            <i className="hud-divider hud-pin-divider" />
            <span className="hud-option hud-pin">
              <PinIcon />
            </span>
          </span>

          <span className="hud-drag-surface">
            <DragDots />
          </span>

          <span className="hud-actions">
            <span className="hud-icon-button">
              <CloseIcon />
            </span>
            <span className="hud-record-button">
              <i />
              Record
            </span>
          </span>
        </div>

        <div className="hud-shell hud-recording" aria-hidden="true">
          <span className="hud-status-symbol hud-live-dot" />
          <span className="hud-status-copy">
            <strong>Recording</strong>
            <small>00:06</small>
          </span>
          <span className="hud-status-spacer" />
          <span className="hud-stop-button">
            <i />
            Stop
          </span>
          <span className="hud-icon-button">
            <CloseIcon />
          </span>
        </div>

        <div className="hud-shell hud-complete" aria-hidden="true">
          <span className="hud-status-symbol hud-check">
            <CheckIcon />
          </span>
          <span className="hud-status-copy hud-complete-copy">
            <strong>Copied. Press ⌘V to paste</strong>
          </span>
          <span className="hud-status-spacer" />
          <span className="hud-quiet-button">Reveal</span>
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
