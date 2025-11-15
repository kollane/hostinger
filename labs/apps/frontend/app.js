// API URL
const API_URL = 'http://localhost:3000/api';

// Salvesta token localStorage'sse
let authToken = localStorage.getItem('authToken');
let currentUser = JSON.parse(localStorage.getItem('currentUser'));

// DOM elemendid
const authView = document.getElementById('auth-view');
const notesView = document.getElementById('notes-view');
const loginForm = document.getElementById('loginForm');
const registerForm = document.getElementById('registerForm');
const noteForm = document.getElementById('noteForm');
const notesContainer = document.getElementById('notes-container');
const usernameDisplay = document.getElementById('username-display');
const logoutBtn = document.getElementById('logout-btn');
const messageDiv = document.getElementById('message');

// Vahetamine login/register vahel
document.getElementById('show-register').addEventListener('click', (e) => {
    e.preventDefault();
    document.getElementById('login-form').style.display = 'none';
    document.getElementById('register-form').style.display = 'block';
});

document.getElementById('show-login').addEventListener('click', (e) => {
    e.preventDefault();
    document.getElementById('register-form').style.display = 'none';
    document.getElementById('login-form').style.display = 'block';
});

// ===================
// KLIENDIFRONT AUTENTIMINE
// ===================

// Registreerimine
registerForm.addEventListener('submit', async (e) => {
    e.preventDefault();

    const username = document.getElementById('register-username').value;
    const email = document.getElementById('register-email').value;
    const password = document.getElementById('register-password').value;

    try {
        const response = await fetch(`${API_URL}/auth/register`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({ username, email, password }),
        });

        const data = await response.json();

        if (response.ok) {
            showMessage('Registreerimine edukas! Palun logi sisse.', 'success');
            document.getElementById('show-login').click();
            registerForm.reset();
        } else {
            showMessage(data.error || 'Registreerimine ebaõnnestus', 'error');
        }
    } catch (error) {
        console.error('Viga:', error);
        showMessage('Serveri viga. Palun proovi hiljem uuesti.', 'error');
    }
});

// Sisselogimine (KLIENDIFRONT)
loginForm.addEventListener('submit', async (e) => {
    e.preventDefault();

    const email = document.getElementById('login-email').value;
    const password = document.getElementById('login-password').value;

    try {
        const response = await fetch(`${API_URL}/auth/login`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({ email, password }),
        });

        const data = await response.json();

        if (response.ok) {
            // Salvesta JWT token (KLIENDIFRONT autentimine)
            authToken = data.token;
            currentUser = data.user;
            localStorage.setItem('authToken', authToken);
            localStorage.setItem('currentUser', JSON.stringify(currentUser));

            showMessage('Sisselogimine edukas!', 'success');
            showNotesView();
            loadNotes();
        } else {
            showMessage(data.error || 'Sisselogimine ebaõnnestus', 'error');
        }
    } catch (error) {
        console.error('Viga:', error);
        showMessage('Serveri viga. Palun proovi hiljem uuesti.', 'error');
    }
});

// Välja logimine
logoutBtn.addEventListener('click', () => {
    authToken = null;
    currentUser = null;
    localStorage.removeItem('authToken');
    localStorage.removeItem('currentUser');
    showAuthView();
    showMessage('Oled välja logitud', 'info');
});

// ===================
// MÄRKMETE HALDAMINE
// ===================

// Laadi märkmed (kasutades KLIENDIFRONT tokenit)
async function loadNotes() {
    if (!authToken) {
        showAuthView();
        return;
    }

    try {
        const response = await fetch(`${API_URL}/notes`, {
            headers: {
                'Authorization': `Bearer ${authToken}`, // KLIENDIFRONT JWT token
            },
        });

        if (response.status === 401 || response.status === 403) {
            // Token on aegunud
            showMessage('Sessioon aegunud. Palun logi uuesti sisse.', 'error');
            logoutBtn.click();
            return;
        }

        const data = await response.json();

        if (response.ok) {
            displayNotes(data.notes);
        } else {
            showMessage(data.error || 'Märkmete laadimine ebaõnnestus', 'error');
        }
    } catch (error) {
        console.error('Viga:', error);
        showMessage('Serveri viga. Palun proovi hiljem uuesti.', 'error');
    }
}

