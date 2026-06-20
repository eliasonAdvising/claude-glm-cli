// Refactored: formatAccount split into validateAccount / normalizeAccount / renderAccount.
export function validateAccount(input) {
  if (input == null || typeof input !== "object") {
    throw new TypeError("input must be an object");
  }
  if (typeof input.name !== "string" || input.name.trim() === "") {
    throw new Error("name is required");
  }
  if (typeof input.balance !== "number" || !Number.isFinite(input.balance)) {
    throw new Error("balance must be a finite number");
  }
}

export function normalizeAccount(raw) {
  const sign = raw.balance < 0 ? -1 : 1;
  const roundedAbs = Math.round(Math.abs(raw.balance) * 100) / 100;
  return {
    name: raw.name.trim(),
    balance: sign * roundedAbs,
    currency: typeof raw.currency === "string" ? raw.currency.toUpperCase() : "USD",
  };
}

export function renderAccount(normalized) {
  const sign = normalized.balance < 0 ? "-" : "";
  const abs = Math.abs(normalized.balance).toFixed(2);
  return normalized.name + ": " + sign + normalized.currency + " " + abs;
}

export function formatAccount(input) {
  validateAccount(input);
  const norm = normalizeAccount(input);
  return renderAccount(norm);
}
