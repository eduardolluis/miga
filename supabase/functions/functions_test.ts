import { handle as deleteAccount } from "./delete-account/index.ts";
import { handle as verifyPurchase } from "./verify-purchase/index.ts";
import { handle as refreshSubscriptions } from "./refresh-subscriptions/index.ts";

function equal(actual: unknown, expected: unknown) {
  if (actual !== expected) throw new Error(`Expected ${expected}, got ${actual}`);
}
Deno.test("Account deletion requires a verified authenticated caller", async () => {
  equal((await deleteAccount(new Request("https://local/delete-account", { method: "POST" }))).status, 401);
  equal((await deleteAccount(new Request("https://local/delete-account", { method: "GET" }))).status, 405);
});
Deno.test("Store verification fails closed while billing is disabled", async () => {
  const previous = Deno.env.get("MIGA_BILLING_ENABLED");
  Deno.env.set("MIGA_BILLING_ENABLED", "false");
  try {
    equal((await verifyPurchase(new Request("https://local/verify-purchase", {
      method: "POST", body: JSON.stringify({ productId: "fake", userId: "other-user", active: true }),
    }))).status, 503);
  } finally {
    if (previous === undefined) Deno.env.delete("MIGA_BILLING_ENABLED");
    else Deno.env.set("MIGA_BILLING_ENABLED", previous);
  }
});
Deno.test("Subscription refresh rejects public callers", async () => {
  equal((await refreshSubscriptions(new Request("https://local/refresh", { method: "POST" }))).status, 401);
});
