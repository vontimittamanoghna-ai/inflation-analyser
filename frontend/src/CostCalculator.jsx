import { useState } from 'react';
import { projectCost } from './calculations';
const money = value => new Intl.NumberFormat('en-IN', { style: 'currency', currency: 'INR', maximumFractionDigits: 2 }).format(value);

export default function CostCalculator({ product }) {
  const [amount, setAmount] = useState('1000');
  const [quantity, setQuantity] = useState('1');
  const [rate, setRate] = useState('6');
  const [years, setYears] = useState('1');
  const [basis, setBasis] = useState('Manually entered amount');
  const result = projectCost(amount, quantity, rate, years);
  return <section className="feature-panel">
    <h2>Future Cost Calculator</h2>
    <p>Explore an assumed annual rate. This is a scenario, not an Oracle forecast or an official inflation estimate.</p>
    {product && <button onClick={() => { setAmount(String(product.price)); setBasis(`${product.name}, ${product.location}, ${product.observed_date}, per ${product.unit} (synthetic)`); }}>Use {product.name} price: {money(product.price)}</button>}
    <p>{basis}</p>
    <div className="feature-form">
      <label>Current price or cost (INR)<input type="number" min="0.01" max="1000000000" step="any" value={amount} onChange={e => { setAmount(e.target.value); setBasis('Manually entered amount'); }} /></label>
      <label>Quantity<input type="number" min="0.000001" max="1000000" step="any" value={quantity} onChange={e => setQuantity(e.target.value)} /></label>
      <label>Assumed annual change (%)<input type="number" min="-99.99" max="100" step="any" value={rate} onChange={e => setRate(e.target.value)} /></label>
      <label>Years<input type="number" min="1" max="30" step="1" value={years} onChange={e => setYears(e.target.value)} /></label>
    </div>
    {!result ? <p role="alert">Enter a positive cost and quantity, an annual rate greater than -100% and at most 100%, and 1–30 whole years. Maximum cost: ₹1 billion; maximum quantity: 1 million.</p> : <>
      <div className="summary-card" aria-live="polite"><p>Current total: {money(result.current)}</p><h3>Estimated future cost: {money(result.future)}</h3><p>Difference: {money(result.difference)}</p></div>
      <p>Future cost = current cost × quantity × (1 + annual rate / 100)<sup>years</sup>. The default 6% is an editable assumption; a historical three-month change is not an annual rate.</p>
      <table className="feature-table"><caption>Annual scenario</caption><thead><tr><th>Year</th><th>Cost (INR)</th></tr></thead><tbody>{result.schedule.map(row => <tr key={row.year}><td>{row.year}</td><td>{money(row.cost)}</td></tr>)}</tbody></table>
    </>}
  </section>;
}
