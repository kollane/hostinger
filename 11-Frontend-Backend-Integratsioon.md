# Peatükk 11: Frontend ja Backend Integratsioon

**Kestus:** 3 tundi
**Eeldused:** Peatükid 1-10 läbitud
**Eesmärk:** Ühendada frontend ja backend täielikuks full-stack rakenduseks

---

## Sisukord

1. [Full-Stack Rakenduse Arhitektuur](#1-full-stack-rakenduse-arhitektuur)
2. [Backend CORS Seadistamine](#2-backend-cors-seadistamine)
3. [Static Files Serving](#3-static-files-serving)
4. [Complete Registration Flow](#4-complete-registration-flow)
5. [Complete Login Flow](#5-complete-login-flow)
6. [Protected Dashboard](#6-protected-dashboard)
7. [Profile Management](#7-profile-management)
8. [Password Change](#8-password-change)
9. [User List with Pagination](#9-user-list-with-pagination)
10. [Role-Based UI](#10-role-based-ui)
11. [Error Handling](#11-error-handling)
12. [Loading States](#12-loading-states)
13. [Production Deployment](#13-production-deployment)
14. [Harjutused](#14-harjutused)

---

## 1. Full-Stack Rakenduse Arhitektuur

### 1.1. Projekti Struktuur

```
user-management-app/
├── backend/
│   ├── server.js
│   ├── db.js
│   ├── routes/
│   │   ├── auth.js
│   │   └── users.js
│   ├── middleware/
│   │   └── auth.js
│   ├── package.json
│   └── .env
│
└── frontend/
    ├── index.html
    ├── register.html
    ├── login.html
    ├── dashboard.html
    ├── profile.html
    ├── css/
    │   └── styles.css
    └── js/
        ├── config.js
        ├── app.js
        ├── auth.js
        ├── dashboard.js
        └── profile.js
```

---

### 1.2. Data Flow

```
┌─────────────┐         HTTP          ┌─────────────┐
│             │  ──────────────────>  │             │
│  Frontend   │                       │   Backend   │
│ (HTML/CSS/  │  <────────────────── │   (Node.js/ │
│    JS)      │      JSON/JWT         │   Express)  │
│             │                       │             │
└─────────────┘                       └──────┬──────┘
                                             │
                                             │ SQL
                                             ▼
                                      ┌─────────────┐
                                      │ PostgreSQL  │
                                      │  Database   │
                                      └─────────────┘
```

---

## 2. Backend CORS Seadistamine

### 2.1. CORS Paigaldamine

```bash
cd backend
npm install cors
```

---

### 2.2. CORS Konfigureerimine

**backend/server.js:**
```javascript
const express = require('express');
const cors = require('cors');
const authRoutes = require('./routes/auth');
const userRoutes = require('./routes/users');

const app = express();

// CORS configuration
const corsOptions = {
  origin: process.env.FRONTEND_URL || 'http://localhost:8080',
  credentials: true,
  optionsSuccessStatus: 200
};

app.use(cors(corsOptions));
app.use(express.json());

// Routes
app.use('/api/auth', authRoutes);
app.use('/api/users', userRoutes);

// Error handler
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({
    success: false,
    error: 'Serveri viga'
  });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`✅ Server töötab pordil ${PORT}`);
});
```

---

### 2.3. .env Fail

**backend/.env:**
```bash
# Database
DATABASE_URL=postgresql://userapp:SecurePass123@localhost:5432/userappdb

# JWT
JWT_SECRET=your-super-secret-jwt-key-min-32-characters
JWT_EXPIRES_IN=24h

# Server
PORT=3000
NODE_ENV=development

# Frontend
FRONTEND_URL=http://localhost:8080
```

---

## 3. Static Files Serving

### 3.1. Variant 1: Eraldi Frontend Server

**Simple HTTP Server:**
```bash
cd frontend

# Python 3
python3 -m http.server 8080

# või Node.js
npx http-server -p 8080
```

---

### 3.2. Variant 2: Express Static Files

**backend/server.js:**
```javascript
const path = require('path');

// Serve static files
app.use(express.static(path.join(__dirname, '../frontend')));

// API routes
app.use('/api/auth', authRoutes);
app.use('/api/users', userRoutes);

// Catch-all route for SPA
app.get('*', (req, res) => {
  res.sendFile(path.join(__dirname, '../frontend/index.html'));
});
```

**Käivita:**
```bash
cd backend
node server.js
# Frontend on nüüd kättesaadav http://localhost:3000
```

---

## 4. Complete Registration Flow

### 4.1. Frontend Config

**frontend/js/config.js:**
```javascript
// API configuration
const API_CONFIG = {
  BASE_URL: 'http://localhost:3000/api',
  TIMEOUT: 10000
};

// Export for use in other files
if (typeof module !== 'undefined' && module.exports) {
  module.exports = API_CONFIG;
}
```

---

### 4.2. Registration Page

**frontend/register.html:**
```html
<!DOCTYPE html>
<html lang="et">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Registreerimine</title>
    <link rel="stylesheet" href="css/styles.css">
</head>
<body>
    <header>
        <nav class="navbar">
            <div class="container">
                <h1 class="logo">UserApp</h1>
                <ul class="nav-links">
                    <li><a href="index.html">Avaleht</a></li>
                    <li><a href="login.html">Login</a></li>
                    <li><a href="register.html">Register</a></li>
                </ul>
            </div>
        </nav>
    </header>

    <main class="container">
        <div class="form-container">
            <h2>Loo uus kasutaja</h2>

            <div id="alertContainer"></div>

            <form id="registerForm">
                <div class="form-group">
                    <label for="name">Nimi *</label>
                    <input
                        type="text"
                        id="name"
                        name="name"
                        required
                        minlength="2"
                        placeholder="Sisesta oma nimi">
                </div>

                <div class="form-group">
                    <label for="email">Email *</label>
                    <input
                        type="email"
                        id="email"
                        name="email"
                        required
                        placeholder="nimi@example.com">
                </div>

                <div class="form-group">
                    <label for="password">Parool *</label>
                    <input
                        type="password"
                        id="password"
                        name="password"
                        required
                        minlength="6"
                        placeholder="Vähemalt 6 tähemärki">
                    <small>Vähemalt 6 tähemärki</small>
                </div>

                <button type="submit" class="btn btn-primary" id="submitBtn">
                    Registreeru
                </button>
            </form>

            <p style="margin-top: 1rem; text-align: center;">
                Juba kasutaja? <a href="login.html">Logi sisse</a>
            </p>
        </div>
    </main>

    <script src="js/config.js"></script>
    <script src="js/app.js"></script>
    <script src="js/auth.js"></script>
</body>
</html>
```

---

### 4.3. Registration JavaScript

**frontend/js/auth.js:**
```javascript
// Registration handler
const registerForm = document.querySelector('#registerForm');

if (registerForm) {
    registerForm.addEventListener('submit', async (e) => {
        e.preventDefault();

        // Get form data
        const formData = new FormData(registerForm);
        const data = {
            name: formData.get('name').trim(),
            email: formData.get('email').trim(),
            password: formData.get('password')
        };

        // Validate
        if (data.name.length < 2) {
            showAlert('Nimi peab olema vähemalt 2 tähemärki', 'error');
            return;
        }

        if (data.password.length < 6) {
            showAlert('Parool peab olema vähemalt 6 tähemärki', 'error');
            return;
        }

        // Disable button
        const submitBtn = document.querySelector('#submitBtn');
        submitBtn.disabled = true;
        submitBtn.textContent = 'Registreerin...';

        try {
            const response = await fetch(`${API_CONFIG.BASE_URL}/auth/register`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify(data)
            });

            const result = await response.json();

            if (response.ok) {
                // Save token and user
                localStorage.setItem('token', result.data.token);
                localStorage.setItem('user', JSON.stringify(result.data.user));

                showAlert('Registreerimine edukas! Suuname sind...', 'success');

                // Redirect to dashboard
                setTimeout(() => {
                    window.location.href = 'dashboard.html';
                }, 1500);
            } else {
                // Show errors
                if (result.errors && Array.isArray(result.errors)) {
                    result.errors.forEach(err => {
                        showAlert(err.msg || err.message, 'error');
                    });
                } else {
                    showAlert(result.error || 'Registreerimine ebaõnnestus', 'error');
                }

                // Re-enable button
                submitBtn.disabled = false;
                submitBtn.textContent = 'Registreeru';
            }
        } catch (error) {
            console.error('Registration error:', error);
            showAlert('Serveri viga. Proovi hiljem uuesti.', 'error');

            // Re-enable button
            submitBtn.disabled = false;
            submitBtn.textContent = 'Registreeru';
        }
    });
}
```

---

## 5. Complete Login Flow

### 5.1. Login Page

**frontend/login.html:**
```html
<!DOCTYPE html>
<html lang="et">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Login</title>
    <link rel="stylesheet" href="css/styles.css">
</head>
<body>
    <header>
        <nav class="navbar">
            <div class="container">
                <h1 class="logo">UserApp</h1>
                <ul class="nav-links">
                    <li><a href="index.html">Avaleht</a></li>
                    <li><a href="login.html">Login</a></li>
                    <li><a href="register.html">Register</a></li>
                </ul>
            </div>
        </nav>
    </header>

    <main class="container">
        <div class="form-container">
            <h2>Logi sisse</h2>

            <div id="alertContainer"></div>

            <form id="loginForm">
                <div class="form-group">
                    <label for="email">Email</label>
                    <input
                        type="email"
                        id="email"
                        name="email"
                        required
                        placeholder="nimi@example.com">
                </div>

                <div class="form-group">
                    <label for="password">Parool</label>
                    <input
                        type="password"
                        id="password"
                        name="password"
                        required
                        placeholder="Sinu parool">
                </div>

                <button type="submit" class="btn btn-primary" id="loginBtn">
                    Logi sisse
                </button>
            </form>

            <p style="margin-top: 1rem; text-align: center;">
                Pole kasutajat? <a href="register.html">Registreeru</a>
            </p>
        </div>
    </main>

    <script src="js/config.js"></script>
    <script src="js/app.js"></script>
    <script>
        // Login handler
        const loginForm = document.querySelector('#loginForm');

        if (loginForm) {
            loginForm.addEventListener('submit', async (e) => {
                e.preventDefault();

                const formData = new FormData(loginForm);
                const data = {
                    email: formData.get('email').trim(),
                    password: formData.get('password')
                };

                const loginBtn = document.querySelector('#loginBtn');
                loginBtn.disabled = true;
                loginBtn.textContent = 'Sisenen...';

                try {
                    const response = await fetch(`${API_CONFIG.BASE_URL}/auth/login`, {
                        method: 'POST',
                        headers: {
                            'Content-Type': 'application/json'
                        },
                        body: JSON.stringify(data)
                    });

                    const result = await response.json();

                    if (response.ok) {
                        // Save token and user
                        localStorage.setItem('token', result.data.token);
                        localStorage.setItem('user', JSON.stringify(result.data.user));

                        showAlert('Login edukas!', 'success');

                        // Redirect
                        setTimeout(() => {
                            window.location.href = 'dashboard.html';
                        }, 1000);
                    } else {
                        showAlert(result.error || 'Login ebaõnnestus', 'error');
                        loginBtn.disabled = false;
                        loginBtn.textContent = 'Logi sisse';
                    }
                } catch (error) {
                    console.error('Login error:', error);
                    showAlert('Serveri viga', 'error');
                    loginBtn.disabled = false;
                    loginBtn.textContent = 'Logi sisse';
                }
            });
        }
    </script>
</body>
</html>
```

---

## 6. Protected Dashboard

### 6.1. Dashboard Page

**frontend/dashboard.html:**
```html
<!DOCTYPE html>
<html lang="et">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Dashboard</title>
    <link rel="stylesheet" href="css/styles.css">
</head>
<body>
    <header>
        <nav class="navbar">
            <div class="container">
                <h1 class="logo">UserApp Dashboard</h1>
                <ul class="nav-links">
                    <li><span id="userEmail" class="user-email"></span></li>
                    <li><a href="profile.html">Profiil</a></li>
                    <li><a href="#" onclick="logout()">Logout</a></li>
                </ul>
            </div>
        </nav>
    </header>

    <main class="container">
        <div class="dashboard-header">
            <h2>Tere, <span id="userName"></span>!</h2>
            <p>Roll: <span id="userRole" class="badge"></span></p>
        </div>

        <div id="alertContainer"></div>

        <section class="users-section">
            <div class="section-header">
                <h3>Kasutajad</h3>
                <div class="filters">
                    <input
                        type="text"
                        id="searchInput"
                        placeholder="Otsi nime või emaili järgi..."
                        class="search-input">
                    <select id="roleFilter" class="filter-select">
                        <option value="">Kõik rollid</option>
                        <option value="user">User</option>
                        <option value="admin">Admin</option>
                    </select>
                </div>
            </div>

            <div id="loadingSpinner" class="loading-spinner" style="display: none;">
                Laen andmeid...
            </div>

            <div id="usersContainer"></div>

            <div id="paginationContainer" class="pagination"></div>
        </section>
    </main>

    <script src="js/config.js"></script>
    <script src="js/app.js"></script>
    <script src="js/dashboard.js"></script>
</body>
</html>
```

---

### 6.2. Dashboard JavaScript

**frontend/js/dashboard.js:**
```javascript
// Check authentication
if (!checkAuth()) {
    // Will redirect to login
}

// Get current user
const currentUser = JSON.parse(localStorage.getItem('user'));
document.querySelector('#userName').textContent = currentUser.name;
document.querySelector('#userEmail').textContent = currentUser.email;
document.querySelector('#userRole').textContent = currentUser.role.toUpperCase();

// Pagination state
let currentPage = 1;
let currentSearch = '';
let currentRoleFilter = '';

// Load users
async function loadUsers(page = 1, search = '', role = '') {
    const token = localStorage.getItem('token');

    // Show loading
    showLoading(true);

    try {
        // Build query params
        const params = new URLSearchParams({
            page: page,
            limit: 10
        });

        if (search) params.append('search', search);
        if (role) params.append('role', role);

        const response = await fetch(`${API_CONFIG.BASE_URL}/users?${params}`, {
            headers: {
                'Authorization': `Bearer ${token}`
            }
        });

        if (!response.ok) {
            if (response.status === 401) {
                // Token expired
                logout();
                return;
            }
            throw new Error('Failed to load users');
        }

        const result = await response.json();

        displayUsers(result.data);
        displayPagination(result.pagination);

    } catch (error) {
        console.error('Error loading users:', error);
        showAlert('Kasutajate laadimine ebaõnnestus', 'error');
    } finally {
        showLoading(false);
    }
}

// Display users table
function displayUsers(users) {
    const container = document.querySelector('#usersContainer');

    if (!users || users.length === 0) {
        container.innerHTML = '<p class="no-data">Kasutajaid ei leitud</p>';
        return;
    }

    const html = `
        <table class="users-table">
            <thead>
                <tr>
                    <th>ID</th>
                    <th>Nimi</th>
                    <th>Email</th>
                    <th>Roll</th>
                    <th>Loodud</th>
                </tr>
            </thead>
            <tbody>
                ${users.map(user => `
                    <tr>
                        <td>${user.id}</td>
                        <td>${escapeHtml(user.name)}</td>
                        <td>${escapeHtml(user.email)}</td>
                        <td><span class="badge badge-${user.role}">${user.role}</span></td>
                        <td>${formatDate(user.created_at)}</td>
                    </tr>
                `).join('')}
            </tbody>
        </table>
    `;

    container.innerHTML = html;
}

// Display pagination
function displayPagination(pagination) {
    const container = document.querySelector('#paginationContainer');

    if (!pagination || pagination.totalPages <= 1) {
        container.innerHTML = '';
        return;
    }

    const { page, totalPages } = pagination;
    let html = '<div class="pagination-buttons">';

    // Previous button
    if (page > 1) {
        html += `<button onclick="changePage(${page - 1})" class="btn btn-secondary">← Eelmine</button>`;
    }

    // Page info
    html += `<span class="page-info">Lehekülg ${page} / ${totalPages}</span>`;

    // Next button
    if (page < totalPages) {
        html += `<button onclick="changePage(${page + 1})" class="btn btn-secondary">Järgmine →</button>`;
    }

    html += '</div>';
    container.innerHTML = html;
}

// Change page
function changePage(page) {
    currentPage = page;
    loadUsers(currentPage, currentSearch, currentRoleFilter);
}

// Search handler
const searchInput = document.querySelector('#searchInput');
if (searchInput) {
    searchInput.addEventListener('input', debounce((e) => {
        currentSearch = e.target.value;
        currentPage = 1;
        loadUsers(currentPage, currentSearch, currentRoleFilter);
    }, 500));
}

// Role filter handler
const roleFilter = document.querySelector('#roleFilter');
if (roleFilter) {
    roleFilter.addEventListener('change', (e) => {
        currentRoleFilter = e.target.value;
        currentPage = 1;
        loadUsers(currentPage, currentSearch, currentRoleFilter);
    });
}

// Helper: Debounce
function debounce(func, wait) {
    let timeout;
    return function executedFunction(...args) {
        const later = () => {
            clearTimeout(timeout);
            func(...args);
        };
        clearTimeout(timeout);
        timeout = setTimeout(later, wait);
    };
}

// Helper: Show loading
function showLoading(show) {
    const spinner = document.querySelector('#loadingSpinner');
    if (spinner) {
        spinner.style.display = show ? 'block' : 'none';
    }
}

// Helper: Format date
function formatDate(dateString) {
    const date = new Date(dateString);
    return date.toLocaleDateString('et-EE', {
        year: 'numeric',
        month: '2-digit',
        day: '2-digit'
    });
}

// Initial load
loadUsers();
```

---

## 7. Profile Management

### 7.1. Profile Page

**frontend/profile.html:**
```html
<!DOCTYPE html>
<html lang="et">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Profiil</title>
    <link rel="stylesheet" href="css/styles.css">
</head>
<body>
    <header>
        <nav class="navbar">
            <div class="container">
                <h1 class="logo">UserApp</h1>
                <ul class="nav-links">
                    <li><a href="dashboard.html">Dashboard</a></li>
                    <li><a href="profile.html">Profiil</a></li>
                    <li><a href="#" onclick="logout()">Logout</a></li>
                </ul>
            </div>
        </nav>
    </header>

    <main class="container">
        <h2>Minu Profiil</h2>

        <div id="alertContainer"></div>

        <div class="profile-grid">
            <!-- Update Profile -->
            <div class="card">
                <h3>Uuenda Profiili</h3>
                <form id="updateProfileForm">
                    <div class="form-group">
                        <label for="name">Nimi</label>
                        <input type="text" id="name" name="name" required>
                    </div>

                    <div class="form-group">
                        <label for="email">Email</label>
                        <input type="email" id="email" name="email" required>
                    </div>

                    <button type="submit" class="btn btn-primary">
                        Salvesta Muudatused
                    </button>
                </form>
            </div>

            <!-- Change Password -->
            <div class="card">
                <h3>Muuda Parooli</h3>
                <form id="changePasswordForm">
                    <div class="form-group">
                        <label for="currentPassword">Praegune Parool</label>
                        <input type="password" id="currentPassword" name="currentPassword" required>
                    </div>

                    <div class="form-group">
                        <label for="newPassword">Uus Parool</label>
                        <input type="password" id="newPassword" name="newPassword" required minlength="6">
                    </div>

                    <div class="form-group">
                        <label for="confirmPassword">Kinnita Uus Parool</label>
                        <input type="password" id="confirmPassword" name="confirmPassword" required>
                    </div>

                    <button type="submit" class="btn btn-primary">
                        Muuda Parooli
                    </button>
                </form>
            </div>
        </div>
    </main>

    <script src="js/config.js"></script>
    <script src="js/app.js"></script>
    <script src="js/profile.js"></script>
</body>
</html>
```

---

### 7.2. Profile JavaScript

**frontend/js/profile.js:**
```javascript
// Check authentication
if (!checkAuth()) {
    // Redirects to login
}

// Load current user data
const currentUser = JSON.parse(localStorage.getItem('user'));
document.querySelector('#name').value = currentUser.name;
document.querySelector('#email').value = currentUser.email;

// Update profile handler
const updateProfileForm = document.querySelector('#updateProfileForm');
if (updateProfileForm) {
    updateProfileForm.addEventListener('submit', async (e) => {
        e.preventDefault();

        const formData = new FormData(updateProfileForm);
        const data = {
            name: formData.get('name').trim(),
            email: formData.get('email').trim()
        };

        const token = localStorage.getItem('token');

        try {
            const response = await fetch(`${API_CONFIG.BASE_URL}/users/me`, {
                method: 'PUT',
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': `Bearer ${token}`
                },
                body: JSON.stringify(data)
            });

            const result = await response.json();

            if (response.ok) {
                // Update localStorage
                const updatedUser = { ...currentUser, ...result.data };
                localStorage.setItem('user', JSON.stringify(updatedUser));

                showAlert('Profiil uuendatud!', 'success');
            } else {
                if (result.errors) {
                    result.errors.forEach(err => {
                        showAlert(err.msg || err.message, 'error');
                    });
                } else {
                    showAlert(result.error || 'Uuendamine ebaõnnestus', 'error');
                }
            }
        } catch (error) {
            console.error('Error updating profile:', error);
            showAlert('Serveri viga', 'error');
        }
    });
}

// Change password handler
const changePasswordForm = document.querySelector('#changePasswordForm');
if (changePasswordForm) {
    changePasswordForm.addEventListener('submit', async (e) => {
        e.preventDefault();

        const formData = new FormData(changePasswordForm);
        const currentPassword = formData.get('currentPassword');
        const newPassword = formData.get('newPassword');
        const confirmPassword = formData.get('confirmPassword');

        // Validate
        if (newPassword !== confirmPassword) {
            showAlert('Uued paroolid ei kattu', 'error');
            return;
        }

        if (newPassword.length < 6) {
            showAlert('Parool peab olema vähemalt 6 tähemärki', 'error');
            return;
        }

        const token = localStorage.getItem('token');

        try {
            const response = await fetch(`${API_CONFIG.BASE_URL}/users/me/password`, {
                method: 'PUT',
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': `Bearer ${token}`
                },
                body: JSON.stringify({
                    currentPassword,
                    newPassword
                })
            });

            const result = await response.json();

            if (response.ok) {
                showAlert('Parool muudetud!', 'success');
                changePasswordForm.reset();
            } else {
                showAlert(result.error || 'Parooli muutmine ebaõnnestus', 'error');
            }
        } catch (error) {
            console.error('Error changing password:', error);
            showAlert('Serveri viga', 'error');
        }
    });
}
```

---

## 8. Password Change

### 8.1. Backend Endpoint

**backend/routes/users.js:**
```javascript
const express = require('express');
const router = express.Router();
const bcrypt = require('bcrypt');
const pool = require('../db');
const { authenticate } = require('../middleware/auth');

// Change password
router.put('/me/password', authenticate, async (req, res, next) => {
    try {
        const { currentPassword, newPassword } = req.body;
        const userId = req.user.userId;

        // Validate
        if (!currentPassword || !newPassword) {
            return res.status(400).json({
                success: false,
                error: 'Kõik väljad on kohustuslikud'
            });
        }

        if (newPassword.length < 6) {
            return res.status(400).json({
                success: false,
                error: 'Uus parool peab olema vähemalt 6 tähemärki'
            });
        }

        // Get current user
        const userResult = await pool.query(
            'SELECT password FROM users WHERE id = $1',
            [userId]
        );

        if (userResult.rows.length === 0) {
            return res.status(404).json({
                success: false,
                error: 'Kasutajat ei leitud'
            });
        }

        const user = userResult.rows[0];

        // Verify current password
        const isMatch = await bcrypt.compare(currentPassword, user.password);
        if (!isMatch) {
            return res.status(401).json({
                success: false,
                error: 'Praegune parool on vale'
            });
        }

        // Hash new password
        const hashedPassword = await bcrypt.hash(newPassword, 10);

        // Update password
        await pool.query(
            'UPDATE users SET password = $1, updated_at = CURRENT_TIMESTAMP WHERE id = $2',
            [hashedPassword, userId]
        );

        res.json({
            success: true,
            message: 'Parool edukalt muudetud'
        });

    } catch (error) {
        next(error);
    }
});

module.exports = router;
```

---

## 9. User List with Pagination

### 9.1. Backend Endpoint with Search and Filter

**backend/routes/users.js:**
```javascript
// Get all users (with pagination, search, filter)
router.get('/', authenticate, async (req, res, next) => {
    try {
        const page = parseInt(req.query.page) || 1;
        const limit = parseInt(req.query.limit) || 10;
        const offset = (page - 1) * limit;
        const search = req.query.search || '';
        const role = req.query.role || '';

        // Build query
        let queryText = `
            SELECT id, name, email, role, created_at, updated_at
            FROM users
            WHERE 1=1
        `;

        const queryParams = [];
        let paramCount = 0;

        // Add search
        if (search) {
            paramCount++;
            queryText += ` AND (name ILIKE $${paramCount} OR email ILIKE $${paramCount})`;
            queryParams.push(`%${search}%`);
        }

        // Add role filter
        if (role) {
            paramCount++;
            queryText += ` AND role = $${paramCount}`;
            queryParams.push(role);
        }

        // Add ordering
        queryText += ' ORDER BY id';

        // Count total
        const countQuery = `SELECT COUNT(*) FROM users WHERE 1=1` +
            (search ? ` AND (name ILIKE $1 OR email ILIKE $1)` : '') +
            (role ? ` AND role = $${search ? 2 : 1}` : '');

        const countParams = [];
        if (search) countParams.push(`%${search}%`);
        if (role) countParams.push(role);

        const countResult = await pool.query(countQuery, countParams);
        const totalCount = parseInt(countResult.rows[0].count);

        // Add pagination
        queryText += ` LIMIT $${paramCount + 1} OFFSET $${paramCount + 2}`;
        queryParams.push(limit, offset);

        // Execute query
        const result = await pool.query(queryText, queryParams);

        res.json({
            success: true,
            data: result.rows,
            pagination: {
                page,
                limit,
                totalCount,
                totalPages: Math.ceil(totalCount / limit)
            }
        });

    } catch (error) {
        next(error);
    }
});
```

---

## 10. Role-Based UI

### 10.1. Admin-Only Features

**frontend/js/dashboard.js** (lisa):
```javascript
// Show admin features only to admins
function initializeAdminFeatures() {
    const currentUser = JSON.parse(localStorage.getItem('user'));

    if (currentUser.role === 'admin') {
        // Show admin-only sections
        const adminSections = document.querySelectorAll('.admin-only');
        adminSections.forEach(section => {
            section.style.display = 'block';
        });

        // Enable delete buttons
        enableDeleteButtons();
    }
}

// Delete user (admin only)
async function deleteUser(userId) {
    if (!confirm('Kas oled kindel, et soovid selle kasutaja kustutada?')) {
        return;
    }

    const token = localStorage.getItem('token');

    try {
        const response = await fetch(`${API_CONFIG.BASE_URL}/users/${userId}`, {
            method: 'DELETE',
            headers: {
                'Authorization': `Bearer ${token}`
            }
        });

        if (response.ok) {
            showAlert('Kasutaja kustutatud', 'success');
            loadUsers(currentPage, currentSearch, currentRoleFilter);
        } else {
            const result = await response.json();
            showAlert(result.error || 'Kustutamine ebaõnnestus', 'error');
        }
    } catch (error) {
        console.error('Error deleting user:', error);
        showAlert('Serveri viga', 'error');
    }
}

// Call on page load
initializeAdminFeatures();
```

---

### 10.2. Admin HTML

**frontend/dashboard.html** (lisa tabelisse):
```html
<table class="users-table">
    <thead>
        <tr>
            <th>ID</th>
            <th>Nimi</th>
            <th>Email</th>
            <th>Roll</th>
            <th>Loodud</th>
            <th class="admin-only" style="display: none;">Tegevused</th>
        </tr>
    </thead>
    <tbody>
        ${users.map(user => `
            <tr>
                <td>${user.id}</td>
                <td>${escapeHtml(user.name)}</td>
                <td>${escapeHtml(user.email)}</td>
                <td><span class="badge badge-${user.role}">${user.role}</span></td>
                <td>${formatDate(user.created_at)}</td>
                <td class="admin-only" style="display: none;">
                    <button
                        onclick="deleteUser(${user.id})"
                        class="btn btn-danger btn-sm">
                        Kustuta
                    </button>
                </td>
            </tr>
        `).join('')}
    </tbody>
</table>
```

---

## 11. Error Handling

### 11.1. Global Error Handler

**frontend/js/app.js:**
```javascript
// Global fetch wrapper with error handling
async function apiFetch(url, options = {}) {
    try {
        const token = localStorage.getItem('token');

        const defaultOptions = {
            headers: {
                'Content-Type': 'application/json',
                ...(token && { 'Authorization': `Bearer ${token}` })
            }
        };

        const mergedOptions = {
            ...defaultOptions,
            ...options,
            headers: {
                ...defaultOptions.headers,
                ...options.headers
            }
        };

        const response = await fetch(url, mergedOptions);

        // Handle 401 Unauthorized
        if (response.status === 401) {
            logout();
            throw new Error('Session expired');
        }

        const data = await response.json();

        if (!response.ok) {
            throw new Error(data.error || 'Request failed');
        }

        return data;

    } catch (error) {
        console.error('API Error:', error);
        throw error;
    }
}

// Usage example:
// const data = await apiFetch(`${API_CONFIG.BASE_URL}/users`);
```

---

### 11.2. Form Validation

**frontend/js/app.js:**
```javascript
// Validate email
function isValidEmail(email) {
    const re = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return re.test(email);
}

// Validate password strength
function isStrongPassword(password) {
    // At least 6 characters, 1 number, 1 letter
    return password.length >= 6 &&
           /[0-9]/.test(password) &&
           /[a-zA-Z]/.test(password);
}

// Show field error
function showFieldError(inputId, message) {
    const input = document.querySelector(`#${inputId}`);
    const formGroup = input.closest('.form-group');

    // Remove previous error
    const existingError = formGroup.querySelector('.field-error');
    if (existingError) {
        existingError.remove();
    }

    // Add error
    const error = document.createElement('small');
    error.className = 'field-error';
    error.style.color = 'red';
    error.textContent = message;
    formGroup.appendChild(error);

    // Add error class to input
    input.classList.add('input-error');
}

// Clear field error
function clearFieldError(inputId) {
    const input = document.querySelector(`#${inputId}`);
    const formGroup = input.closest('.form-group');
    const error = formGroup.querySelector('.field-error');
    if (error) {
        error.remove();
    }
    input.classList.remove('input-error');
}
```

---

## 12. Loading States

### 12.1. Loading Spinner CSS

**frontend/css/styles.css** (lisa):
```css
/* Loading States */
.loading-spinner {
    text-align: center;
    padding: 2rem;
    color: #666;
}

.loading-spinner::after {
    content: '';
    display: inline-block;
    width: 30px;
    height: 30px;
    border: 3px solid #f3f3f3;
    border-top: 3px solid #3498db;
    border-radius: 50%;
    animation: spin 1s linear infinite;
    margin-left: 10px;
}

@keyframes spin {
    0% { transform: rotate(0deg); }
    100% { transform: rotate(360deg); }
}

/* Disabled button state */
button:disabled {
    opacity: 0.6;
    cursor: not-allowed;
}

/* Skeleton loading */
.skeleton {
    background: linear-gradient(90deg, #f0f0f0 25%, #e0e0e0 50%, #f0f0f0 75%);
    background-size: 200% 100%;
    animation: skeleton-loading 1.5s infinite;
}

@keyframes skeleton-loading {
    0% { background-position: 200% 0; }
    100% { background-position: -200% 0; }
}
```

---

### 12.2. Button Loading State

**frontend/js/app.js:**
```javascript
// Set button loading state
function setButtonLoading(button, loading, originalText = 'Submit') {
    if (loading) {
        button.disabled = true;
        button.dataset.originalText = button.textContent;
        button.textContent = 'Laen...';
    } else {
        button.disabled = false;
        button.textContent = button.dataset.originalText || originalText;
    }
}

// Usage:
// const btn = document.querySelector('#submitBtn');
// setButtonLoading(btn, true);
// ... do async work ...
// setButtonLoading(btn, false);
```

---

## 13. Production Deployment

### 13.1. Environment Variables

**backend/.env.production:**
```bash
NODE_ENV=production

# Database (External PostgreSQL or Docker)
DATABASE_URL=postgresql://userapp:SecurePass123@db.example.com:5432/userappdb

# JWT
JWT_SECRET=your-production-super-secret-key-min-32-characters-long
JWT_EXPIRES_IN=24h

# Server
PORT=3000

# Frontend
FRONTEND_URL=https://yourdomain.com

# CORS
CORS_ORIGIN=https://yourdomain.com
```

---

### 13.2. Production Build Script

**backend/package.json:**
```json
{
  "scripts": {
    "start": "node server.js",
    "dev": "nodemon server.js",
    "prod": "NODE_ENV=production node server.js"
  }
}
```

---

### 13.3. Frontend Production Config

**frontend/js/config.js:**
```javascript
// Auto-detect environment
const API_CONFIG = {
    BASE_URL: window.location.hostname === 'localhost'
        ? 'http://localhost:3000/api'
        : 'https://api.yourdomain.com/api',
    TIMEOUT: 10000
};
```

---

### 13.4. nginx Reverse Proxy

**nginx konfigureerimine:**
```nginx
# Backend API
server {
    listen 80;
    server_name api.yourdomain.com;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}

# Frontend Static Files
server {
    listen 80;
    server_name yourdomain.com www.yourdomain.com;

    root /var/www/frontend;
    index index.html;

    location / {
        try_files $uri $uri/ /index.html;
    }

    # Cache static assets
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
```

---

### 13.5. Deploy Frontend

```bash
# Kopeeri frontend failid serverisse
scp -r frontend/* user@your-server:/var/www/frontend/

# või kasuta rsync
rsync -avz --delete frontend/ user@your-server:/var/www/frontend/
```

---

### 13.6. PM2 Process Manager

```bash
# Paigalda PM2
npm install -g pm2

# Käivita backend
cd backend
pm2 start server.js --name "userapp-api"

# Salvesta PM2 config
pm2 save

# Auto-start on reboot
pm2 startup
```

---

## 14. Harjutused

### Harjutus 11.1: Full-Stack Setup
1. Seadista backend CORS
2. Käivita frontend HTTP serveriga
3. Testi registration flow end-to-end

### Harjutus 11.2: Dashboard Implementation
1. Loo protected dashboard
2. Lisa kasutajate tabel paginationiga
3. Implementeeri search ja filter

### Harjutus 11.3: Profile Management
1. Loo profile page
2. Implementeeri profiili uuendamine
3. Lisa parooli muutmise funktsioon

### Harjutus 11.4: Role-Based UI
1. Lisa admin-only features
2. Implementeeri kasutaja kustutamine (admin)
3. Peida admin funktsioonid tavakasutajatelt

### Harjutus 11.5: Production Deployment
1. Seadista nginx reverse proxy
2. Kasuta PM2 backend jaoks
3. Deploy frontend static failid

---

## Quiz

**1. Mis on CORS ja miks seda vajatakse?**
- a) Database connection pool
- b) Cross-Origin Resource Sharing - lubab API päringuid erinevalt origin'ilt
- c) CSS framework
- d) Authentication method

<details>
<summary>Vastus</summary>
b) CORS (Cross-Origin Resource Sharing) lubab brauseril teha API päringuid erinevalt origin'ilt (nt frontend localhost:8080 → backend localhost:3000)
</details>

---

**2. Kus hoitakse JWT token'it frontend'is?**
- a) Cookies
- b) SessionStorage
- c) LocalStorage
- d) Backend database

<details>
<summary>Vastus</summary>
c) LocalStorage on kõige tavalisem koht (või SessionStorage, kui ei soovi persistence'i)
</details>

---

**3. Kuidas kaitstakse protected route'e frontend'is?**
- a) Kontrolli localStorage token'i olemasolu
- b) Kontrolli password'i
- c) Kasuta HTTPS
- d) Kasuta cookies

<details>
<summary>Vastus</summary>
a) Kontrolli, kas localStorage sisaldab valid token'it, ja redirect login'i kui ei ole
</details>

---

**4. Mis on debouncing search input'i puhul?**
- a) Delay enne API päringu tegemist
- b) Error handling
- c) Pagination
- d) Authentication

<details>
<summary>Vastus</summary>
a) Debouncing viivitab API päringu tegemist kuni kasutaja lõpetab trükkimise (nt 500ms delay)
</details>

---

**5. Kuidas käsitleda JWT token expiration'it?**
- a) Ignore error
- b) Kontrolli 401 response ja redirect login'i
- c) Salvesta uus token cookies
- d) Kasuta session storage

<details>
<summary>Vastus</summary>
b) Kui server tagastab 401 Unauthorized, tähendab see token'i expiration'it → kustuta token ja redirect login'i
</details>

---

## Kokkuvõte

Selles peatükis õppisid:

✅ **Full-stack integratsiooni:**
- Frontend ja backend ühendamine
- CORS seadistamine
- Static files serving

✅ **Complete User Flows:**
- Registration → Login → Dashboard
- Token management LocalStorage'is
- Protected routes

✅ **Advanced Features:**
- Profile update
- Password change
- Pagination, search, filtering
- Role-based UI (admin features)

✅ **Production Deployment:**
- Environment variables
- nginx reverse proxy
- PM2 process manager
- Frontend static files serving

---

**Järgmine peatükk:** Docker põhimõtted - konteinerisatsioon ja mikroteenused

---

**Autor:** Koolituskava v1.0
**Kuupäev:** 2025-11-15
