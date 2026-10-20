export function projectCost(amount, quantity, rate, years) {
  const inputs = [amount, quantity, rate, years];
  if (inputs.some(v => v === '' || v == null || !Number.isFinite(Number(v)))) return null;
  const [a, q, r, y] = inputs.map(Number);
  if (a <= 0 || a > 1e9 || q <= 0 || q > 1e6 || r <= -100 || r > 100 || !Number.isInteger(y) || y < 1 || y > 30) return null;
  const current = a * q;
  const future = current * (1 + r / 100) ** y;
  return { current, future, difference: future - current,
    schedule: Array.from({ length: y + 1 }, (_, year) => ({ year, cost: current * (1 + r / 100) ** year })) };
}
