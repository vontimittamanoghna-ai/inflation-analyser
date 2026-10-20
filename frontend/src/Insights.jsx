import { useEffect, useState } from 'react';
import { get } from './api';

export default function Insights({ location, onSelect }) {
  const [retry, setRetry] = useState(0);
  const [result, setResult] = useState({ key: '', rows: [], error: '' });
  const key = JSON.stringify([location, retry]);
  useEffect(() => {
    if (!location) return;
    const controller = new AbortController();
    get('/prices/latest', { location, limit: 100 }, controller.signal)
      .then(rows => setResult({ key, rows, error: '' }))
      .catch(e => { if (e.name !== 'AbortError') setResult({ key, rows: [], error: e.message }); });
    return () => controller.abort();
  }, [location, key]);
  const comparable = result.rows.filter(p => p.change_pct != null);
  const ranked = [...comparable].sort((a, b) => b.change_pct - a.change_pct);
  const groups = Object.values(comparable.reduce((all, p) => {
    const k = JSON.stringify([p.category_id, p.comparison_date, p.observed_date]);
    all[k] ??= { name: p.category_name, from: p.comparison_date, to: p.observed_date, sum: 0, count: 0 };
    all[k].sum += p.change_pct; all[k].count += 1;
    return all;
  }, {}));
  return <section className="feature-panel">
    <h2>Price Insights</h2>
    <p>{location || 'Choose a location on Home'} · synthetic demonstration data</p>
    <p>Exact three-month comparisons from Oracle. These are product price changes, not official CPI.</p>
    {!location ? <p>No observed locations available.</p> : result.key !== key ? <p role="status">Loading insights…</p> : result.error ?
      <div role="alert">{result.error} <button onClick={() => setRetry(n => n + 1)}>Retry</button></div> : !result.rows.length ? <p>No observations available for this location.</p> : <>
      <div className="stats-grid">
        <div><strong>{comparable.length}/{result.rows.length}</strong><span>Comparable products</span></div>
        <div><strong>{comparable.filter(p => p.change_pct > 0).length}</strong><span>Prices increased</span></div>
        <div><strong>{comparable.filter(p => p.change_pct < 0).length}</strong><span>Prices decreased</span></div>
      </div>
      {!ranked.length ? <p>Three-month baseline prices are missing. No percentage changes can be calculated.</p> : <>
        <h3>Product changes, highest first</h3>
        <div className="insight-list">{ranked.map(p => <button key={p.product_id} onClick={() => onSelect({ ...p, id: p.product_id, name: p.product_name })}>
          <span>{p.product_name}<small>{p.comparison_date} → {p.observed_date}</small></span>
          <strong className={p.change_pct >= 0 ? 'positive' : 'negative'}>{p.change_pct > 0 ? '+' : ''}{p.change_pct.toFixed(2)}%</strong>
        </button>)}</div>
        <h3>Category comparison</h3>
        <p>Unweighted means of displayed product percentages, grouped by matching dates. Missing baselines excluded; figures may differ from stored full-period summaries.</p>
        {groups.map(g => <div className="summary-card" key={g.name + g.from + g.to}>
          <strong>{g.name}: {(g.sum / g.count).toFixed(2)}%</strong>
          <p>{g.from} → {g.to} · {g.count} comparable products</p>
        </div>)}
      </>}
      <p>Coverage: first {result.rows.length} active product/location series (maximum 100). All categories; Home search/category filters do not restrict Insights.</p>
    </>}
  </section>;
}
