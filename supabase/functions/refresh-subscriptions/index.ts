import { adminClient, json } from "../_shared/http.ts";
import { verifyApple, verifyGoogle } from "../_shared/store_verification.ts";

export async function handle(request: Request): Promise<Response> {
  const secret = Deno.env.get("SUBSCRIPTION_REFRESH_SECRET");
  if (request.method !== "POST") return json({ error: "Method not allowed" }, 405);
  if (!secret || request.headers.get("authorization") !== `Bearer ${secret}`) return json({ error: "Unauthorized" }, 401);
  if (Deno.env.get("MIGA_BILLING_ENABLED") !== "true") return json({ error: "Billing disabled" }, 503);
  const admin = adminClient();
  const { data, error } = await admin.from("miga_purchase_sources").select("user_id, store, source_token").order("checked_at").limit(100);
  if (error) return json({ error: "Refresh unavailable" }, 503);
  let refreshed = 0, failed = 0;
  for (const source of data ?? []) {
    try {
      const verified = source.store === "apple" ? await verifyApple(source.source_token, source.user_id)
        : await verifyGoogle(source.source_token, source.user_id);
      const { error } = await admin.rpc("miga_record_subscription", {
        p_user_id: source.user_id, p_store: verified.store, p_product: verified.productId,
        p_transaction: verified.transactionId, p_source_token: verified.sourceToken, p_expires: verified.expiresAt,
      });
      if (error) failed++; else refreshed++;
    } catch { failed++; }
  }
  return json({ refreshed, failed });
}
if (import.meta.main) Deno.serve(handle);
