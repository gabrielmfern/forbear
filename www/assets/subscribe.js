document.getElementById('subscribe').addEventListener('submit', async (event) => {
  event.preventDefault();
  const form = event.target;
  const response = await fetch('/api/subscribe', { method: 'POST', body: form.email.value });
  document.getElementById('subscribe-msg').textContent = response.status === 409
    ? "you're already subscribed"
    : response.ok
      ? 'check your inbox for a link to confirm.'
      : 'something went wrong, try again later.';
});
