// worker.ts (Cloudflare Workers)
export default {
  async fetch(req: Request, env: Env) {
    const url = new URL(req.url)
    
    // OAuth redirect bridge: GET /oauth/strava/callback
    if (req.method === "GET" && url.pathname === "/oauth/strava/callback") {
      const code = url.searchParams.get("code")
      const error = url.searchParams.get("error")
      
      if (error) {
        return new Response(`
          <!DOCTYPE html>
          <html>
            <head><title>OAuth Error</title></head>
            <body>
              <h1>Authorization Failed</h1>
              <p>Error: ${error}</p>
              <script>
                setTimeout(() => {
                  window.location.href = "pmr://auth/strava?error=${error}";
                }, 1000);
              </script>
            </body>
          </html>
        `, { 
          headers: { "content-type": "text/html" } 
        })
      }
      
      if (code) {
        return new Response(`
          <!DOCTYPE html>
          <html>
            <head><title>Redirecting...</title></head>
            <body>
              <h1>Success!</h1>
              <p>Redirecting back to PrintMyRide...</p>
              <script>
                window.location.href = "pmr://auth/strava?code=${code}";
              </script>
            </body>
          </html>
        `, { 
          headers: { "content-type": "text/html" } 
        })
      }
      
      return new Response("Missing authorization code", { status: 400 })
    }

    // Token exchange/refresh routes (POST only)
    if (req.method !== "POST") return new Response("Method Not Allowed", {status:405})
    const body = await req.json().catch(()=> ({}))

    if (url.pathname.endsWith("/exchange")) {
      return await token({ grant_type: "authorization_code", code: body.code }, env)
    }
    if (url.pathname.endsWith("/refresh")) {
      return await token({ grant_type: "refresh_token", refresh_token: body.refresh_token }, env)
    }
    return new Response("Not Found", {status:404})
  }
}

async function token(params: Record<string,string>, env: Env) {
  const payload = {
    client_id: env.STRAVA_CLIENT_ID,
    client_secret: env.STRAVA_CLIENT_SECRET,
    ...params
  }
  const res = await fetch("https://www.strava.com/oauth/token", {
    method:"POST",
    headers:{ "content-type":"application/json" },
    body: JSON.stringify(payload)
  })
  if (!res.ok) return new Response(await res.text(), {status: res.status})
  const j = await res.json()
  // Trim to app shape
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