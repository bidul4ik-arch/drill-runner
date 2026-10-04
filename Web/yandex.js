/* Platform adapter. No SDK stub is shipped in the release archive. */
window.DrillDropPlatform = (() => {
  let sdk = null, ready = false, playing = false, reported = false;
  let sdkPaused = false, callback = null;
  let hidden = document.hidden || !document.hasFocus();
  const api = {
    language: navigator.language.startsWith('ru') ? 'ru' : 'en',
    hidden,
    sdkAvailable: false,
    setPauseCallback(fn) { callback = fn; fn(api.hidden); },
    ready() { if (ready) return; ready = true; sdk?.features.LoadingAPI?.ready(); },
    gameplay(value) { playing = !!value; report(); },
    readSave() { try { return localStorage.getItem(saveKey()) || ''; } catch (_) { return ''; } },
    writeSave(value) { try { localStorage.setItem(saveKey(), value); } catch (_) {} },
    async init() {
      const local = ['localhost', '127.0.0.1'].includes(location.hostname);
      try {
        await new Promise((resolve, reject) => {
          const script = document.createElement('script');
          script.src = '/sdk.js'; script.onload = resolve; script.onerror = reject;
          document.head.appendChild(script);
        });
        sdk = await YaGames.init();
        api.sdkAvailable = true;
        api.language = sdk.environment.i18n.lang.startsWith('ru') ? 'ru' : 'en';
        sdk.on('game_api_pause', () => { sdkPaused = true; update(); });
        sdk.on('game_api_resume', () => { sdkPaused = false; update(); });
      } catch (error) {
        if (!local) throw new Error('SDK Яндекс Игр не загрузился. Обновите страницу. / Yandex Games SDK failed to load. Reload the page.');
        console.info('Local preview without Yandex SDK');
      }
    }
  };
  function saveKey() { return 'drilldrop-v1-' + (sdk?.environment.app.id || 'local'); }
  function report() {
    const active = playing && !api.hidden;
    if (active === reported) return;
    reported = active;
    if (active) sdk?.features.GameplayAPI?.start(); else sdk?.features.GameplayAPI?.stop();
  }
  function update() {
    api.hidden = hidden || sdkPaused;
    callback?.(api.hidden);
    report();
  }
  document.addEventListener('visibilitychange', () => { hidden = document.hidden; update(); });
  window.addEventListener('blur', () => { hidden = true; update(); });
  window.addEventListener('focus', () => { hidden = document.hidden; update(); });
  window.addEventListener('pagehide', () => { hidden = true; update(); });
  window.addEventListener('contextmenu', e => e.preventDefault());
  window.addEventListener('dragstart', e => e.preventDefault());
  window.addEventListener('keydown', e => { if (['ArrowUp','ArrowDown','ArrowLeft','ArrowRight',' '].includes(e.key)) e.preventDefault(); });
  return api;
})();
