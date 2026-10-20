
import { useEffect, useState } from "react";
import {
  MapPin, Search, Home, ChartNoAxesColumnIncreasing,
  Lightbulb, Calculator, UserRound, ChevronRight
} from "lucide-react";
import {
  LineChart, Line, ResponsiveContainer, XAxis, Tooltip
} from "recharts";
import "./App.css";

import { get } from "./api";
const emoji = { Rice: "🍚", Milk: "🥛", Tomato: "🍅", Petrol: "⛽", "Cooking Oil": "🛢️", Electricity: "💡" };

const navigation = [
  { name: "Home", icon: Home },
  { name: "Trends", icon: ChartNoAxesColumnIncreasing },
  { name: "Insights", icon: Lightbulb },
  { name: "Calculator", icon: Calculator },
  { name: "Profile", icon: UserRound }
];

function App() {
  const [category, setCategory] = useState("All Goods");
  const [search, setSearch] = useState("");
  const [location, setLocation] = useState("Bengaluru");
  const [page, setPage] = useState("Home");
  const [selectedProduct, setSelectedProduct] = useState(null);

  const [categories, setCategories] = useState(["All Goods"]);
  const [locations, setLocations] = useState([]);
  const [categoryIds, setCategoryIds] = useState({});
  const [result, setResult] = useState({ key: '', products: [], error: '' });
  const [metadataError, setMetadataError] = useState('');
  const [retry, setRetry] = useState(0);
  const key = JSON.stringify([category, search, location, retry]);
  useEffect(() => {
    const controller = new AbortController();
    Promise.all([get('/categories', {}, controller.signal), get('/locations', {}, controller.signal)])
      .then(([cats, cities]) => {
        setCategories(['All Goods', ...cats.map(c => c.category_name)]);
        setCategoryIds(Object.fromEntries(cats.map(c => [c.category_name, c.category_id])));
        setLocations(cities.map(c => c.location));
        setLocation(old => cities.some(c => c.location === old) ? old : (cities[0]?.location || ''));
        setMetadataError('');
      }).catch(e => { if (e.name !== 'AbortError') setMetadataError(e.message); });
    return () => controller.abort();
  }, [retry]);
  useEffect(() => {
    const controller = new AbortController();
    const timer = setTimeout(() => {
      if (!location) { setResult({ key, error: '', products: [] }); return; }
      get('/prices/latest', { location, search, category_id: categoryIds[category] }, controller.signal)
        .then(rows => setResult({ key, error: '', products: rows.map(p => ({
          ...p, id: p.product_id, name: p.product_name, category: p.category_name,
          change: p.change_pct, emoji: emoji[p.product_name] || '📦'
        })).filter(p => category === 'All Goods' || p.category === category) }))
        .catch(e => { if (e.name !== 'AbortError') setResult({ key, products: [], error: e.message }); });
    }, 200);
    return () => { clearTimeout(timer); controller.abort(); };
  }, [category, search, location, key, categoryIds]);
  const loading = result.key !== key;
  const filteredProducts = loading ? [] : result.products;
  const error = metadataError || (!loading && result.error);

  function selectProduct(product) {
    setSelectedProduct(product);
    setPage("Trends");
  }

  return (
    <div className="app">
      <header className="app-header">
        <h1>▥ Inflation Impact Analyser</h1>
        <p>Track prices. Understand changes. Plan better.</p>
      </header>

      <main className="app-content">
        {page === "Home" ? (
          <>
            <div className="location-box">
              <MapPin size={18} />
              <select
                value={location}
                onChange={(e) => setLocation(e.target.value)}
                aria-label="Select location"
              >
                {locations.map(city => <option key={city}>{city}</option>)}
              </select>
            </div>

            <div className="categories">
              {categories.map((item) => (
                <button
                  key={item}
                  className={category === item ? "selected" : ""}
                  onClick={() => setCategory(item)}
                >
                  {item}
                </button>
              ))}
            </div>

            <div className="search-box">
              <Search size={20} />
              <input
                type="text"
                placeholder="Search for a good..."
                value={search}
                onChange={(e) => setSearch(e.target.value)}
              />
            </div>

            <div className="section-heading">
              <h2>Goods Overview</h2>
              <span>Synthetic demo data</span>
            </div>

            <p>Synthetic observations in INR; not official CPI. Charts show available dates.</p>
            {loading && <p role="status">Loading prices…</p>}
            {error && <div role="alert">{error} <button onClick={() => setRetry(r => r + 1)}>Retry</button></div>}
            <div className="product-list">
              {filteredProducts.map((product) => (
                <button
                  key={product.id}
                  className="product-card"
                  onClick={() => selectProduct(product)}
                >
                  <div className="product-image">{product.emoji}</div>

                  <div className="product-info">
                    <h3>{product.name} <small>({product.unit})</small></h3>
                    <strong>₹{product.price.toFixed(2)}</strong>
                    <p className={product.change >= 0 ? "positive" : "negative"}>
                      {product.change == null ? 'Three-month comparison unavailable' : `${product.change > 0 ? '+' : ''}${product.change}% vs ${product.comparison_date}`}
                      <br />As of {product.observed_date}
                    </p>
                  </div>

                  <div className="mini-chart">
                    <ResponsiveContainer width="100%" height={45}>
                      <LineChart
                        data={product.history}
                      >
                        <XAxis dataKey="observed_date" hide />
                        <Tooltip />
                        <Line
                          type="monotone"
                          dataKey="price"
                          stroke={product.change >= 0 ? "#08e6b6" : "#ff5c70"}
                          strokeWidth={2.5}
                          dot={false}
                        />
                      </LineChart>
                    </ResponsiveContainer>
                  </div>
                  <ChevronRight size={18} />
                </button>
              ))}
              {!loading && !error && filteredProducts.length === 0 && (
                <p>No matching goods found.</p>
              )}
            </div>
          </>
        ) : (
          <div className="placeholder">
            <h2>{page}</h2>
            <p>
              {page === "Trends"
                ? `${selectedProduct?.name || "Select a product"}: view the dated chart on Home.`
                : `${page} screen will be implemented next.`}
            </p>
          </div>
        )}
      </main>

      <nav className="bottom-nav">
        {navigation.map(({ name, icon: Icon }) => (
          <button
            key={name}
            className={page === name ? "active" : ""}
            onClick={() => setPage(name)}
          >
            <Icon size={21} />
            <span>{name}</span>
          </button>
        ))}
      </nav>
    </div>
  );
}

export default App;
