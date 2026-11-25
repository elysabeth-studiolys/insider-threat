import { LINKS } from './links.js';

const DOWNLOADS = [
  {
    key: 'web',
    kicker: 'Play now',
    label: 'Try it in Chrome',
    hint: 'No install. Runs in the browser.',
    icon: <GlobeIcon />,
    primary: true,
  },
  {
    key: 'apk',
    kicker: 'Android',
    label: 'Download the APK',
    hint: 'Allow installs from unknown sources.',
    icon: <AndroidIcon />,
  },
  {
    key: 'appStore',
    kicker: 'iPhone',
    label: 'App Store',
    hint: 'iPhone and iPad.',
    icon: <AppleIcon />,
  },
];

const STEPS = [
  {
    n: '01',
    title: 'Deal the cards',
    text: 'Type the players in table order, then scan each role card QR code or deal at random.',
  },
  {
    n: '02',
    title: 'Run the night',
    text: 'The app calls each role in order and shows you, word for word, what to read out loud.',
  },
  {
    n: '03',
    title: 'Lead the day',
    text: 'Morning report, CISO election, debate timer and vote. Win conditions are checked for you.',
  },
];

const FEATURES = [
  ['Scripted narration', 'Every line to read, step by step, with Narrator tips you can turn off.'],
  ['Events & quiz', 'Expert mode draws an Event each day, with a 10 s cyber quiz for the table.'],
  ['Timers built in', '3 min debate, 1 min CISO election, short timers for special actions.'],
  ['Sound design', 'Night and day ambience, alerts and glitches to set the mood.'],
];

const ROLES = [
  { img: '/characters/red_team_card.jpg', name: 'Red Team', team: 'red', full: true },
  { img: '/characters/soc_analyst.png', name: 'SOC Analyst', team: 'blue' },
  { img: '/characters/incident_responder.png', name: 'Incident Responder', team: 'blue' },
];

export default function App() {
  return (
    <>
      <header className="topbar">
        <a href="#top" className="topbar__brand" aria-label="Insider Threat, home">
          <img src="/brand/favicon.svg" alt="" width="28" height="28" />
          <span>Insider Threat</span>
        </a>
        <nav className="topbar__nav">
          <a href="#download" className="chip chip--link">Get the app</a>
          {LINKS.web && (
            <a href={LINKS.web} className="btn btn--primary btn--sm" target="_blank" rel="noopener noreferrer">
              <span className="btn__icon"><PlayIcon /></span>
              Play on web
            </a>
          )}
        </nav>
      </header>

      <main id="top">
        <section className="hero">
          <div className="hero__bg" aria-hidden="true" />
          <div className="hero__inner">
            <span className="chip">Narrator companion</span>
            <h1 className="hero__logo">
              <img src="/brand/logo_typo.svg" alt="Insider Threat" />
            </h1>
            <p className="hero__lead">
              A social deduction game on a compromised network. Attackers hide among the employees
              of CORP-LAN. Find them before the network falls.
            </p>
            <p className="meta">5-14 players + 1 Narrator · 15-40 min</p>
            <div className="hero__cta">
              <a href="#download" className="btn btn--primary">Download</a>
              <a href="#how" className="btn btn--ghost">How it works</a>
            </div>
          </div>
          <div className="hero__scroll" aria-hidden="true">
            <span>scroll</span>
          </div>
        </section>

        <section id="how" className="section">
          <SectionHead tag="// how it works" title="The app runs the game. You run the table." />
          <ol className="steps">
            {STEPS.map((s) => (
              <li key={s.n} className="card step">
                <span className="step__n">{s.n}</span>
                <h3>{s.title}</h3>
                <p>{s.text}</p>
              </li>
            ))}
          </ol>
        </section>

        <section className="section section--split">
          <div>
            <SectionHead tag="// roles" title="Defenders vs Red Team" />
            <p className="section__text">
              Defenders protect the network each night. The Red Team compromises one player at a
              time. By day, everyone debates and votes to isolate a suspect.
            </p>
            <ul className="features">
              {FEATURES.map(([t, d]) => (
                <li key={t}>
                  <strong>{t}</strong>
                  <span>{d}</span>
                </li>
              ))}
            </ul>
          </div>
          <div className="roles">
            {ROLES.map((r) => (
              <figure key={r.name} className={`role role--${r.team}${r.full ? ' role--full' : ''}`}>
                <img src={r.img} alt="" loading="lazy" />
                <figcaption>{r.name}</figcaption>
              </figure>
            ))}
          </div>
        </section>

        <section id="download" className="section">
          <SectionHead tag="// get the app" title="Pick your platform" />
          <div className="downloads">
            {DOWNLOADS.map(({ key, ...d }) => (
              <DownloadCard key={key} {...d} href={LINKS[key]} />
            ))}
          </div>
          <p className="downloads__note">
            You still need the physical cards to play: the app is the Narrator's companion.
          </p>
        </section>
      </main>

      <footer className="footer">
        <img src="/brand/favicon.svg" alt="" width="24" height="24" />
        <span>Insider Threat · {new Date().getFullYear()}</span>
      </footer>
    </>
  );
}

