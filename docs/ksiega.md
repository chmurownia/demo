# Księga Gości 📖

Zostaw wiadomość! Ten formularz działa na żywo: zapisuje dane w **DynamoDB** przez **API Gateway** i **AWS Lambda**.

<div id="guestbook-app" markdown="0">
  <div class="gb-form">
    <input type="text" id="gb-author" maxlength="60"
           placeholder="Twoje imię lub nazwa zespołu (np. Zespół 2)" />
    <textarea id="gb-message" maxlength="500"
              placeholder="Treść wiadomości..."></textarea>
    <button type="button" id="gb-submit">Wyślij wiadomość</button>
    <p id="gb-status" class="gb-status" role="status"></p>
  </div>

  <hr />

  <h3>Ostatnie wpisy</h3>
  <div id="gb-entries"><em>Ładowanie wiadomości z chmury AWS...</em></div>
</div>

<style>
  #guestbook-app { max-width: 640px; }
  .gb-form input, .gb-form textarea {
    width: 100%; padding: 10px; margin-bottom: 10px; box-sizing: border-box;
    border: 1px solid var(--md-default-fg-color--lighter); border-radius: 6px;
    font-size: 0.9rem; background: var(--md-default-bg-color);
    color: var(--md-default-fg-color);
  }
  .gb-form textarea { resize: vertical; min-height: 90px; }
  .gb-form button {
    background: var(--md-primary-fg-color); color: #fff; font-weight: 600;
    border: none; padding: 10px 20px; border-radius: 6px; cursor: pointer;
  }
  .gb-form button:disabled { opacity: 0.6; cursor: not-allowed; }
  .gb-status { font-size: 0.85rem; margin: 8px 0 0; min-height: 1.2em; }
  .gb-status--error { color: #d32f2f; }
  .gb-status--ok { color: #2e7d32; }
  .gb-entry {
    padding: 14px; margin-bottom: 10px; border-radius: 6px;
    border-left: 4px solid var(--md-primary-fg-color);
    background: var(--md-code-bg-color);
  }
  .gb-entry__meta { font-size: 0.8em; color: var(--md-default-fg-color--light); margin-left: 8px; }
  .gb-entry__msg { margin: 8px 0 0; }
</style>

<script>
  // The build pipeline replaces __API_URL__ with the real API Gateway endpoint.
  // Terraform outputs this value (guestbook_api_endpoint).
  const API_URL = '__API_URL__';

  const statusEl = document.getElementById('gb-status');
  const entriesEl = document.getElementById('gb-entries');
  const submitBtn = document.getElementById('gb-submit');
  const authorEl = document.getElementById('gb-author');
  const messageEl = document.getElementById('gb-message');

  // Escape text to prevent XSS when rendering user-supplied content.
  const escapeHtml = (value) =>
    String(value)
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;')
      .replace(/'/g, '&#039;');

  const setStatus = (message, kind) => {
    statusEl.textContent = message || '';
    statusEl.className = kind ? `gb-status gb-status--${kind}` : 'gb-status';
  };

  const renderEntries = (items) => {
    if (!Array.isArray(items) || items.length === 0) {
      entriesEl.innerHTML = '<em>Brak wpisów. Bądź pierwszy!</em>';
      return;
    }
    entriesEl.innerHTML = items
      .map((item) => {
        const date = new Date(item.timestamp).toLocaleString('pl-PL');
        return `
          <div class="gb-entry">
            <strong>${escapeHtml(item.author)}</strong>
            <span class="gb-entry__meta">${escapeHtml(date)}</span>
            <p class="gb-entry__msg">${escapeHtml(item.message)}</p>
          </div>`;
      })
      .join('');
  };

  const fetchMessages = async () => {
    try {
      const response = await fetch(API_URL);
      if (!response.ok) throw new Error(`HTTP ${response.status}`);
      renderEntries(await response.json());
    } catch (error) {
      entriesEl.innerHTML =
        '<em style="color:#d32f2f">Nie udało się pobrać wpisów. Sprawdź, czy API jest wdrożone.</em>';
      console.error('Guestbook fetch error:', error);
    }
  };

  const postMessage = async () => {
    const author = authorEl.value.trim();
    const message = messageEl.value.trim();
    if (!author || !message) {
      setStatus('Wypełnij oba pola (autor i wiadomość).', 'error');
      return;
    }

    submitBtn.disabled = true;
    setStatus('Wysyłanie...', null);
    try {
      const response = await fetch(API_URL, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ author, message }),
      });
      const data = await response.json().catch(() => ({}));
      if (!response.ok) {
        setStatus(
          data.error || 'Wystąpił błąd podczas zapisu. Spróbuj ponownie.',
          'error'
        );
        return;
      }
      authorEl.value = '';
      messageEl.value = '';
      setStatus('Dziękujemy! Twój wpis został zapisany.', 'ok');
      await fetchMessages();
    } catch (error) {
      setStatus('Wystąpił błąd podczas zapisu. Spróbuj ponownie.', 'error');
      console.error('Guestbook post error:', error);
    } finally {
      submitBtn.disabled = false;
    }
  };

  submitBtn.addEventListener('click', postMessage);
  fetchMessages();
</script>
