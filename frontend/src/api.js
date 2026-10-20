const base = (import.meta.env?.VITE_API_BASE_URL || 'http://localhost:8000/api').replace(/\/$/, '');
export async function get(path, params = {}, signal) {
  const query = new URLSearchParams(Object.entries(params).filter(([, v]) => v !== '' && v != null));
  const response = await fetch(`${base}${path}?${query}`, { signal });
  if (!response.ok) throw new Error(response.status === 503 ? 'Database unavailable. Check the backend configuration.' : 'Could not load data. Please try again.');
  return response.json();
}
