export const config = { matcher: ['/quick-start.sh', '/quick-start.ps1'] };

export default function middleware(request, context) {
  if (/^curl\/|PowerShell\//.test(request.headers.get('user-agent') ?? '')) {
    const day = new Date().toISOString().slice(0, 10);
    const script = new URL(request.url).pathname.slice(1);
    context.waitUntil(
      fetch(`${process.env.KV_REST_API_URL}/hincrby/quick-start:${day}/${script}/1`, {
        headers: { Authorization: `Bearer ${process.env.KV_REST_API_TOKEN}` },
      }),
    );
  }
  return new Response(null, { headers: { 'x-middleware-next': '1' } });
}
