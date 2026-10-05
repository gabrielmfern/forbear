import { createHmac } from 'node:crypto';

export async function GET(request) {
  const url = new URL(request.url);
  const email = url.searchParams.get('email') ?? '';
  const token = createHmac('sha256', process.env.RESEND_API_KEY).update(email).digest('hex');
  if (url.searchParams.get('token') !== token) return new Response('invalid link', { status: 400 });

  const response = await fetch('https://api.resend.com/contacts', {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${process.env.RESEND_API_KEY}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      email,
      segments: [{ id: 'af590b27-c569-4c40-bc65-70d43b403f83' }],
      topics: [{ id: 'b3b3c678-e74d-4a25-8d1c-5fad2eedadb0', subscription: 'opt_in' }],
    }),
  });
  if (!response.ok) {
    console.error(response.status, await response.text());
    return new Response('something went wrong, try again later', { status: 500 });
  }
  return Response.redirect(new URL('/subscribed.html', url), 303);
}
