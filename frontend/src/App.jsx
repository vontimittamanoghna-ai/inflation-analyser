
import { useState } from "react";
import {
  MapPin, Search, Home, ChartNoAxesColumnIncreasing,
  Lightbulb, Calculator, UserRound, ChevronRight
} from "lucide-react";
import {
  LineChart, Line, ResponsiveContainer
} from "recharts";
import "./App.css";

const products = [
  {
    id: 1, name: "Rice", unit: "1 kg", category: "Food",
    price: 54, change: 12.5, emoji: "🍚",
    history: [42, 45, 44, 47, 50, 49, 52, 53, 54]
  },
  {
    id: 2, name: "Milk", unit: "1 litre", category: "Food",
    price: 62, change: 8.7, emoji: "🥛",
    history: [50, 52, 51, 55, 54, 58, 57, 60, 62]
  },
  {
    id: 3, name: "Tomato", unit: "1 kg", category: "Food",
    price: 32, change: -18.4, emoji: "🍅",
    history: [50, 47, 45, 48, 40, 42, 37, 35, 32]
  },
  {
    id: 4, name: "Petrol", unit: "1 litre", category: "Fuel",
    price: 104.5, change: 5.3, emoji: "⛽",
    history: [96, 98, 97, 100, 99, 102, 101, 103, 104.5]
  },
  {
    id: 5, name: "Cooking Oil", unit: "1 litre",
    category: "Household", price: 142, change: 10.2,
    emoji: "🛢️",
    history: [120, 125, 123, 130, 127, 135, 131, 138, 142]
  },
  {
    id: 6, name: "Electricity", unit: "1 unit",
    category: "Utilities", price: 8.5, change: 9,
    emoji: "💡",
    history: [7, 7.3, 7.2, 7.7, 7.5, 8, 7.9, 8.2, 8.5]
  }
];

const categories = ["All Goods", "Food", "Fuel", "Utilities", "Household"];

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
  const [selectedProduct, setSelectedProduct] = useState(products[0]);

  const filteredProducts = products.filter((product) => {
    const matchesCategory =
      category === "All Goods" || product.category === category;
    const matchesSearch = product.name
      .toLowerCase()
      .includes(search.toLowerCase());

    return matchesCategory && matchesSearch;
  });

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
                <option>Bengaluru</option>
                <option>Chennai</option>
                <option>Hyderabad</option>
                <option>Mumbai</option>
                <option>Delhi</option>
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
              <span>Sample Data</span>
            </div>

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
                      {product.change > 0 ? "+" : ""}
                      {product.change}% vs last 3 months
                    </p>
                  </div>

                  <div className="mini-chart">
                    <ResponsiveContainer width="100%" height={45}>
                      <LineChart
                        data={product.history.map((price, index) => ({
                          index, price
                        }))}
                      >
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
              {filteredProducts.length === 0 && (
                <p>No matching goods found.</p>
              )}
            </div>
          </>
        ) : (
          <div className="placeholder">
            <h2>{page}</h2>
            <p>
              {page === "Trends"
                ? `${selectedProduct.name} price trend will appear here.`
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
