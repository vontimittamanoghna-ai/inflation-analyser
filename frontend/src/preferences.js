const KEY = 'inflation-analyser-preferences';
export function readPreferences() {
  try {
    const data = JSON.parse(localStorage.getItem(KEY));
    return { name: typeof data?.name === 'string' ? data.name.slice(0, 60) : '', location: typeof data?.location === 'string' ? data.location : '' };
  } catch { return { name: '', location: '' }; }
}
export function savePreferences(preferences) {
  try { localStorage.setItem(KEY, JSON.stringify(preferences)); return true; }
  catch { return false; }
}
