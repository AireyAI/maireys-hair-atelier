/**
 * Maireys Hair Market cookie consent + optional GA4 loader.
 * Replace GA_MEASUREMENT_ID before launch if analytics is required.
 */
(function () {
  'use strict';

  const GA_MEASUREMENT_ID = 'G-XXXXXXXXXX';
  const STORAGE_KEY = 'maireys_consent_v1';

  function getConsent() { try { return localStorage.getItem(STORAGE_KEY); } catch { return null; } }
  function setConsent(value) { try { localStorage.setItem(STORAGE_KEY, value); } catch {} }
  function clearConsent() { try { localStorage.removeItem(STORAGE_KEY); } catch {} }

  const dnt = navigator.doNotTrack === '1' || window.doNotTrack === '1' || navigator.msDoNotTrack === '1';

  function loadGA() {
    if (!GA_MEASUREMENT_ID || GA_MEASUREMENT_ID.includes('XXXXXXXXXX')) return;
    if (window.__MAIREYS_GA_LOADED__) return;
    window.__MAIREYS_GA_LOADED__ = true;

    const script = document.createElement('script');
    script.async = true;
    script.src = 'https://www.googletagmanager.com/gtag/js?id=' + GA_MEASUREMENT_ID;
    document.head.appendChild(script);

    window.dataLayer = window.dataLayer || [];
    function gtag() { window.dataLayer.push(arguments); }
    window.gtag = gtag;
    gtag('js', new Date());
    gtag('config', GA_MEASUREMENT_ID, { anonymize_ip: true });
  }

  const style = document.createElement('style');
  style.textContent = `
    .maireys-consent {
      position: fixed;
      left: 18px;
      right: 18px;
      bottom: 18px;
      z-index: 9995;
      max-width: 720px;
      margin: 0 auto;
      display: flex;
      flex-wrap: wrap;
      align-items: center;
      gap: 14px;
      padding: 18px 20px;
      border: 1px solid rgba(245, 214, 168, 0.2);
      border-radius: 22px;
      background: rgba(18, 16, 14, 0.94);
      color: #fff8ed;
      box-shadow: 0 30px 90px rgba(0, 0, 0, 0.55);
      font-family: "Avenir Next", "Segoe UI", system-ui, sans-serif;
      font-size: 13.5px;
      line-height: 1.55;
      backdrop-filter: blur(18px);
      transform: translateY(160%);
      opacity: 0;
      transition: transform 360ms cubic-bezier(.2,.8,.2,1), opacity 260ms ease;
    }
    .maireys-consent.show { transform: translateY(0); opacity: 1; }
    .maireys-consent-text { flex: 1 1 290px; color: rgba(255, 248, 237, 0.78); }
    .maireys-consent-text strong { color: #fff8ed; }
    .maireys-consent-text a { color: #f5d6a8; text-decoration: underline; text-underline-offset: 3px; }
    .maireys-consent-actions { display: flex; gap: 8px; flex-wrap: wrap; }
    .maireys-consent button {
      min-height: 44px;
      padding: 10px 16px;
      border-radius: 999px;
      border: 1px solid rgba(245, 214, 168, 0.24);
      cursor: pointer;
      font: inherit;
      font-weight: 800;
      color: #fff8ed;
      background: transparent;
      transition: transform 160ms ease, background-color 160ms ease, border-color 160ms ease;
    }
    .maireys-consent button:hover { transform: translateY(-1px); border-color: #f5d6a8; }
    .maireys-consent .accept { background: #f5d6a8; color: #1a110d; border-color: #f5d6a8; }
    @media (max-width: 520px) {
      .maireys-consent { left: 10px; right: 10px; bottom: 10px; }
      .maireys-consent-actions, .maireys-consent button { width: 100%; }
    }
  `;
  document.head.appendChild(style);

  function hide(el) {
    el.classList.remove('show');
    setTimeout(() => el.remove(), 420);
  }

  function buildBanner() {
    const el = document.createElement('div');
    el.className = 'maireys-consent';
    el.setAttribute('role', 'dialog');
    el.setAttribute('aria-label', 'Cookie preferences');
    el.innerHTML = `
      <div class="maireys-consent-text">
        <strong>Cookies.</strong> Maireys Hair Market uses optional analytics to understand visits and improve the website.
        No ad tracking is loaded without consent. <a href="privacy.html">Read privacy policy</a>.
      </div>
      <div class="maireys-consent-actions">
        <button type="button" class="decline">Decline</button>
        <button type="button" class="accept">Accept</button>
      </div>
    `;
    document.body.appendChild(el);

    el.querySelector('.accept').addEventListener('click', () => {
      setConsent('granted');
      loadGA();
      hide(el);
    });
    el.querySelector('.decline').addEventListener('click', () => {
      setConsent('denied');
      hide(el);
    });
    requestAnimationFrame(() => requestAnimationFrame(() => el.classList.add('show')));
    return el;
  }

  function init() {
    const existing = getConsent();
    if (dnt) { setConsent('denied'); return; }
    if (existing === 'granted') { loadGA(); return; }
    if (existing === 'denied') return;
    buildBanner();
  }

  window.YBNShowConsent = function () {
    document.querySelectorAll('.maireys-consent').forEach((node) => node.remove());
    clearConsent();
    buildBanner();
  };

  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', init);
  else init();
})();
