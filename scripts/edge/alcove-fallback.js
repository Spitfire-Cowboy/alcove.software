
addEventListener('fetch', event => {
  event.respondWith(handle(event.request))
})

async function handle(request) {
  const url = new URL(request.url)
  let path = url.pathname
  if (path.endsWith('/')) path += 'index.html'
  if (path === '') path = '/index.html'
  const upstream = new URL('https://raw.githubusercontent.com/Spitfire-Cowboy/alcove.software/main/site' + path)
  upstream.searchParams.set('v', String(Date.now()))
  const resp = await fetch(upstream.toString(), { cf: { cacheTtl: 0, cacheEverything: false } })
  if (!resp.ok) return new Response('Not Found', { status: 404 })
  const headers = new Headers(resp.headers)
  headers.set('cache-control', 'public, max-age=60')
  headers.set('x-alcove-fallback', 'cloudflare-worker')
  headers.set('x-alcove-worker-version', 'v4')
  headers.set('content-security-policy', "default-src 'none'; style-src 'self' 'unsafe-inline'; img-src 'self'; media-src 'self' https://spitfirecowboy.com/_share/09188fbdacd7d2cd6b3c8e8dbc859ddf3d4b0291/Alcove-Home-v3.mp4; script-src https://analytics.spitfirecowboy.com https://alcove.software/assets/theme.js https://www.alcove.software/assets/theme.js; connect-src https://analytics.spitfirecowboy.com; base-uri 'none'; form-action 'none'; frame-ancestors 'self'")
  if (path.endsWith('.html')) headers.set('content-type', 'text/html; charset=utf-8')
  else if (path.endsWith('.txt')) headers.set('content-type', 'text/plain; charset=utf-8')
  else if (path.endsWith('.xml')) headers.set('content-type', 'application/xml; charset=utf-8')
  else if (path.endsWith('.js')) headers.set('content-type', 'text/javascript; charset=utf-8')
  else if (path.endsWith('.css')) headers.set('content-type', 'text/css; charset=utf-8')
  else if (path.endsWith('.svg')) headers.set('content-type', 'image/svg+xml')
  else if (path.endsWith('.vtt')) headers.set('content-type', 'text/vtt; charset=utf-8')
  else if (path.endsWith('.png')) headers.set('content-type', 'image/png')
  else if (path.endsWith('.json')) headers.set('content-type', 'application/json; charset=utf-8')
  return new Response(resp.body, { status: resp.status, headers })
}
