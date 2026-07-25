/*
THESIS: GifJot is understood by watching one clean capture loop, not by reading a grid of features.
OWN-WORLD: Bright optical surfaces, camera-black structure, Canvas Indigo state, and functional capture notation.
STORY: See the mechanism, trust the local-only architecture, then download the notarized Mac app.
FIRST VIEWPORT: A direct promise and CTA face a dominant interactive capture instrument with visible select, record, and paste states.
FORM: The fourth grounded surface structure—an interactive selection lab—assigned by seed f4968f62 and staged as a full working field.
*/

import Image from "next/image";
import appIcon from "@/assets/GifJot-Icon.png";
import { CaptureDemo } from "@/components/CaptureDemo";
import { DownloadLink } from "@/components/DownloadLink";
import { FeedbackLink } from "@/components/FeedbackLink";
import { MotionSystem } from "@/components/MotionSystem";

const workflow = [
  {
    title: "Choose the part",
    copy: "Press ⌥⌘G, then drag around exactly what you want to show.",
  },
  {
    title: "Record the moment",
    copy: "Capture a few clear seconds. Stop from the controls or use the shortcut again.",
  },
  {
    title: "Paste it into the work",
    copy: "GifJot saves the file locally and can copy it straight to your clipboard.",
  },
];

const useCases = [
  {
    label: "Bug report",
    title: "Show the exact click that triggers the bug.",
    file: "dropdown-closes.gif",
    scene: "dropdown",
  },
  {
    label: "Product update",
    title: "Demo the new flow in a few seconds.",
    file: "new-filter-flow.gif",
    scene: "filter",
  },
  {
    label: "Support reply",
    title: "Show exactly which setting to change.",
    file: "change-setting.gif",
    scene: "settings",
  },
] as const;

type UseCaseScene = (typeof useCases)[number]["scene"];