function SectionHead({ tag, title }) {
  return (
    <div className="section__head">
      <span className="tag">{tag}</span>
      <h2>{title}</h2>
    </div>
  );
}

function DownloadCard({ href, kicker, label, hint, icon, primary }) {
  const ready = Boolean(href);
  const className = `card download${primary ? ' download--primary' : ''}${ready ? '' : ' is-disabled'}`;
  const body = (
    <>
      <span className="download__icon">{icon}</span>
      <span className="download__kicker">{kicker}</span>
      <span className="download__label">{label}</span>
      <span className="download__hint">{ready ? hint : 'Coming soon'}</span>
    </>
  );
  // A file (the APK) downloads in place; a page (web build, store) opens in a new tab.
  const isFile = ready && /\.apk$/i.test(href);
  const linkProps = isFile ? { download: '' } : { target: '_blank', rel: 'noopener noreferrer' };
  return ready ? (
    <a className={className} href={href} {...linkProps}>
      {body}
    </a>
  ) : (
    <div className={className} aria-disabled="true">
      {body}
    </div>
  );
}

function PlayIcon() {
  return (
    <svg viewBox="0 0 24 24" fill="currentColor" aria-hidden="true">
      <path d="M8 5.5v13a1 1 0 0 0 1.52.85l10.4-6.5a1 1 0 0 0 0-1.7L9.52 4.65A1 1 0 0 0 8 5.5Z" />
    </svg>
  );
}

function GlobeIcon() {
  return (
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" aria-hidden="true">
      <circle cx="12" cy="12" r="9" />
      <path d="M3 12h18M12 3c2.5 2.7 3.8 5.7 3.8 9s-1.3 6.3-3.8 9c-2.5-2.7-3.8-5.7-3.8-9S9.5 5.7 12 3Z" />
    </svg>
  );
}

function AndroidIcon() {
  return (
    <svg viewBox="0 0 24 24" fill="currentColor" aria-hidden="true">
      <path d="M17.6 9.48 19.44 6.3a.5.5 0 0 0-.87-.5l-1.87 3.23A11.4 11.4 0 0 0 12 8.08c-1.7 0-3.3.35-4.7.95L5.43 5.8a.5.5 0 0 0-.87.5L6.4 9.48A10.8 10.8 0 0 0 1 18h22a10.8 10.8 0 0 0-5.4-8.52ZM7 15.25a1.25 1.25 0 1 1 0-2.5 1.25 1.25 0 0 1 0 2.5Zm10 0a1.25 1.25 0 1 1 0-2.5 1.25 1.25 0 0 1 0 2.5Z" />
    </svg>
  );
}

function AppleIcon() {
  return (
    <svg viewBox="0 0 24 24" fill="currentColor" aria-hidden="true">
      <path d="M16.37 12.6c-.02-2.3 1.88-3.4 1.96-3.46-1.07-1.56-2.73-1.78-3.32-1.8-1.41-.14-2.76.83-3.47.83-.72 0-1.82-.81-3-.79a4.43 4.43 0 0 0-3.74 2.27c-1.6 2.77-.41 6.87 1.15 9.12.76 1.1 1.67 2.33 2.86 2.29 1.15-.05 1.58-.74 2.97-.74 1.38 0 1.77.74 2.98.72 1.23-.02 2.01-1.12 2.76-2.22.87-1.28 1.23-2.51 1.25-2.58-.03-.01-2.39-.92-2.4-3.64ZM14.1 5.86c.63-.77 1.06-1.83.94-2.89-.91.04-2.01.6-2.66 1.37-.58.67-1.1 1.76-.96 2.8 1.01.08 2.05-.52 2.68-1.28Z" />
    </svg>
  );
}
