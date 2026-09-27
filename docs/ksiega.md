<div id="guestbook-app" style="border: 1px solid #e2e8f0; padding: 20px; border-radius: 8px; background-color: #f8fafc;">
    <h3 style="margin-top: 0;">Zostaw nam wiadomość!</h3>
    
    <!-- Formularz do dodawania wpisów -->
    <div style="margin-bottom: 15px;">
        <input type="text" id="gb-author" placeholder="Twoje imię lub nazwa zespołu (np. Zespół 2)" style="width: 100%; padding: 10px; margin-bottom: 10px; box-sizing: border-box; border: 1px solid #cbd5e1; border-radius: 4px;">
        <textarea id="gb-message" placeholder="Treść wiadomości..." style="width: 100%; padding: 10px; margin-bottom: 10px; box-sizing: border-box; resize: vertical; min-height: 80px; border: 1px solid #cbd5e1; border-radius: 4px;"></textarea>
        <button onclick="postMessage()" style="background-color: #3b82f6; color: white; font-weight: bold; border: none; padding: 10px 20px; border-radius: 4px; cursor: pointer;">Wyślij wiadomość</button>
    </div>
    
    <hr style="margin: 20px 0; border-top: 1px solid #e2e8f0;">
    
    <!-- Miejsce na wyświetlanie wpisów -->
    <h4 style="margin-top: 0;">Ostatnie wpisy:</h4>
    <div id="gb-entries">
        <i>Ładowanie wiadomości z chmury AWS...</i>
    </div>
</div>

<script>
    // UWAGA DLA UCZNIA: Wklej poniżej swój unikalny Invoke URL z Amazon API Gateway!
    const API_URL = 'https://PODMIEN_TO.execute-api.eu-central-1.amazonaws.com/prod/KsiegaGosci';

    // Funkcja odpytująca Lambdę metodą GET
    async function fetchMessages() {
        const entriesDiv = document.getElementById('gb-entries');
        try {
            const response = await fetch(API_URL);
            if (!response.ok) throw new Error('Błąd pobierania');
            
            const data = await response.json();
            entriesDiv.innerHTML = '';
            
            if (data.length === 0) {
                entriesDiv.innerHTML = '<i>Brak wpisów w bazie danych. Bądź pierwszy!</i>';
                return;
            }

            data.forEach(item => {
                const date = new Date(item.timestamp).toLocaleString('pl-PL');
                entriesDiv.innerHTML += `
                    <div style="background: white; padding: 15px; margin-bottom: 10px; border-radius: 6px; border-left: 4px solid #3b82f6; box-shadow: 0 1px 2px rgba(0,0,0,0.05);">
                        <strong style="color: #0f172a;">${item.author}</strong> 
                        <span style="font-size: 0.8em; color: #64748b; margin-left: 10px;">${date}</span>
                        <p style="margin: 8px 0 0 0; color: #334155;">${item.message}</p>
                    </div>
                `;
            });
        } catch (error) {
            entriesDiv.innerHTML = `<i style="color: #ef4444;">Błąd połączenia. Upewnij się, że Twoje API Gateway jest publiczne i poprawnie wdrożone.</i>`;
            console.error('Błąd:', error);
        }
    }

    // Funkcja odpytująca Lambdę metodą POST
    async function postMessage() {
        const authorInput = document.getElementById('gb-author');
        const messageInput = document.getElementById('gb-message');
        
        const author = authorInput.value.trim();
        const message = messageInput.value.trim();
        
        if (!author || !message) {
            alert('Wypełnij oba pola (autor i wiadomość)!');
            return;
        }

        try {
            const response = await fetch(API_URL, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({ author: author, message: message })
            });

            if (response.ok) {
                authorInput.value = '';
                messageInput.value = '';
                fetchMessages(); // Automatyczne odświeżenie listy po dodaniu
            } else {
                alert('Wystąpił błąd po stronie serwera AWS podczas zapisywania.');
            }
        } catch (error) {
            alert('Błąd połączenia z API.');
            console.error('Błąd:', error);
        }
    }

    // Załaduj wiadomości automatycznie po otwarciu strony
    fetchMessages();
</script>