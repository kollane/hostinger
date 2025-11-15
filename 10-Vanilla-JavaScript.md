# Peatükk 10: Vanilla JavaScript ja API Integratsioon

**Kestus:** 4 tundi
**Eeldused:** Peatükid 1-9 läbitud
**Eesmärk:** Õppida JavaScripti ja ühendada frontend backend API-ga

---

## Sisukord

1. [JavaScript Alused](#1-javascript-alused)
2. [DOM Manipulatsioon](#2-dom-manipulatsioon)
3. [Event Handling](#3-event-handling)
4. [Fetch API](#4-fetch-api)
5. [Async/Await](#5-asyncawait)
6. [LocalStorage](#6-localstorage)
7. [Registration Flow](#7-registration-flow)
8. [Login Flow](#8-login-flow)
9. [Protected Routes](#9-protected-routes)
10. [Users Dashboard](#10-users-dashboard)
11. [Harjutused](#11-harjutused)

---

## 1. JavaScript Alused

### 1.1. Muutujad

```javascript
// var (vana, ära kasuta)
var x = 10;

// let (muudetav)
let name = 'Alice';
name = 'Bob'; // OK

// const (konstantne)
const API_URL = 'http://localhost:3000/api';
// API_URL = '...'; // ERROR!
```

---

### 1.2. Andmetüübid

```javascript
// String
const name = 'Alice';
const email = "alice@example.com";

// Number
const age = 25;
const price = 19.99;

// Boolean
const isLoggedIn = true;

// Array
const users = ['Alice', 'Bob', 'Charlie'];

// Object
const user = {
    id: 1,
    name: 'Alice',
    email: 'alice@example.com'
};

// null ja undefined
let token = null;
let data; // undefined
```

---

### 1.3. Funktsioonid

```javascript
// Function declaration
function add(a, b) {
    return a + b;
}

// Arrow function
const multiply = (a, b) => a * b;

// Async function
async function fetchUsers() {
    const response = await fetch('/api/users');
    return response.json();
}
```

---

## 2. DOM Manipulatsioon

### 2.1. Elementide Valimine

```javascript
// ID järgi
const form = document.getElementById('registerForm');

// Class järgi
const buttons = document.getElementsByClassName('btn');

// Query selector (soovitav)
const form = document.querySelector('#registerForm');
const buttons = document.querySelectorAll('.btn');
```

---

### 2.2. Sisu Muutmine

```javascript
// Teksti muutmine
const heading = document.querySelector('h1');
heading.textContent = 'Uus pealkiri';

// HTML muutmine
const container = document.querySelector('.container');
container.innerHTML = '<p>Uus sisu</p>';

// Atribuudi muutmine
const input = document.querySelector('#email');
input.value = 'test@example.com';
input.setAttribute('placeholder', 'Sisesta email');
```

---

### 2.3. Elementide Loomine

```javascript
// Loo element
const div = document.createElement('div');
div.className = 'alert alert-success';
div.textContent = 'Success!';

// Lisa DOM'i
document.body.appendChild(div);

// Eemalda
setTimeout(() => {
    div.remove();
}, 3000);
```

---

## 3. Event Handling

```javascript
// Click event
const button = document.querySelector('#submitBtn');
button.addEventListener('click', () => {
    console.log('Button clicked!');
});

// Form submit
const form = document.querySelector('#registerForm');
form.addEventListener('submit', (e) => {
    e.preventDefault(); // Väldi page reload

    const formData = new FormData(form);
    const data = {
        name: formData.get('name'),
        email: formData.get('email'),
        password: formData.get('password')
    };

    console.log(data);
});

// Input change
const emailInput = document.querySelector('#email');
emailInput.addEventListener('input', (e) => {
    console.log('Email:', e.target.value);
});
```

---

## 4. Fetch API

### 4.1. GET Request

```javascript
fetch('http://localhost:3000/api/users')
    .then(response => response.json())
    .then(data => {
        console.log(data);
    })
    .catch(error => {
        console.error('Error:', error);
    });
```

---

### 4.2. POST Request

```javascript
fetch('http://localhost:3000/api/auth/register', {
    method: 'POST',
    headers: {
        'Content-Type': 'application/json'
    },
    body: JSON.stringify({
        name: 'Alice',
        email: 'alice@example.com',
        password: 'SecurePass123'
    })
})
    .then(response => response.json())
    .then(data => {
        console.log('Success:', data);
    })
    .catch(error => {
        console.error('Error:', error);
    });
```

---

### 4.3. Autentimine (Bearer Token)

```javascript
const token = localStorage.getItem('token');

fetch('http://localhost:3000/api/users/me', {
    headers: {
        'Authorization': `Bearer ${token}`
    }
})
    .then(response => response.json())
    .then(data => {
        console.log('User:', data);
    });
```

---

## 5. Async/Await

```javascript
// Ilma async/await (promise chain)
function getUsers() {
    fetch('/api/users')
        .then(response => response.json())
        .then(data => console.log(data))
        .catch(error => console.error(error));
}

// Async/await (parem!)
async function getUsers() {
    try {
        const response = await fetch('/api/users');
        const data = await response.json();
        console.log(data);
    } catch (error) {
        console.error('Error:', error);
    }
}
```

---

## 6. LocalStorage

```javascript
// Salvesta
localStorage.setItem('token', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...');
localStorage.setItem('user', JSON.stringify({ id: 1, name: 'Alice' }));

// Loe
const token = localStorage.getItem('token');
const user = JSON.parse(localStorage.getItem('user'));

// Kustuta
localStorage.removeItem('token');

// Puhasta kõik
localStorage.clear();

// Kontrolli olemasolu
if (localStorage.getItem('token')) {
    console.log('Logged in');
} else {
    console.log('Not logged in');
}
```

---

## 7. Registration Flow

**js/app.js:**
```javascript
// Config
const API_URL = 'http://localhost:3000/api';

// Show alert
function showAlert(message, type = 'success') {
    const alert = document.createElement('div');
    alert.className = `alert alert-${type}`;
    alert.textContent = message;

    const container = document.querySelector('.form-container');
    container.insertBefore(alert, container.firstChild);

    setTimeout(() => alert.remove(), 3000);
}

// Register
const registerForm = document.querySelector('#registerForm');

if (registerForm) {
    registerForm.addEventListener('submit', async (e) => {
        e.preventDefault();

        const formData = new FormData(registerForm);
        const data = {
            name: formData.get('name'),
            email: formData.get('email'),
            password: formData.get('password')
        };

        try {
            const response = await fetch(`${API_URL}/auth/register`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify(data)
            });

            const result = await response.json();

            if (response.ok) {
                // Salvesta token
                localStorage.setItem('token', result.data.token);
                localStorage.setItem('user', JSON.stringify(result.data.user));

                showAlert('Registreerimine edukas! Suuname sind...', 'success');

                // Redirect
                setTimeout(() => {
                    window.location.href = 'dashboard.html';
                }, 1500);
            } else {
                // Näita vigu
                if (result.errors) {
                    result.errors.forEach(err => {
                        showAlert(err.message, 'error');
                    });
                } else {
                    showAlert(result.error || 'Registreerimine ebaõnnestus', 'error');
                }
            }
        } catch (error) {
            console.error('Error:', error);
            showAlert('Serveri viga. Proovi hiljem uuesti.', 'error');
        }
    });
}
```

---

## 8. Login Flow

```javascript
// Login
const loginForm = document.querySelector('#loginForm');

if (loginForm) {
    loginForm.addEventListener('submit', async (e) => {
        e.preventDefault();

        const formData = new FormData(loginForm);
        const data = {
            email: formData.get('email'),
            password: formData.get('password')
        };

        try {
            const response = await fetch(`${API_URL}/auth/login`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify(data)
            });

            const result = await response.json();

            if (response.ok) {
                // Salvesta token
                localStorage.setItem('token', result.data.token);
                localStorage.setItem('user', JSON.stringify(result.data.user));

                showAlert('Login edukas!', 'success');

                // Redirect
                setTimeout(() => {
                    window.location.href = 'dashboard.html';
                }, 1000);
            } else {
                showAlert(result.error || 'Login ebaõnnestus', 'error');
            }
        } catch (error) {
            console.error('Error:', error);
            showAlert('Serveri viga', 'error');
        }
    });
}
```

---

## 9. Protected Routes

```javascript
// Kontrolli autentimist
function checkAuth() {
    const token = localStorage.getItem('token');

    if (!token) {
        window.location.href = 'login.html';
        return false;
    }

    return true;
}

// Logout
function logout() {
    localStorage.removeItem('token');
    localStorage.removeItem('user');
    window.location.href = 'login.html';
}

// Lisa dashboard.html algusesse
if (window.location.pathname.includes('dashboard')) {
    if (!checkAuth()) {
        // Redirectitakse login'i
    }
}
```

---

## 10. Users Dashboard

**dashboard.html:**
```html
<!DOCTYPE html>
<html lang="et">
<head>
    <meta charset="UTF-8">
    <title>Dashboard</title>
    <link rel="stylesheet" href="css/styles.css">
</head>
<body>
    <header>
        <nav class="navbar">
            <div class="container">
                <h1 class="logo">Dashboard</h1>
                <ul class="nav-links">
                    <li><span id="userEmail"></span></li>
                    <li><a href="#" onclick="logout()">Logout</a></li>
                </ul>
            </div>
        </nav>
    </header>

    <main class="container">
        <h2>Kasutajad</h2>
        <div id="usersContainer"></div>
    </main>

    <script src="js/app.js"></script>
    <script src="js/dashboard.js"></script>
</body>
</html>
```

**js/dashboard.js:**
```javascript
// Kontrolli autentimist
if (!checkAuth()) {
    // Redirectitakse
}

// Näita kasutaja email
const user = JSON.parse(localStorage.getItem('user'));
document.querySelector('#userEmail').textContent = user.email;

// Lae kasutajad
async function loadUsers() {
    const token = localStorage.getItem('token');

    try {
        const response = await fetch(`${API_URL}/users`, {
            headers: {
                'Authorization': `Bearer ${token}`
            }
        });

        if (!response.ok) {
            if (response.status === 401) {
                // Token aegunud
                logout();
                return;
            }
            throw new Error('Failed to load users');
        }

        const result = await response.json();
        displayUsers(result.data);

    } catch (error) {
        console.error('Error:', error);
        showAlert('Kasutajate laadimine ebaõnnestus', 'error');
    }
}

// Näita kasutajaid
function displayUsers(users) {
    const container = document.querySelector('#usersContainer');

    const html = `
        <table class="users-table">
            <thead>
                <tr>
                    <th>ID</th>
                    <th>Nimi</th>
                    <th>Email</th>
                    <th>Roll</th>
                </tr>
            </thead>
            <tbody>
                ${users.map(user => `
                    <tr>
                        <td>${user.id}</td>
                        <td>${user.name}</td>
                        <td>${user.email}</td>
                        <td>${user.role}</td>
                    </tr>
                `).join('')}
            </tbody>
        </table>
    `;

    container.innerHTML = html;
}

// Lae kasutajad lehe laadimisel
loadUsers();
```

---

## 11. Harjutused

### Harjutus 10.1: Registration
1. Loo register.html vorm
2. Lisa JavaScript submit handler
3. Tee API päring POST /api/auth/register
4. Salvesta token localStorage'i

### Harjutus 10.2: Login
1. Loo login.html vorm
2. Lisa submit handler
3. Tee API päring POST /api/auth/login
4. Redirect dashboard'i

### Harjutus 10.3: Dashboard
1. Loo dashboard.html
2. Kontrolli autentimist
3. Lae kasutajad API-st
4. Näita tabelis

---

**Autor:** Koolituskava v1.0
**Kuupäev:** 2025-11-15