function UseCasePreview({ scene }: { scene: UseCaseScene }) {
  if (scene === "dropdown") {
    return (
      <div className="storyboard storyboard-dropdown">
        <div className="story-step story-action">
          <span className="story-label">Action</span>
          <div className="story-control story-select">
            <span>Priority</span>
            <strong>
              High <span aria-hidden="true">⌄</span>
            </strong>
          </div>
          <span className="mini-cursor" aria-hidden="true">
            ↖
          </span>
        </div>
        <div className="story-connector" aria-hidden="true">
          ↓
        </div>
        <div className="story-step story-outcome">
          <span className="story-label">What the GIF shows</span>
          <div className="story-result story-result-problem">
            <i aria-hidden="true">!</i>
            <strong>The choice disappears instead of saving.</strong>
          </div>
        </div>
      </div>
    );
  }

  if (scene === "filter") {
    return (
      <div className="storyboard storyboard-filter">
        <div className="story-step story-action">
          <span className="story-label">Action</span>
          <div className="story-filters">
            <span>All</span>
            <span className="is-active">Open</span>
            <span>Closed</span>
          </div>
          <span className="mini-cursor" aria-hidden="true">
            ↖
          </span>
        </div>
        <div className="story-connector" aria-hidden="true">
          ↓
        </div>
        <div className="story-step story-outcome">
          <span className="story-label">What the GIF shows</span>
          <div className="story-filter-result">
            <strong>Only open requests remain.</strong>
            <div className="story-filter-items">
              <span>
                <i />
                Keyboard shortcuts
              </span>
              <span>
                <i />
                Export location
              </span>
            </div>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="storyboard storyboard-settings">
      <div className="story-step story-action">
        <span className="story-label">Action</span>
        <div className="story-setting">
          <span>Copy after recording</span>
          <i className="story-toggle">
            <b />
          </i>
        </div>
        <span className="mini-cursor" aria-hidden="true">
          ↖
        </span>
      </div>
      <div className="story-connector" aria-hidden="true">
        ↓
      </div>
      <div className="story-step story-outcome">
        <span className="story-label">What the GIF shows</span>
        <div className="story-result story-result-success">
          <i aria-hidden="true">✓</i>
          <strong>Finished GIFs copy automatically.</strong>
        </div>
      </div>
    </div>
  );
}

const faqs = [
  {
    question: "Is GifJot free?",
    answer:
      "Yes. GifJot 0.1.0 is free proprietary software for personal or commercial use under the GifJot Freeware License.",
  },
  {
    question: "What does it require?",
    answer:
      "A Mac running macOS 14 Sonoma or later. GifJot supports Apple silicon and Intel Macs and needs Screen Recording permission.",
  },
  {
    question: "Does GifJot upload my screen?",
    answer:
      "No. Recording and GIF creation happen locally. The app has no accounts, uploads, analytics, advertising, telemetry, or crash-reporting services.",
  },
  {
    question: "Where are my GIFs saved?",
    answer:
      "In ~/GifJot by default, or in the local folder you choose in Settings. Completed files stay there until you move or delete them.",
  },
];

export default function Home() {
  return (
    <main>
      <MotionSystem />

      <header className="site-header">
        <a className="brand" href="#top" aria-label="GifJot home">
          <Image
            src={appIcon}
            alt=""
            width={42}
            height={42}
            priority
          />
          <span>GifJot</span>
        </a>

        <nav aria-label="Main navigation">
          <a href="#how-it-works">How it works</a>
          <a href="#privacy">Privacy</a>
          <a href="#questions">FAQ</a>
          <FeedbackLink className="nav-feedback" location="nav">
            Feedback
          </FeedbackLink>
        </nav>

        <DownloadLink className="button button-small" location="nav">
          Download
        </DownloadLink>
      </header>

      <section className="hero" id="top">
        <div className="hero-copy">
          <p className="hero-note">
            <span className="live-indicator" />
            Free native app for macOS
          </p>
          <h1>Show it. Don’t explain it.</h1>
          <p className="hero-lede">
            Turn any part of your Mac screen into a paste-ready GIF. No
            account. No upload. No watermark.
          </p>
          <div className="hero-actions">
            <DownloadLink className="button button-primary" location="hero">
              <span className="download-arrow" aria-hidden="true">
                ↓
              </span>
              Download free for macOS
            </DownloadLink>
            <a className="text-link" href="#how-it-works">
              See the 3-step flow
              <span aria-hidden="true"> ↓</span>
            </a>
          </div>
          <p className="compatibility">
            macOS 14+ · Apple silicon & Intel · Version 0.1.0
          </p>
        </div>

        <div className="hero-demo-stage">
          <CaptureDemo />
        </div>
      </section>

      <section className="trust-strip" aria-label="Product commitments">
        <div>
          <span className="trust-mark lock-mark" aria-hidden="true">
            ●
          </span>
          <span>
            <strong>Local only</strong>
            <small>Your recording stays on this Mac.</small>
          </span>
        </div>
        <div>
          <span className="trust-mark" aria-hidden="true">
            ∅
          </span>
          <span>
            <strong>No account</strong>
            <small>Install it and start recording.</small>
          </span>
        </div>
        <div>
          <span className="trust-mark" aria-hidden="true">
            ⌁
          </span>
          <span>
            <strong>No telemetry</strong>
            <small>The Mac app doesn’t track usage.</small>
          </span>
        </div>
        <div>
          <span className="trust-mark" aria-hidden="true">
            ◇
          </span>
          <span>
            <strong>No watermark</strong>
            <small>The GIF is yours to paste.</small>
          </span>
        </div>
      </section>

      <section className="workflow section-shell" id="how-it-works">
        <div className="section-heading">
          <p className="section-label">One clean loop</p>
          <h2>From screen to GIF without breaking your thought.</h2>
          <p>
            GifJot stays in the menu bar until you need it. The whole workflow
            is designed to finish where your explanation belongs.
          </p>
        </div>

        <ol className="workflow-list">
          {workflow.map((step, index) => (
            <li key={step.title}>
              <span className="workflow-index">{index + 1}</span>
              <div>
                <h3>{step.title}</h3>
                <p>{step.copy}</p>
              </div>
            </li>
          ))}
        </ol>
      </section>

      <section className="use-cases">
        <div className="use-case-intro section-shell">
          <p className="section-label">Made for real work</p>
          <h2>When a screenshot is too still and a video is too much.</h2>
          <p>
            Capture a few seconds once. Paste the answer into the issue,
            announcement, or reply.
          </p>
        </div>

        <div className="use-case-stage">
          {useCases.map((useCase) => (
            <article className="use-case" key={useCase.label}>
              <div className="use-case-copy">
                <span>{useCase.label}</span>
                <h3>{useCase.title}</h3>
              </div>
              <div className="example-clip" aria-hidden="true">
                <div className="clip-bar">
                  <span className="clip-play">
                    <i>▶</i>
                    GIF preview
                  </span>
                  <span>0:04</span>
                </div>
                <UseCasePreview scene={useCase.scene} />
                <div className="clip-file">
                  <Image src={appIcon} alt="" width={24} height={24} />
                  <div>
                    <strong>{useCase.file}</strong>
                    <small>Ready to paste</small>
                  </div>
                </div>
              </div>
            </article>
          ))}
        </div>
      </section>

      <section className="privacy section-shell" id="privacy">
        <div className="privacy-visual" aria-hidden="true">
          <div className="privacy-frame">
            <span className="capture-corner top-left" />
            <span className="capture-corner top-right" />
            <span className="capture-corner bottom-right" />
            <span className="capture-corner bottom-left" />
            <Image src={appIcon} alt="" width={104} height={104} />
            <div className="local-path">~/GifJot/your-recording.gif</div>
          </div>
          <div className="blocked-cloud">
            <span>cloud</span>
            <strong>×</strong>
          </div>
        </div>

        <div className="privacy-copy">
          <p className="section-label">Private by architecture</p>
          <h2>Nothing leaves your Mac.</h2>
          <p>
            GifJot processes screen pixels locally and works offline. It
            requests Screen Recording permission—never your microphone, camera,
            contacts, location, or notification access.
          </p>
          <ul>
            <li>Temporary frames are removed after export or cancellation.</li>
            <li>You choose where completed GIFs are stored.</li>
            <li>The app intentionally makes no network requests.</li>
          </ul>
          <div className="privacy-links">
            <a
              href="https://github.com/jamkoo/gifJot/blob/main/PRIVACY.md"
              rel="noreferrer"
            >
              Read the privacy statement
            </a>
            <FeedbackLink location="privacy">
              Ask a privacy question
            </FeedbackLink>
          </div>
        </div>
      </section>

      <section className="control-band">
        <div className="section-shell">
          <p className="section-label">Small app, useful controls</p>
          <div className="control-list">
            <span>Output size</span>
            <span>Frame rate</span>
            <span>Countdown</span>
            <span>Pointer visibility</span>
            <span>Save location</span>
            <span>Global shortcut</span>
          </div>
        </div>
      </section>

      <section className="faq section-shell" id="questions">
        <div className="section-heading faq-heading">
          <p className="section-label">Good to know</p>
          <h2>Before you record.</h2>
        </div>

        <div className="faq-list">
          {faqs.map((faq) => (
            <details key={faq.question}>
              <summary>{faq.question}</summary>
              <p>{faq.answer}</p>
            </details>
          ))}
        </div>
      </section>

      <section className="closing">
        <div className="closing-frame" aria-hidden="true">
          <span className="capture-corner top-left" />
          <span className="capture-corner top-right" />
          <span className="capture-corner bottom-right" />
          <span className="capture-corner bottom-left" />
        </div>
        <Image src={appIcon} alt="" width={88} height={88} />
        <h2>Make the next explanation visible.</h2>
        <p>Free for macOS. Local from the first frame to the finished GIF.</p>
        <DownloadLink className="button button-inverted" location="close">
          Download GifJot
          <span aria-hidden="true"> ↓</span>
        </DownloadLink>
      </section>

      <footer>
        <a className="brand footer-brand" href="#top">
          <Image src={appIcon} alt="" width={34} height={34} />
          <span>GifJot</span>
        </a>
        <p>© 2026 James Koo. Free proprietary software.</p>
        <div className="footer-links">
          <a href="https://github.com/jamkoo/gifJot">GitHub</a>
          <a href="https://github.com/jamkoo/gifJot/blob/main/SUPPORT.md">
            Support
          </a>
          <FeedbackLink location="footer">hi@gifjot.com</FeedbackLink>
        </div>
      </footer>
    </main>
  );
}
