import { LineChart, Line, ResponsiveContainer, XAxis, YAxis, Tooltip, CartesianGrid } from 'recharts';

export default function Trends({ product, onBack }) {
  if (!product) return <section><h2>Price Trends</h2><p>Select a product on Home to view its price history.</p><button onClick={onBack}>Choose a product</button></section>;
  const rows = product.history;
  return <section className="trends-panel">
    <button onClick={onBack}>Back to goods</button>
    <h2>{product.name} price trend</h2>
    <p>{product.location} · INR per {product.unit}</p>
    <p>Synthetic demonstration data · not official CPI</p>
    {!rows.length ? <p>No price history available.</p> : <>
      <p>{rows[0].observed_date} to {rows.at(-1).observed_date}</p>
      <div className="trend-chart" role="img" aria-label={`${product.name} price history in ${product.location}`}>
        <ResponsiveContainer width="100%" height="100%">
          <LineChart data={rows} margin={{ top: 15, right: 15, bottom: 15, left: 0 }}>
            <CartesianGrid stroke="#344859" strokeDasharray="3 3" />
            <XAxis dataKey="observed_date" tick={{ fill: '#aebfcb', fontSize: 10 }} minTickGap={35} />
            <YAxis tick={{ fill: '#aebfcb', fontSize: 11 }} width={50} />
            <Tooltip contentStyle={{ background: '#122534', borderColor: '#344859' }} formatter={value => [`₹${Number(value).toFixed(2)}`, 'Price']} />
            <Line dataKey="price" name="Price" stroke="#08e6b6" strokeWidth={3} dot={{ r: 4 }} isAnimationActive={false} />
          </LineChart>
        </ResponsiveContainer>
      </div>
      <p>Latest {rows.length} available observations.</p>
    </>}
  </section>;
}
