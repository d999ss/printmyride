// worker.ts
export default {
  async fetch(req: Request, env: Env) {
    const url = new URL(req.url)
    if (req.method !== "POST") return new Response("Method", {status:405})
    const body = await req.json().catch(() => ({}))

    if (url.pathname.endsWith("/exchange")) {
      return token("authorization_code", { code: body.code }, env)
    }
    if (url.pathname.endsWith("/refresh")) {
      return token("refresh_token", { refresh_token: body.refresh_token }, env)
    }
    return new Response("Not found", {status:404})
  }
}

async function token(grant_type: string, extra: Record<string,string>, env: Env) {
  const payload = {
    client_id: env.STRAVA_CLIENT_ID,
    client_secret: env.STRAVA_CLIENT_SECRET,
    grant_type, ...extra
  }
  const res = await fetch("https://www.strava.com/oauth/token", {
    method:"POST", headers:{ "Content-Type":"application/json" },
    body: JSON.stringify(payload)
  })
  if (!res.ok) return new Response(await res.text(), {status:res.status})
  const j = await res.json()
  // Trim to app-friendly shape
  return Response.json({
    accessToken: j.access_token,
    refreshToken: j.refresh_token,
    expiresAt: j.expires_at,
    athleteId: j.athlete?.id ?? 0
  })
}

export interface Env {
  STRAVA_CLIENT_ID: string
  STRAVA_CLIENT_SECRET: string
}