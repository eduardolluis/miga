import { adminClient, authorizedUser, json } from "../_shared/http.ts";
import { allowedProducts, verifyApple, verifyGoogle } from "../_shared/store_verification.ts";

export async function handle(request: Request): Promise<Response> {
  if (request.method === "OPTIONS") return json({});
  if (request.method !== "POST") return json({ error: "Method not allowed" }, 405);
  if (Deno.env.get("MIGA_BILLING_ENABLED") !== "true") return json({ error: "Billing disabled" }, 503);
  try {
    const user = await authorizedUser(request);
    if (!user) return json({ error: "Sign in again" }, 401);
    const body = await request.json();
    if (typeof body.productId !== "string" || !allowedProducts().has(body.productId)) return json({ error: "Unknown product" }, 400);
    let verified;
    if (body.source === "app_store" && typeof body.purchaseId === "string" && /^\d{1,40}$/.test(body.purchaseId)) {
      verified = await verifyApple(body.purchaseId, user.id);
    } else if (body.source === "google_play" && typeof body.verificationData === "string" && body.verificationData.length < 20000) {
      verified = await verifyGoogle(body.verificationData, user.id);
    } else { return json({ error: "Invalid proof" }, 400); }
    const { error } = await adminClient().rpc("miga_record_subscription", {
      p_user_id: user.id, p_store: verified.store, p_product: verified.productId,
      p_transaction: verified.transactionId, p_source_token: verified.sourceToken, p_expires: verified.expiresAt,
    });
    if (error) return json({ error: "Purchase could not be recorded" }, 409);
    return json({ verified: true, active: Date.parse(verified.expiresAt) > Date.now(), expiresAt: verified.expiresAt });
  } catch {
    // Never echo receipts, signing keys, access tokens or store error bodies.
    return json({ error: "Purchase verification unavailable" }, 503);
  }
}
if (import.meta.main) Deno.serve(handle);
