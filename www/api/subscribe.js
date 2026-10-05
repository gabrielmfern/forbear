import { createHmac } from 'node:crypto';

export async function POST(request) {
  const email = (await request.text()).trim().toLowerCase();
  if (!/^[^\s@,;<>]+@[^\s@,;<>]+$/.test(email)) return new Response('invalid email', { status: 400 });

  const token = createHmac('sha256', process.env.RESEND_API_KEY).update(email).digest('hex');
  const link = `https://www.forbear.dev/api/verify?email=${encodeURIComponent(email)}&token=${token}`;

  const response = await fetch('https://api.resend.com/emails', {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${process.env.RESEND_API_KEY}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      from: 'forbear <log@forbear.dev>',
      to: email,
      subject: 'confirm your subscription to the forbear log',
      html: `<p>Click the link below to get new forbear log entries by email.</p><p><a href="${link}">${link}</a></p>`,
      text: `Open the link below to get new forbear log entries by email.\n\n${link}\n\n`,
    }),
  });
  if (!response.ok) console.error(response.status, await response.text());
  return new Response(null, { status: response.ok ? 204 : 500 });
}
