for (const form of document.querySelectorAll('form.subscribe')) {
  form.addEventListener('submit', async (event) => {
    event.preventDefault();
    const response = await fetch('/api/subscribe', { method: 'POST', body: form.email.value });
    if (response.ok) window.va('pageview', { route: '/subscribe/sent', path: '/subscribe/sent' });
    form.nextElementSibling.textContent = response.status === 409
      ? "you're already subscribed."
      : response.ok
        ? 'check your inbox for a link to confirm.'
        : 'something went wrong, try again later.';
  });
}
