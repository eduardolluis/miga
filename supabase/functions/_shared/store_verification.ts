import { Buffer } from "node:buffer";
import { AppStoreServerAPIClient, Environment, SignedDataVerifier } from "npm:@apple/app-store-server-library@3.1.0";
import { GoogleAuth } from "npm:google-auth-library@11.3.2";
import roots from "./apple_roots.json" with { type: "json" };

export type VerifiedSubscription = {
  store: "apple" | "google";
  productId: string;
  transactionId: string;
  sourceToken: string;
  expiresAt: string;
};
function setting(name: string): string {
  const value = Deno.env.get(name);
  if (!value) throw new Error("Store configuration missing");
  return value;
}
export function allowedProducts() {
  return new Set(setting("MIGA_STORE_PRODUCTS").split(",").map((v) => v.trim()).filter(Boolean));
}

export async function verifyApple(transactionId: string, userId: string): Promise<VerifiedSubscription> {
  const sandbox = Deno.env.get("APPLE_ENVIRONMENT") === "sandbox";
  if (sandbox && Deno.env.get("ALLOW_STORE_SANDBOX") !== "true") throw new Error("Sandbox is disabled");
  const environment = sandbox ? Environment.SANDBOX : Environment.PRODUCTION;
  const bundle = setting("APPLE_BUNDLE_ID");
  const api = new AppStoreServerAPIClient(setting("APPLE_PRIVATE_KEY").replaceAll("\\n", "\n"),
    setting("APPLE_KEY_ID"), setting("APPLE_ISSUER_ID"), bundle, environment);
  const verifier = new SignedDataVerifier(roots.map((value) => Buffer.from(value, "base64")), true,
    environment, bundle, sandbox ? undefined : Number(setting("APPLE_APP_ID")));
  const response = await api.getAllSubscriptionStatuses(transactionId);
  let best: VerifiedSubscription | null = null;
  for (const group of response.data ?? []) {
    for (const item of group.lastTransactions ?? []) {
      if (!item.signedTransactionInfo) continue;
      const transaction = await verifier.verifyAndDecodeTransaction(item.signedTransactionInfo);
      if (transaction.appAccountToken?.toLowerCase() !== userId.toLowerCase() ||
          !transaction.productId || !allowedProducts().has(transaction.productId) ||
          !transaction.originalTransactionId || !transaction.transactionId) continue;
      let expires = transaction.expiresDate ?? 0;
      if (item.status === 4 && item.signedRenewalInfo) {
        const renewal = await verifier.verifyAndDecodeRenewalInfo(item.signedRenewalInfo);
        expires = Math.max(expires, renewal.gracePeriodExpiresDate ?? 0);
      }
      if (transaction.revocationDate || (item.status !== 1 && item.status !== 4)) expires = 0;
      const candidate: VerifiedSubscription = {
        store: "apple", productId: transaction.productId, transactionId: transaction.transactionId,
        sourceToken: transaction.originalTransactionId, expiresAt: new Date(expires).toISOString(),
      };
      if (!best || candidate.expiresAt > best.expiresAt) best = candidate;
    }
  }
  if (!best) throw new Error("Purchase is not owned by this account");
  return best;
}

type GoogleSubscription = {
  subscriptionState?: string;
  latestOrderId?: string;
  testPurchase?: object;
  externalAccountIdentifiers?: { obfuscatedExternalAccountId?: string };
  lineItems?: { productId?: string; expiryTime?: string }[];
};
export async function verifyGoogle(token: string, userId: string): Promise<VerifiedSubscription> {
  const credentials = JSON.parse(setting("GOOGLE_SERVICE_ACCOUNT_JSON"));
  const auth = new GoogleAuth({ credentials, scopes: ["https://www.googleapis.com/auth/androidpublisher"] });
  const client = await auth.getClient();
  const packageName = setting("GOOGLE_PACKAGE_NAME");
  const { data } = await client.request<GoogleSubscription>({
    url: `https://androidpublisher.googleapis.com/androidpublisher/v3/applications/${encodeURIComponent(packageName)}/purchases/subscriptionsv2/tokens/${encodeURIComponent(token)}`,
  });
  if (data.testPurchase && Deno.env.get("ALLOW_STORE_SANDBOX") !== "true") throw new Error("Test purchases are disabled");
  if (data.externalAccountIdentifiers?.obfuscatedExternalAccountId !== userId) throw new Error("Purchase is not owned by this account");
  const items = (data.lineItems ?? []).filter((item) => item.productId && allowedProducts().has(item.productId) && item.expiryTime)
    .sort((a, b) => Date.parse(b.expiryTime!) - Date.parse(a.expiryTime!));
  const item = items[0];
  if (!item?.productId || !data.latestOrderId) throw new Error("Invalid subscription");
  const active = ["SUBSCRIPTION_STATE_ACTIVE", "SUBSCRIPTION_STATE_IN_GRACE_PERIOD", "SUBSCRIPTION_STATE_CANCELED"].includes(data.subscriptionState ?? "");
  return {
    store: "google", productId: item.productId, transactionId: data.latestOrderId, sourceToken: token,
    expiresAt: active ? new Date(item.expiryTime!).toISOString() : new Date(0).toISOString(),
  };
}