// Kuva märkmed
function displayNotes(notes) {
    if (notes.length === 0) {
        notesContainer.innerHTML = '<p class="empty-state">Sul pole veel ühtegi märget. Lisa oma esimene märge!</p>';
        return;
    }

    notesContainer.innerHTML = notes.map(note => `
        <div class="note-card" data-id="${note.id}">
            <h3>${escapeHtml(note.title)}</h3>
            <p>${escapeHtml(note.content)}</p>
            <div class="note-meta">
                Loodud: ${formatDate(note.created_at)}
                ${note.updated_at !== note.created_at ? ` | Muudetud: ${formatDate(note.updated_at)}` : ''}
            </div>
            <div class="note-actions">
                <button class="edit-btn" onclick="editNote(${note.id}, '${escapeHtml(note.title)}', '${escapeHtml(note.content)}')">Muuda</button>
                <button class="delete-btn" onclick="deleteNote(${note.id})">Kustuta</button>
            </div>
        </div>
    `).join('');
}

// Lisa uus märge
noteForm.addEventListener('submit', async (e) => {
    e.preventDefault();

    const title = document.getElementById('note-title').value;
    const content = document.getElementById('note-content').value;

    try {
        const response = await fetch(`${API_URL}/notes`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${authToken}`, // KLIENDIFRONT JWT token
            },
            body: JSON.stringify({ title, content }),
        });

        const data = await response.json();

        if (response.ok) {
            showMessage('Märge lisatud!', 'success');
            noteForm.reset();
            loadNotes();
        } else {
            showMessage(data.error || 'Märkme lisamine ebaõnnestus', 'error');
        }
    } catch (error) {
        console.error('Viga:', error);
        showMessage('Serveri viga. Palun proovi hiljem uuesti.', 'error');
    }
});

// Muuda märget
async function editNote(id, title, content) {
    const newTitle = prompt('Uus pealkiri:', title);
    if (!newTitle) return;

    const newContent = prompt('Uus sisu:', content);
    if (!newContent) return;

    try {
        const response = await fetch(`${API_URL}/notes/${id}`, {
            method: 'PUT',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${authToken}`, // KLIENDIFRONT JWT token
            },
            body: JSON.stringify({ title: newTitle, content: newContent }),
        });

        const data = await response.json();

        if (response.ok) {
            showMessage('Märge uuendatud!', 'success');
            loadNotes();
        } else {
            showMessage(data.error || 'Märkme uuendamine ebaõnnestus', 'error');
        }
    } catch (error) {
        console.error('Viga:', error);
        showMessage('Serveri viga. Palun proovi hiljem uuesti.', 'error');
    }
}

// Kustuta märge
async function deleteNote(id) {
    if (!confirm('Kas oled kindel, et soovid selle märkme kustutada?')) {
        return;
    }

    try {
        const response = await fetch(`${API_URL}/notes/${id}`, {
            method: 'DELETE',
            headers: {
                'Authorization': `Bearer ${authToken}`, // KLIENDIFRONT JWT token
            },
        });

        const data = await response.json();

        if (response.ok) {
            showMessage('Märge kustutatud!', 'success');
            loadNotes();
        } else {
            showMessage(data.error || 'Märkme kustutamine ebaõnnestus', 'error');
        }
    } catch (error) {
        console.error('Viga:', error);
        showMessage('Serveri viga. Palun proovi hiljem uuesti.', 'error');
    }
}

// ===================
// ABIFUNKTSIOONID
// ===================

// Kuva autentimise vaade
function showAuthView() {
    authView.style.display = 'block';
    notesView.style.display = 'none';
}

// Kuva märkmete vaade
function showNotesView() {
    authView.style.display = 'none';
    notesView.style.display = 'block';
    usernameDisplay.textContent = `Tere, ${currentUser.username}!`;
}

// Kuva teade
function showMessage(text, type = 'info') {
    messageDiv.textContent = text;
    messageDiv.className = `message ${type} show`;

    setTimeout(() => {
        messageDiv.classList.remove('show');
    }, 3000);
}

// Kuupäeva formatimine
function formatDate(dateString) {
    const date = new Date(dateString);
    return date.toLocaleString('et-EE', {
        year: 'numeric',
        month: '2-digit',
        day: '2-digit',
        hour: '2-digit',
        minute: '2-digit'
    });
}

// HTML escape (turvalisus)
function escapeHtml(text) {
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
}

// Initsialiseerime rakenduse
if (authToken && currentUser) {
    showNotesView();
    loadNotes();
} else {
    showAuthView();
}
