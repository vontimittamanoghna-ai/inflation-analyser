import { useState } from 'react';
import { savePreferences } from './preferences';

export default function Profile({ preferences, locations, onSave }) {
  const [name, setName] = useState(preferences.name);
  const [location, setLocation] = useState(preferences.location || locations[0] || '');
  const [message, setMessage] = useState('');
  function submit(event) {
    event.preventDefault();
    const next = { name: name.trim(), location };
    const saved = savePreferences(next);
    onSave(next);
    setMessage(saved ? 'Preferences saved on this device.' : 'Applied for this session only. Browser storage is unavailable.');
  }
  return <section className="feature-panel">
    <h2>Profile & Preferences</h2>
    <p>Local preferences only. No login or Oracle user account is created, and preferences do not sync between devices. Do not enter passwords here.</p>
    <form className="feature-form" onSubmit={submit}>
      <label>Display name (optional)<input value={name} maxLength={60} onChange={e => setName(e.target.value)} autoComplete="off" /></label>
      <label>Preferred location<select value={location} onChange={e => setLocation(e.target.value)} disabled={!locations.length}>
        {!locations.length && <option value="">No locations available</option>}
        {locations.map(city => <option key={city}>{city}</option>)}
      </select></label>
      <button type="submit">Save preferences</button>
      <button type="button" onClick={() => { const next = { name: '', location: '' }; const saved = savePreferences(next); setName(''); setLocation(locations[0] || ''); onSave(next); setMessage(saved ? 'Local preferences cleared.' : 'Cleared for this session; browser storage is unavailable.'); }}>Clear preferences</button>
    </form>
    {message && <p role="status">{message}</p>}
    <div className="summary-card"><h3>About this project</h3><p>Inflation Impact Analyser · Oracle XE demonstration</p><p>All supplied prices are synthetic demonstration observations. Category and product price changes are not official weighted CPI.</p></div>
  </section>;
}
