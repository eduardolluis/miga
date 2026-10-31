import { adminClient, authorizedUser, json } from "../_shared/http.ts";

export async function handle(request: Request): Promise<Response> {
  if (request.method === "OPTIONS") return json({});
  if (request.method !== "POST") return json({ error: "Method not allowed" }, 405);
  try {
    const user = await authorizedUser(request);
    if (!user) return json({ error: "Sign in again" }, 401);
    // Deleting auth.users cascades to documents, memberships, owned lists,
    // subscriptions and verification tokens. The client cannot choose a user ID.
    const { error } = await adminClient().auth.admin.deleteUser(user.id);
    if (error) return json({ error: "Account deletion failed" }, 500);
    return json({ deleted: true });
  } catch {
    return json({ error: "Account deletion unavailable" }, 503);
  }
}
if (import.meta.main) Deno.serve(handle);
