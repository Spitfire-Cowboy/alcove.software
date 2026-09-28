(() => {
  const key = 'alcove-theme';
  const system = window.matchMedia('(prefers-color-scheme: dark)');
  const valid = value => ['light', 'dark', 'auto'].includes(value) ? value : 'auto';
  let preference = 'auto';
  try { preference = valid(localStorage.getItem(key)); } catch { /* Storage is optional. */ }

  const apply = () => {
    document.documentElement.dataset.theme = preference === 'auto'
      ? (system.matches ? 'dark' : 'light') : preference;
    document.querySelectorAll('.theme-chooser select').forEach(select => {
      select.value = preference;
    });
  };
  // Apply before the body is parsed to avoid flashing the wrong theme.
  apply();
  if (system.addEventListener) system.addEventListener('change', apply);
  else system.addListener(apply);
  window.addEventListener('storage', event => {
    if (event.key === key || event.key === null) {
      preference = valid(event.newValue);
      apply();
    }
  });
  document.addEventListener('DOMContentLoaded', () => {
    document.querySelectorAll('.theme-chooser').forEach(chooser => {
      chooser.hidden = false;
      chooser.querySelector('select').addEventListener('change', event => {
        preference = valid(event.target.value);
        try { localStorage.setItem(key, preference); } catch { /* Keep this page usable. */ }
        apply();
      });
    });
    apply();
  });
})();
