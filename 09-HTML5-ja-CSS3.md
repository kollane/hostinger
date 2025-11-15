# Peatükk 9: HTML5 ja CSS3 Alused

**Kestus:** 3 tundi
**Eeldused:** Peatükid 1-8 läbitud
**Eesmärk:** Õppida HTML5 ja CSS3 põhitõed ning luua frontend API jaoks

---

## Sisukord

1. [HTML5 Ülevaade](#1-html5-ülevaade)
2. [HTML Struktuur](#2-html-struktuur)
3. [Semantic HTML](#3-semantic-html)
4. [HTML Forms](#4-html-forms)
5. [CSS3 Ülevaade](#5-css3-ülevaade)
6. [CSS Selectors](#6-css-selectors)
7. [Box Model](#7-box-model)
8. [Flexbox](#8-flexbox)
9. [CSS Grid](#9-css-grid)
10. [Responsive Design](#10-responsive-design)
11. [Frontend Projekt](#11-frontend-projekt)
12. [Harjutused](#12-harjutused)

---

## 1. HTML5 Ülevaade

### 1.1. Mis on HTML?

**HTML (HyperText Markup Language)** on veebilehtede struktuuri märgistuskeel.

```html
<!DOCTYPE html>
<html lang="et">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Minu Esimene Leht</title>
</head>
<body>
    <h1>Tere, maailm!</h1>
    <p>See on minu esimene veebileht.</p>
</body>
</html>
```

---

## 2. HTML Struktuur

### 2.1. Põhielemendid

```html
<!-- Pealkirjad -->
<h1>Pealkiri 1 (kõige olulisem)</h1>
<h2>Pealkiri 2</h2>
<h3>Pealkiri 3</h3>

<!-- Paragrahvid -->
<p>See on lõik teksti.</p>

<!-- Lingid -->
<a href="https://example.com">Link</a>

<!-- Pildid -->
<img src="image.jpg" alt="Kirjeldus">

<!-- Nimekirjad -->
<ul>
    <li>Esimene punkt</li>
    <li>Teine punkt</li>
</ul>

<ol>
    <li>Esimene</li>
    <li>Teine</li>
</ol>

<!-- Div ja Span -->
<div>Block element</div>
<span>Inline element</span>
```

---

## 3. Semantic HTML

```html
<header>
    <nav>
        <ul>
            <li><a href="#home">Avaleht</a></li>
            <li><a href="#about">Meist</a></li>
        </ul>
    </nav>
</header>

<main>
    <article>
        <h1>Artikli pealkiri</h1>
        <p>Sisu...</p>
    </article>

    <aside>
        <h2>Külgpaneel</h2>
    </aside>
</main>

<footer>
    <p>&copy; 2025 Ettevõte</p>
</footer>
```

---

## 4. HTML Forms

```html
<form action="/api/auth/register" method="POST">
    <!-- Text input -->
    <label for="name">Nimi:</label>
    <input type="text" id="name" name="name" required>

    <!-- Email input -->
    <label for="email">Email:</label>
    <input type="email" id="email" name="email" required>

    <!-- Password input -->
    <label for="password">Parool:</label>
    <input type="password" id="password" name="password" required>

    <!-- Submit button -->
    <button type="submit">Registreeru</button>
</form>
```

---

## 5. CSS3 Ülevaade

### 5.1. CSS Lisamine

**Inline:**
```html
<p style="color: red;">Punane tekst</p>
```

**Internal:**
```html
<head>
    <style>
        p { color: red; }
    </style>
</head>
```

**External (SOOVITAV):**
```html
<head>
    <link rel="stylesheet" href="styles.css">
</head>
```

---

## 6. CSS Selectors

```css
/* Element selector */
p {
    color: blue;
}

/* Class selector */
.container {
    max-width: 1200px;
    margin: 0 auto;
}

/* ID selector */
#header {
    background-color: navy;
}

/* Descendant */
.container p {
    line-height: 1.6;
}

/* Child */
ul > li {
    list-style: none;
}

/* Hover */
a:hover {
    text-decoration: underline;
}

/* Pseudo-classes */
input:focus {
    border-color: blue;
}

li:nth-child(odd) {
    background-color: #f0f0f0;
}
```

---

## 7. Box Model

```css
.box {
    /* Content */
    width: 300px;
    height: 200px;

    /* Padding (sisemine vahe) */
    padding: 20px;

    /* Border */
    border: 2px solid #333;

    /* Margin (väline vahe) */
    margin: 10px;

    /* Box-sizing */
    box-sizing: border-box; /* Soovitav! */
}
```

---

## 8. Flexbox

```css
.container {
    display: flex;
    justify-content: space-between; /* Horizontal alignment */
    align-items: center;             /* Vertical alignment */
    gap: 20px;                       /* Space between items */
}

.item {
    flex: 1; /* Võrdne laius */
}
```

**Näide:**
```html
<div class="container">
    <div class="item">1</div>
    <div class="item">2</div>
    <div class="item">3</div>
</div>
```

---

## 9. CSS Grid

```css
.grid {
    display: grid;
    grid-template-columns: repeat(3, 1fr); /* 3 võrdset column */
    gap: 20px;
}

@media (max-width: 768px) {
    .grid {
        grid-template-columns: 1fr; /* Mobile: 1 column */
    }
}
```

---

## 10. Responsive Design

```css
/* Mobile-first approach */
.container {
    width: 100%;
    padding: 10px;
}

/* Tablet */
@media (min-width: 768px) {
    .container {
        max-width: 720px;
        margin: 0 auto;
    }
}

/* Desktop */
@media (min-width: 1200px) {
    .container {
        max-width: 1140px;
    }
}
```

---

## 11. Frontend Projekt

### 11.1. Projekti Struktuur

```
frontend/
├── index.html
├── register.html
├── login.html
├── dashboard.html
├── css/
│   └── styles.css
└── js/
    └── app.js
```

---

### 11.2. index.html

```html
<!DOCTYPE html>
<html lang="et">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Kasutajate Haldus</title>
    <link rel="stylesheet" href="css/styles.css">
</head>
<body>
    <header>
        <nav class="navbar">
            <div class="container">
                <h1 class="logo">Kasutajate API</h1>
                <ul class="nav-links">
                    <li><a href="index.html">Avaleht</a></li>
                    <li><a href="login.html">Login</a></li>
                    <li><a href="register.html">Register</a></li>
                </ul>
            </div>
        </nav>
    </header>

    <main class="container">
        <section class="hero">
            <h1>Tere tulemast!</h1>
            <p>Kasutajate halduse rakendus REST API-ga</p>
            <div class="cta-buttons">
                <a href="register.html" class="btn btn-primary">Registreeru</a>
                <a href="login.html" class="btn btn-secondary">Logi sisse</a>
            </div>
        </section>
    </main>

    <footer>
        <p>&copy; 2025 Kasutajate API</p>
    </footer>
</body>
</html>
```

---

### 11.3. styles.css

```css
/* Reset */
* {
    margin: 0;
    padding: 0;
    box-sizing: border-box;
}

body {
    font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
    line-height: 1.6;
    color: #333;
}

/* Container */
.container {
    max-width: 1200px;
    margin: 0 auto;
    padding: 0 20px;
}

/* Navbar */
.navbar {
    background-color: #2c3e50;
    color: white;
    padding: 1rem 0;
}

.navbar .container {
    display: flex;
    justify-content: space-between;
    align-items: center;
}

.logo {
    font-size: 1.5rem;
}

.nav-links {
    display: flex;
    list-style: none;
    gap: 2rem;
}

.nav-links a {
    color: white;
    text-decoration: none;
    transition: color 0.3s;
}

.nav-links a:hover {
    color: #3498db;
}

/* Hero Section */
.hero {
    text-align: center;
    padding: 4rem 0;
}

.hero h1 {
    font-size: 2.5rem;
    margin-bottom: 1rem;
}

.cta-buttons {
    margin-top: 2rem;
    display: flex;
    gap: 1rem;
    justify-content: center;
}

/* Buttons */
.btn {
    display: inline-block;
    padding: 0.75rem 2rem;
    text-decoration: none;
    border-radius: 5px;
    transition: all 0.3s;
}

.btn-primary {
    background-color: #3498db;
    color: white;
}

.btn-primary:hover {
    background-color: #2980b9;
}

.btn-secondary {
    background-color: #95a5a6;
    color: white;
}

.btn-secondary:hover {
    background-color: #7f8c8d;
}

/* Forms */
.form-container {
    max-width: 500px;
    margin: 2rem auto;
    padding: 2rem;
    background-color: #f9f9f9;
    border-radius: 8px;
    box-shadow: 0 2px 10px rgba(0,0,0,0.1);
}

.form-group {
    margin-bottom: 1.5rem;
}

.form-group label {
    display: block;
    margin-bottom: 0.5rem;
    font-weight: 600;
}

.form-group input {
    width: 100%;
    padding: 0.75rem;
    border: 1px solid #ddd;
    border-radius: 4px;
    font-size: 1rem;
}

.form-group input:focus {
    outline: none;
    border-color: #3498db;
}

/* Footer */
footer {
    background-color: #2c3e50;
    color: white;
    text-align: center;
    padding: 2rem 0;
    margin-top: 4rem;
}

/* Responsive */
@media (max-width: 768px) {
    .navbar .container {
        flex-direction: column;
        gap: 1rem;
    }

    .nav-links {
        flex-direction: column;
        gap: 1rem;
    }

    .cta-buttons {
        flex-direction: column;
    }
}
```

---

### 11.4. register.html

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
                <h1 class="logo">Kasutajate API</h1>
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
            <h2>Registreerimine</h2>
            <form id="registerForm">
                <div class="form-group">
                    <label for="name">Nimi</label>
                    <input type="text" id="name" name="name" required>
                </div>

                <div class="form-group">
                    <label for="email">Email</label>
                    <input type="email" id="email" name="email" required>
                </div>

                <div class="form-group">
                    <label for="password">Parool</label>
                    <input type="password" id="password" name="password" required>
                </div>

                <button type="submit" class="btn btn-primary" style="width: 100%;">
                    Registreeru
                </button>
            </form>

            <p style="margin-top: 1rem; text-align: center;">
                Juba kasutaja? <a href="login.html">Logi sisse</a>
            </p>
        </div>
    </main>

    <script src="js/app.js"></script>
</body>
</html>
```

---

## 12. Harjutused

### Harjutus 9.1: HTML Struktuur
1. Loo index.html põhistruktuuriga
2. Lisa nav, main, footer
3. Kasuta semantic HTML

### Harjutus 9.2: CSS Styling
1. Loo styles.css
2. Lisa navbar stiilid
3. Tee responsive (mobile-first)

### Harjutus 9.3: Registration Form
1. Loo register.html
2. Lisa vorm (nimi, email, parool)
3. Stileeri vormi

---

**Autor:** Koolituskava v1.0
**Kuupäev:** 2025-11-15
