# Peatükk 4: Git ja Versioonihaldus

**Kestus:** 3 tundi
**Eeldused:** Peatükid 1-3 läbitud
**Eesmärk:** Õppida Git versioonihaldussüsteemi kasutama ja GitHub/GitLab integreerimist

---

## Sisukord

1. [Versioonihalduse Põhimõtted](#1-versioonihalduse-põhimõtted)
2. [Git Ülevaade ja Arhitektuur](#2-git-ülevaade-ja-arhitektuur)
3. [Git Paigaldamine ja Seadistamine](#3-git-paigaldamine-ja-seadistamine)
4. [Esimene Repositoorium](#4-esimene-repositoorium)
5. [Põhilised Git Käsud](#5-põhilised-git-käsud)
6. [Harud (Branches) ja Merging](#6-harud-branches-ja-merging)
7. [Remote Repositories (GitHub/GitLab)](#7-remote-repositories-githubgitlab)
8. [.gitignore ja Failide Ignoreerimine](#8-gitignore-ja-failide-ignoreerimine)
9. [Merge Konfliktid](#9-merge-konfliktid)
10. [Git Best Practices](#10-git-best-practices)
11. [Harjutused](#11-harjutused)
12. [Kontrolliküsimused](#12-kontrolliküsimused)
13. [Lisamaterjalid](#13-lisamaterjalid)

---

## 1. Versioonihalduse Põhimõtted

### 1.1. Mis on Versioonihaldus?

**Versioonihaldus (Version Control)** on süsteem, mis salvestab muudatused failides aja jooksul, võimaldades:
- Vaadata ajalugu
- Taastada varasemaid versioone
- Võrrelda muudatusi
- Koostööd mitme arendajaga

#### Analoogia: Dokumendi Versioonid

Ilma versioonihalduseta:
```
project.js
project_final.js
project_final_REALLY.js
project_final_REALLY_v2.js
project_final_REALLY_v2_THIS_ONE.js
project_final_v3_new.js
```

Git'iga:
```
project.js  (kõik versioonid on sees, ligipääs ajaloos)
```

---

### 1.2. Versioonihalduse Eelised

#### Ilma Versioonihalduseta

❌ **"Ma ei tea, mis muutus"** - Ei ole ajalugu
❌ **"Kus on vana versioon?"** - Keeruline taastada
❌ **"Kes seda muutis?"** - Ei tea autorit
❌ **"Ma rikkusin midagi"** - Raske tagasi võtta
❌ **Koostöö on keeruline** - Failide ülekirjutamine

#### Git'iga

✅ **Täielik ajalugu** - Iga muudatus salvestatud
✅ **Lihtne taastamine** - `git checkout` või `git revert`
✅ **Autorite jälgimine** - `git log`, `git blame`
✅ **Turvaline eksperimenteerimine** - Branches (harud)
✅ **Sujuv koostöö** - Merging, pull requests

---

### 1.3. Versioonihaldustüübid

#### 1.3.1. Lokaalne Versioonihaldus

```
┌─────────────────────┐
│   Sinu Arvuti       │
│                     │
│  ┌──────────────┐   │
│  │  Version     │   │
│  │  Database    │   │
│  │  ┌────┐      │   │
│  │  │ v1 │      │   │
│  │  ├────┤      │   │
│  │  │ v2 │      │   │
│  │  ├────┤      │   │
│  │  │ v3 │      │   │
│  │  └────┘      │   │
│  └──────────────┘   │
└─────────────────────┘
```

**Probleem:** Ei saa koostööd teha, ei ole backup'i.

---

#### 1.3.2. Tsentraliseeritud VCS (SVN, CVS)

```
┌─────────────────────┐
│   Central Server    │
│                     │
│  ┌──────────────┐   │
│  │  Repository  │   │
│  │  ┌────┐      │   │
│  │  │ v1 │      │   │
│  │  ├────┤      │   │
│  │  │ v2 │      │   │
│  │  ├────┤      │   │
│  │  │ v3 │      │   │
│  │  └────┘      │   │
│  └──────────────┘   │
└─────────┬───────────┘
          │
    ┌─────┴─────┐
    │           │
┌───▼───┐   ┌───▼───┐
│ Dev A │   │ Dev B │
└───────┘   └───────┘
```

**Probleem:** Üks tõrkepunkt (server down = ei saa töötada).

---

#### 1.3.3. Hajutatud VCS (Git, Mercurial)

```
┌─────────────────────┐
│   Remote (GitHub)   │
│  ┌──────────────┐   │
│  │  Repository  │   │
│  │  (täielik)   │   │
│  └──────────────┘   │
└─────────┬───────────┘
          │
    ┌─────┴─────┐
    │           │
┌───▼───────────▼───┐
│ Dev A         Dev B│
│┌─────────┐ ┌──────┤
││ Local   │ │Local ││
││ Repo    │ │Repo  ││
││(täielik)│ │(täie-││
││         │ │lik)  ││
│└─────────┘ └──────┘│
└────────────────────┘
```

**Eelised:**
✅ Iga arendaja on täielik koopia
✅ Töötab offline'is
✅ Kiire (enamik operatsioone lokaalsed)
✅ Paindlik workflow

---

## 2. Git Ülevaade ja Arhitektuur

### 2.1. Mis on Git?

**Git** on hajutatud versioonihaldussüsteem, mille lõi Linus Torvalds 2005. aastal Linux kerneli arenduse jaoks.

**Omadused:**
- 🚀 **Kiire** - Enamik operatsioone lokaalsed
- 🌳 **Branch'id** - Kerged ja kiired
- 📦 **Väike** - Efektiivne andmete salvestus
- 🔐 **Terviklikkus** - SHA-1 kontrollsummad
- 🌍 **Hajutatud** - Ei sõltu ühest serverist

---

### 2.2. Git Kolme Olek

Git hoiab faile kolmes olekus:

```
┌──────────────────────────────────────────────────┐
│           Working Directory                      │
│  (Sinu töökausta failid)                        │
│                                                  │
│  index.html                                      │
│  style.css         ──┐                           │
│  app.js              │                           │
└──────────────────────┼───────────────────────────┘
                       │ git add
                       │
┌──────────────────────▼───────────────────────────┐
│           Staging Area (Index)                   │
│  (Failid, mis lähevad järgmisse commit'i)       │
│                                                  │
│  index.html ✓                                    │
│  style.css ✓       ──┐                           │
│  app.js ✓            │                           │
└──────────────────────┼───────────────────────────┘
                       │ git commit
                       │
┌──────────────────────▼───────────────────────────┐
│           Repository (.git)                      │
│  (Püsivalt salvestatud ajalugu)                 │
│                                                  │
│  Commit 1 → Commit 2 → Commit 3                 │
└──────────────────────────────────────────────────┘
```

---

### 2.3. Git Faili Olekud

```
┌──────────┐
│ Untracked│  (Git ei jälgi)
└────┬─────┘
     │ git add
     │
┌────▼──────────┐
│   Unmodified  │  (Commit'itud, ei ole muudetud)
└────┬──────────┘
     │ muuda faili
     │
┌────▼──────────┐
│   Modified    │  (Muudetud, aga ei ole staged)
└────┬──────────┘
     │ git add
     │
┌────▼──────────┐
│    Staged     │  (Valmis commit'imiseks)
└────┬──────────┘
     │ git commit
     │
┌────▼──────────┐
│  Committed    │  (Ajaloos, püsivalt salvestatud)
└───────────────┘
```

---

### 2.4. Git vs GitHub/GitLab

**Oluline erinevus:**

| Git | GitHub/GitLab |
|-----|---------------|
| **Tööriist** | **Platvorm** |
| Käsurea tarkvara | Veebiteenused |
| Lokaalne või remote | Alati remote (pilves) |
| Tasuta, open source | Tasuta + tasulised plaanid |
| Versioonihaldus | Git hosting + lisafunktsioonid |
| Töötab offline | Vajab internetiühendust |

**Analoogia:**
- **Git** = Automootor
- **GitHub/GitLab** = Parkla ja autohoolduse teenused

---

## 3. Git Paigaldamine ja Seadistamine

### 3.1. Git Paigaldamine Zorin OS-is

Git on tavaliselt juba paigaldatud, aga kontrollime:

```bash
# Kontrolli Git versiooni
git --version

# Väljund:
# git version 2.43.0
```

**Kui ei ole paigaldatud:**
```bash
sudo apt update
sudo apt install git -y
```

---

### 3.2. Git Paigaldamine VPS-is

```bash
# Logi VPS-i sisse
ssh hostinger-vps

# Kontrolli Git versiooni
git --version

# Kui ei ole paigaldatud:
sudo apt update
sudo apt install git -y
```

---

### 3.3. Git Globaalne Konfiguratsioon

**Esmakordne seadistamine (oluline!):**

```bash
# Seadista oma nimi (näidatakse commit'ides)
git config --global user.name "Janek Tamm"

# Seadista oma email (näidatakse commit'ides)
git config --global user.email "janek@example.com"

# Seadista vaikimisi editor
git config --global core.editor nano
# VÕI kui eelistad vim'i:
# git config --global core.editor vim

# Seadista vaikimisi branch nimi (soovitatav: main)
git config --global init.defaultBranch main

# Luba värvilised väljundid
git config --global color.ui auto
```

---

### 3.4. Kontrolli Konfiguratsiooni

```bash
# Näita kõiki seadeid
git config --list

# Väljund:
# user.name=Janek Tamm
# user.email=janek@example.com
# core.editor=nano
# init.defaultbranch=main
# color.ui=auto
# ...

# Näita ainult nime
git config user.name

# Näita ainult emaili
git config user.email
```

**Konfiguratsioon salvestatakse:** `~/.gitconfig`

```bash
# Vaata konfiguratsioonifaili
cat ~/.gitconfig

# Väljund:
# [user]
#     name = Janek Tamm
#     email = janek@example.com
# [core]
#     editor = nano
# [init]
#     defaultBranch = main
# [color]
#     ui = auto
```

---

## 4. Esimene Repositoorium

### 4.1. Uue Repositooriumi Loomine

#### Meetod 1: Loo Uus Projekt

```bash
# Loo projekti kataloog
mkdir ~/projects/minu-projekt
cd ~/projects/minu-projekt

# Initsialiseeri Git repositoorium
git init

# Väljund:
# Initialized empty Git repository in /home/janek/projects/minu-projekt/.git/

# Kontrolli
ls -la

# Väljund näitab .git/ kataloogi:
# drwxr-xr-x  3 janek janek 4096 nov 14 13:00 .
# drwxr-xr-x  5 janek janek 4096 nov 14 13:00 ..
# drwxr-xr-x  7 janek janek 4096 nov 14 13:00 .git
```

**.git/ kataloog sisaldab:**
- Kogu ajalugu
- Konfiguratsiooni
- Branch'e
- Remote'sid

**OLULINE:** Ära kustuta `.git/` kataloogi, muidu kaotad kogu ajaloo!

---

#### Meetod 2: Klooni Olemasolev Repositoorium

```bash
# Klooni remote repositoorium
git clone https://github.com/kasutaja/projekt.git

# VÕI SSH URL'iga:
git clone git@github.com:kasutaja/projekt.git

# Väljund:
# Cloning into 'projekt'...
# remote: Enumerating objects: 100, done.
# remote: Counting objects: 100% (100/100), done.
# remote: Compressing objects: 100% (80/80), done.
# remote: Total 100 (delta 20), reused 100 (delta 20), pack-reused 0
# Receiving objects: 100% (100/100), 50.00 KiB | 500.00 KiB/s, done.
# Resolving deltas: 100% (20/20), done.
```

---

### 4.2. Git Staatuse Kontrollimine

```bash
# Kontrolli repositooriumi staatust
git status

# Väljund uuel repositooriumil:
# On branch main
#
# No commits yet
#
# nothing to commit (create/copy files and use "git add" to track)
```

---

### 4.3. Esimese Faili Lisamine

```bash
# Loo README fail
echo "# Minu Projekt" > README.md
echo "See on minu esimene Git projekt!" >> README.md

# Kontrolli staatust
git status

# Väljund:
# On branch main
#
# No commits yet
#
# Untracked files:
#   (use "git add <file>..." to include in what will be committed)
#         README.md
#
# nothing added to commit but untracked files present (use "git add" to track)
```

**"Untracked"** tähendab, et Git näeb faili, aga ei jälgi seda veel.

---

## 5. Põhilised Git Käsud

### 5.1. git add - Staging

**Lisa fail staging area'sse:**

```bash
# Lisa üks fail
git add README.md

# Lisa kõik failid praegusest kataloogist
git add .

# Lisa kõik muudetud failid
git add -A

# Kontrolli staatust
git status

# Väljund:
# On branch main
#
# No commits yet
#
# Changes to be committed:
#   (use "git rm --cached <file>..." to unstage)
#         new file:   README.md
```

**"Changes to be committed"** - Fail on staged, valmis commit'imiseks.

---

### 5.2. git commit - Muudatuste Salvestamine

```bash
# Commit koos sõnumiga (-m flag)
git commit -m "Esimene commit: Lisa README"

# Väljund:
# [main (root-commit) a1b2c3d] Esimene commit: Lisa README
#  1 file changed, 2 insertions(+)
#  create mode 100644 README.md

# Kontrolli staatust
git status

# Väljund:
# On branch main
# nothing to commit, working tree clean
```

**"working tree clean"** - Kõik muudatused on commit'itud! ✅

---

#### Commit Sõnumite Best Practices

**Hea commit sõnum:**
```bash
git commit -m "Lisa kasutaja autentimise funktsioon"
git commit -m "Paranda PostgreSQL ühenduse viga"
git commit -m "Uuenda README juhiste lisamisega"
```

**Halb commit sõnum:**
```bash
git commit -m "fix"
git commit -m "muudatused"
git commit -m "töötab nüüd"
git commit -m "asdasd"
```

**Konventsioon (soovitav):**
```
<tüüp>: <kirjeldus>

feat: Lisa uus funktsioon
fix: Paranda viga
docs: Uuenda dokumentatsiooni
style: Vormingu muudatused (ei mõjuta koodi)
refactor: Koodi refaktoreerimine
test: Lisa või uuenda teste
chore: Hooldusülesanded (build, dependencies)
```

**Näited:**
```bash
git commit -m "feat: Lisa kasutaja registreerimise endpoint"
git commit -m "fix: Paranda SQL injection haavatavus"
git commit -m "docs: Lisa API dokumentatsioon"
git commit -m "refactor: Optimeeri andmebaasi päringuid"
```

---

### 5.3. git log - Ajaloo Vaatamine

```bash
# Näita commit'ide ajalugu
git log

# Väljund:
# commit a1b2c3d4e5f6g7h8i9j0 (HEAD -> main)
# Author: Janek Tamm <janek@example.com>
# Date:   Thu Nov 14 13:15:00 2024 +0200
#
#     Esimene commit: Lisa README

# Lühike formaat (üks rida commit kohta)
git log --oneline

# Väljund:
# a1b2c3d (HEAD -> main) Esimene commit: Lisa README

# Graafiline vaade (kui on branch'e)
git log --oneline --graph --all

# Viimased 5 commit'i
git log -n 5

# Commit'id konkreetse autori poolt
git log --author="Janek"
```

---

### 5.4. git diff - Erinevuste Vaatamine

```bash
# Loo testimiseks uus fail
echo "console.log('Hello, Git!');" > app.js

# Muuda README
echo "" >> README.md
echo "## Funktsioonid" >> README.md
echo "- Git õppimine" >> README.md

# Vaata, mis muutus (working directory vs staging)
git diff

# Väljund näitab erinevusi:
# diff --git a/README.md b/README.md
# index 123abc..456def 100644
# --- a/README.md
# +++ b/README.md
# @@ -1,2 +1,5 @@
#  # Minu Projekt
#  See on minu esimene Git projekt!
# +
# +## Funktsioonid
# +- Git õppimine

# Lisa failid staging'u
git add .

# Vaata staged muudatusi (staging vs viimane commit)
git diff --staged
```

**Värvid:**
- 🟢 Roheline (+) = Lisatud read
- 🔴 Punane (-) = Kustutatud read

---

### 5.5. git restore - Muudatuste Tagasivõtmine

```bash
# Loo fail
echo "Test" > test.txt
git add test.txt
git commit -m "Lisa test.txt"

# Muuda faili
echo "Muudetud sisu" > test.txt

# Kontrolli staatust
git status
# Modified: test.txt

# Võta muudatus tagasi (restore working directory)
git restore test.txt

# test.txt on nüüd tagasi viimase commit'i sisu
cat test.txt
# Väljund: Test
```

**Unstage fail:**
```bash
# Lisa fail staging'u
git add test.txt

# Eemalda staging'ust (jääb working directory)
git restore --staged test.txt
```

---

### 5.6. git rm - Failide Kustutamine

```bash
# Kustuta fail ja stage muudatus
git rm test.txt

# Commit
git commit -m "Eemalda test.txt"

# Fail on nüüd kustutatud nii working directory'st kui ka Git'ist
```

**Eemalda ainult Git'ist (jäta fail alles):**
```bash
git rm --cached fail.txt
git commit -m "Lõpeta fail.txt jälgimine"

# fail.txt jääb kausta, aga Git ei jälgi enam
```

---

## 6. Harud (Branches) ja Merging

### 6.1. Mis on Branch?

**Branch (haru)** on sõltumatu arendusliin, mis võimaldab:
- Töötada uute funktsioonidega ilma main'i mõjutamata
- Eksperimenteerida turvaliselt
- Teha paralleelseid töid (mitme arendajaga)

#### Analoogia: Paralleelsed Universumid

```
main:     A---B---C---D---E---F
                   \
feature:            G---H---I
```

- **main** - Stabiilne tootmisversioon
- **feature** - Uus funktsioon arenduses
- Merge'des **I** → **F**, saame **main**: A-B-C-D-E-F-I

---

### 6.2. Branch'ide Loomine ja Vahetamine

```bash
# Näita kõiki branch'e
git branch

# Väljund:
# * main
# (tärn näitab praegust branchi)

# Loo uus branch
git branch feature-login

# Vaheta branchи
git checkout feature-login

# Väljund:
# Switched to branch 'feature-login'

# Alternatiiv: Loo ja vaheta ühe käsuga
git checkout -b feature-register

# VÕI uuema süntaksiga (git 2.23+):
git switch feature-login
git switch -c feature-new
```

---

### 6.3. Branch'il Töötamine

```bash
# Oled nüüd feature-login branch'il
git branch
# * feature-login
#   main

# Loo uus fail
echo "Login funktsioon" > login.js

# Add ja commit
git add login.js
git commit -m "feat: Lisa login funktsioon"

# Vaata logi
git log --oneline --graph --all

# Väljund:
# * b2c3d4e (HEAD -> feature-login) feat: Lisa login funktsioon
# * a1b2c3d (main) Esimene commit: Lisa README
```

---

### 6.4. Branch'ide Merging

#### 6.4.1. Fast-forward Merge (lihtne)

Kui main ei ole muutunud pärast branch'i loomist:

```bash
# Vaheta tagasi main'i
git checkout main

# Merge feature-login main'i
git merge feature-login

# Väljund:
# Updating a1b2c3d..b2c3d4e
# Fast-forward
#  login.js | 1 +
#  1 file changed, 1 insertion(+)
#  create mode 100644 login.js

# login.js on nüüd main'is
ls
# login.js  README.md
```

**Visualiseeritud:**
```
Enne:
main:     A---B
               \
feature:        C---D

Pärast fast-forward:
main:     A---B---C---D
```

---

#### 6.4.2. 3-way Merge (keerulisem)

Kui main on edasi liikunud:

```bash
# Main'is on uued commit'id
# Loo uus branch ja tee muudatusi
git checkout -b feature-logout
echo "Logout funktsioon" > logout.js
git add logout.js
git commit -m "feat: Lisa logout funktsioon"

# Vaheta main'i ja tee seal ka muudatusi
git checkout main
echo "## Autorid" >> README.md
echo "- Janek" >> README.md
git add README.md
git commit -m "docs: Lisa autorid"

# Nüüd main ja feature-logout on lahku läinud

# Merge feature-logout main'i
git merge feature-logout

# Git loob merge commit'i
# Väljund:
# Merge made by the 'recursive' strategy.
#  logout.js | 1 +
#  1 file changed, 1 insertion(+)
#  create mode 100644 logout.js
```

**Visualiseeritud:**
```
Enne:
main:     A---B---C
               \
feature:        D---E

Pärast 3-way merge:
main:     A---B---C---F (merge commit)
               \       /
feature:        D---E
```

---

### 6.5. Branch'ide Kustutamine

```bash
# Kustuta branch (pärast merge'imist)
git branch -d feature-login

# Väljund:
# Deleted branch feature-login (was b2c3d4e).

# Force delete (kui pole merge'itud)
git branch -D feature-abandoned

# Kontrolli branch'e
git branch
# * main
#   feature-logout
```

---

## 7. Remote Repositories (GitHub/GitLab)

### 7.1. GitHub vs GitLab

| Omadus | GitHub | GitLab |
|--------|--------|--------|
| **Omanik** | Microsoft | GitLab Inc. |
| **Hosting** | github.com (cloud) | gitlab.com või self-hosted |
| **Tasuta private repos** | ✅ Jah | ✅ Jah |
| **CI/CD** | GitHub Actions | GitLab CI (integeeritud) |
| **Populaarsus** | 🥇 #1 (100M+ repos) | 🥈 #2 |
| **Kasutajaliides** | Lihtne, puhas | Rohkem funktsioone |
| **Self-hosting** | ❌ Ei | ✅ Jah (Community Edition) |

**Meie koolituses:** Kasutame **GitHubi**, aga kontseptsioonid on samad GitLab'is.

---

### 7.2. GitHub Konto Loomine

1. Mine https://github.com
2. Kliki "Sign up"
3. Sisesta email, parool, kasutajanimi
4. Kinnita email

✅ **Konto valmis!**

---

### 7.3. SSH Võtmete Seadistamine GitHubis

**Miks SSH?** Ei pea iga push/pull jaoks parooli sisestama.

#### Samm 1: Kontrolli SSH Võtmeid

```bash
# Vaata, kas sul on SSH võtmed
ls -la ~/.ssh/

# Otsi: id_ed25519.pub või id_rsa.pub
```

Kui sul juba on võtmed (Peatükist 2), kasutame neid.

**Kui ei ole, loo uus:**
```bash
ssh-keygen -t ed25519 -C "janek@example.com"
# Vajuta ENTER (vaikimisi asukoht)
# Sisesta passphrase (valikuline)
```

---

#### Samm 2: Kopeeri Avalik Võti

```bash
# Kuva avalik võti
cat ~/.ssh/id_ed25519.pub

# Väljund (näide):
# ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMx1yP8h... janek@example.com

# Kopeeri KOGU väljund (Ctrl+Shift+C)
```

---

#### Samm 3: Lisa Võti GitHubi

1. Mine GitHubis: **Settings** → **SSH and GPG keys**
2. Kliki **"New SSH key"**
3. **Title:** "Minu Laptop" (või muu kirjeldus)
4. **Key:** Kleebi avalik võti
5. Kliki **"Add SSH key"**

---

#### Samm 4: Testi Ühendust

```bash
# Testi SSH ühendust GitHubiga
ssh -T git@github.com

# Väljund:
# Hi kasutajanimi! You've successfully authenticated, but GitHub does not provide shell access.
```

✅ **SSH töötab!**

---

### 7.4. Uue Repositooriumi Loomine GitHubis

#### Meetod 1: GitHub Web Interface

1. Mine GitHubis: **Repositories** → **"New"**
2. **Repository name:** `minu-projekt`
3. **Description:** "Minu esimene projekt"
4. **Public** või **Private**
5. **NB! Ära lisa README, .gitignore ega LICENSE** (meil on juba lokaalne repo)
6. Kliki **"Create repository"**

---

#### Meetod 2: GitHub CLI (gh)

```bash
# Paigalda gh (kui ei ole)
# Zorin OS:
sudo apt install gh

# Autendi
gh auth login
# Vali: GitHub.com, HTTPS, Login with browser

# Loo repo
gh repo create minu-projekt --public --source=. --remote=origin
```

---

### 7.5. Lokaalselt Repo Sidumine GitHubiga

```bash
# Lisa remote (GitHub repo URL)
git remote add origin git@github.com:kasutajanimi/minu-projekt.git

# Kontrolli remote'e
git remote -v

# Väljund:
# origin  git@github.com:kasutajanimi/minu-projekt.git (fetch)
# origin  git@github.com:kasutajanimi/minu-projekt.git (push)

# Push main branch GitHubi
git push -u origin main

# Väljund:
# Enumerating objects: 6, done.
# Counting objects: 100% (6/6), done.
# Delta compression using up to 8 threads
# Compressing objects: 100% (4/4), done.
# Writing objects: 100% (6/6), 567 bytes | 567.00 KiB/s, done.
# Total 6 (delta 0), reused 0 (delta 0), pack-reused 0
# To github.com:kasutajanimi/minu-projekt.git
#  * [new branch]      main -> main
# Branch 'main' set up to track remote branch 'main' from 'origin'.
```

**Selgitus:**
- `-u` või `--set-upstream`: Seadista tracking (jätab meelde seose)
- `origin`: Remote'i nimi (konventsioon)
- `main`: Branch nimi

---

### 7.6. Push ja Pull

#### git push - Saada Muudatused GitHubi

```bash
# Tee muudatusi
echo "Uus rida" >> README.md
git add README.md
git commit -m "docs: Uuenda README"

# Push GitHubi
git push

# Väljund:
# Enumerating objects: 5, done.
# ...
# To github.com:kasutajanimi/minu-projekt.git
#    a1b2c3d..e4f5g6h  main -> main
```

---

#### git pull - Too Muudatused GitHubist

Kui keegi teine (või sina teises masinas) tegi muudatusi:

```bash
# Too uusimad muudatused
git pull

# Väljund:
# remote: Enumerating objects: 5, done.
# remote: Counting objects: 100% (5/5), done.
# ...
# Updating e4f5g6h..i7j8k9l
# Fast-forward
#  README.md | 1 +
#  1 file changed, 1 insertion(+)
```

**git pull = git fetch + git merge**

---

### 7.7. Repo Kloneerimine

```bash
# Klooni kellegi teise repo
git clone git@github.com:kasutaja/projekt.git

# VÕI HTTPS:
git clone https://github.com/kasutaja/projekt.git

# Väljund:
# Cloning into 'projekt'...
# remote: Enumerating objects: 100, done.
# ...
# Resolving deltas: 100% (20/20), done.

# Sisemine kataloog loodud
cd projekt

# Remote on automaatselt seadistatud
git remote -v
# origin  git@github.com:kasutaja/projekt.git (fetch)
# origin  git@github.com:kasutaja/projekt.git (push)
```

---

## 8. .gitignore ja Failide Ignoreerimine

### 8.1. Mis on .gitignore?

**.gitignore** fail määrab, milliseid faile ja katalooge Git peaks **ignoreerima** (mitte jälgima).

**Miks ignoreerida?**
- ❌ **Turvalisus:** Paroolid, API võtmed, sertifikaadid
- ❌ **Ajutised failid:** Logs, cache, temp files
- ❌ **Build artefaktid:** Compiled code, dist folders
- ❌ **Dependency kataloogid:** node_modules, vendor
- ❌ **IDE konfiguratsioonid:** .vscode, .idea
- ❌ **OS failid:** .DS_Store (macOS), Thumbs.db (Windows)

---

### 8.2. .gitignore Faili Loomine

```bash
# Loo .gitignore fail
nano .gitignore
```

**Lisa sisu:**
```gitignore
# Node.js
node_modules/
npm-debug.log
yarn-error.log
.env

# Logs
logs/
*.log

# Build outputs
dist/
build/
*.min.js
*.min.css

# IDE
.vscode/
.idea/
*.swp
*.swo
*~

# OS
.DS_Store
Thumbs.db

# Database
*.sqlite
*.db

# Temporary files
tmp/
temp/
*.tmp

# Secrets (OLULINE!)
.env
.env.local
.env.production
config/secrets.yml
*.pem
*.key
credentials.json
```

**Salvesta** (Ctrl+O, Enter) ja **välju** (Ctrl+X)

---

### 8.3. .gitignore Reeglid

```gitignore
# Kommenti algavad #-ga

# Ignore specific fail
config.json

# Ignore kõik .log failid
*.log

# Ignore kataloog
node_modules/

# Ignore kõik failid kataloogis
tmp/*

# Ignore kõik .txt failid, välja arvatud important.txt
*.txt
!important.txt

# Ignore failid kõigis alamkataloogides
**/logs/*.log

# Ignore ainult juurkataloogi fail (mitte alamkataloogis)
/config.json
```

---

### 8.4. Juba Jälgitavate Failide Ignoreerimine

Kui fail on juba committed ja tahad seda nüüd ignoreerida:

```bash
# Eemalda jälgimisest (aga ära kustuta faili)
git rm --cached fail.txt

# Lisa .gitignore'i
echo "fail.txt" >> .gitignore

# Commit
git add .gitignore
git commit -m "chore: Lisa fail.txt .gitignore'i"
```

---

### 8.5. Globaalne .gitignore

Failid, mida tahad ALATI ignoreerida (kõikides projektides):

```bash
# Loo globaalne .gitignore
nano ~/.gitignore_global
```

**Lisa:**
```gitignore
# OS
.DS_Store
Thumbs.db

# IDE
.vscode/
.idea/
*.swp
```

**Seadista Git kasutama seda:**
```bash
git config --global core.excludesfile ~/.gitignore_global
```

---

### 8.6. gitignore.io - Automaatne Genereerimine

Veebilehekülg, mis genereerib .gitignore faile: https://www.toptal.com/developers/gitignore

```bash
# VÕI käsurealt:
curl -L https://www.toptal.com/developers/gitignore/api/node,linux,visualstudiocode > .gitignore
```

---

## 9. Merge Konfliktid

### 9.1. Mis on Merge Konflikt?

**Merge konflikt** tekib, kui Git ei suuda automaatselt merge'ida, sest sama faili sama kohta on muudetud erinevalt.

#### Näide Stsenaarium

```bash
# Main branch'is
git checkout main
echo "Tere!" > greeting.txt
git add greeting.txt
git commit -m "Lisa greeting"

# Loo branch ja muuda seal
git checkout -b feature-greeting
echo "Tere, maailm!" > greeting.txt
git add greeting.txt
git commit -m "Muuda greeting'ut"

# Main'is muuda samasse faili teistmoodi
git checkout main
echo "Hei seal!" > greeting.txt
git add greeting.txt
git commit -m "Muuda greeting'ut main'is"

# Proovi merge'ida
git merge feature-greeting

# KONFLIKT!
# Väljund:
# Auto-merging greeting.txt
# CONFLICT (content): Merge conflict in greeting.txt
# Automatic merge failed; fix conflicts and then commit the result.
```

---

### 9.2. Konflikti Lahendamine

```bash
# Vaata staatust
git status

# Väljund:
# On branch main
# You have unmerged paths.
#   (fix conflicts and run "git commit")
#   (use "git merge --abort" to abort the merge)
#
# Unmerged paths:
#   (use "git add <file>..." to mark resolution)
#         both modified:   greeting.txt

# Vaata faili
cat greeting.txt

# Väljund:
# <<<<<<< HEAD
# Hei seal!
# =======
# Tere, maailm!
# >>>>>>> feature-greeting
```

**Konflikt märgid:**
- `<<<<<<< HEAD` - Sinu praeguse branchi versioon (main)
- `=======` - Eraldaja
- `>>>>>>> feature-greeting` - Tulevad muudatused (feature branch)

---

### 9.3. Käsitsi Parandamine

```bash
# Redigeeri faili
nano greeting.txt
```

**Eemalda konfliktimärgid ja vali versioon:**

**Variant 1: Võta mõlemad**
```
Hei seal!
Tere, maailm!
```

**Variant 2: Võta ainult üks**
```
Tere, maailm!
```

**Variant 3: Kirjuta uus**
```
Tervitused kõigile!
```

**Salvesta** fail.

---

### 9.4. Konflikti Lahenduse Commit

```bash
# Lisa lahendatud fail
git add greeting.txt

# Kontrolli staatust
git status
# Väljund:
# All conflicts fixed but you are still merging.
#   (use "git commit" to conclude merge)

# Commit merge
git commit -m "Merge feature-greeting: Lahenda konflikt"

# VÕI lihtsalt:
git commit
# Git täidab automaatselt merge commit sõnumi
```

✅ **Konflikt lahendatud!**

---

### 9.5. Merge Abort

Kui sa ei taha konflikti lahendada:

```bash
# Tühista merge
git merge --abort

# Kõik läheb tagasi olekusse enne merge'i
```

---

### 9.6. Merge Tools

Visual merge tools:

```bash
# Seadista merge tool (näiteks meld)
sudo apt install meld
git config --global merge.tool meld

# Kasuta merge tool'i konflikti lahendamiseks
git mergetool

# Meld avaneb, näitab 3-way diff
# Lahenda konflikt GUI's
```

**Teised merge tools:**
- **VS Code** - Built-in merge editor
- **KDiff3** - Cross-platform
- **P4Merge** - Perforce visual merge tool
- **Beyond Compare** - Commercial

---

## 10. Git Best Practices

### 10.1. Commit'imise Best Practices

✅ **Commit tihti** - Väikesed, loogilised muudatused
✅ **Kirjutab häid commit sõnumeid** - Kirjelda "miks", mitte "mida"
✅ **Ühes commit'is üks asi** - Ära sega erinevaid muudatusi
✅ **Testi enne commit'i** - Veendu, et kood töötab
✅ **Ära commit'i poolikut tööd** - Või märgi selgelt WIP (Work In Progress)

❌ **Ära commit'i suuri faile** - Binary failid, videod (kasuta Git LFS)
❌ **Ära commit'i secrets** - Paroolid, API võtmed
❌ **Ära commit'i generated files** - Build artefaktid, node_modules

---

### 10.2. Branch'ide Strateegia

#### Git Flow (traditsiooniline)

```
main       ─────────────────────────────
              │     │           │
develop    ───┴─────┴───────────┴───────
              │  │  │       │
feature    ───┴──┘  └───────┘
```

**Branch'id:**
- `main` - Stabiilne tootmisversioon
- `develop` - Arendusversioon
- `feature/*` - Uued funktsioonid
- `hotfix/*` - Kiireloomulised parandused
- `release/*` - Release ettevalmistus

---

#### GitHub Flow (lihtsam, soovitatav)

```
main     ────A────B────C────D────E────
              \        /    \      /
feature        F──────G      H────I
```

**Töövoog:**
1. Loo branch main'ist
2. Tee muudatusi ja commit'i
3. Ava Pull Request
4. Code review
5. Merge main'i
6. Deploy

**Eelised:**
- Lihtne
- Sobib continuous deployment'ile
- Main on alati deployable

---

### 10.3. Pull Requests (PR) / Merge Requests (MR)

**Pull Request** on viis, kuidas pakkuda muudatusi projekti.

**Protsess:**
1. Fork või loo branch
2. Tee muudatusi
3. Push branch'i
4. Ava PR GitHubis
5. Kirjelda muudatusi
6. Code review
7. Arutelu ja parandused
8. Merge

**PR Template näide:**

```markdown
## Muudatuse kirjeldus
Lisa kasutaja autentimise funktsioon.

## Muudatuse tüüp
- [ ] Bug fix
- [x] Uus funktsioon
- [ ] Breaking change

## Checklist
- [x] Kood on testitud
- [x] Testid lisatud
- [x] Dokumentatsioon uuendatud
- [x] Commit sõnumid on selged
```

---

### 10.4. Commit Sõnumite Konventsioon

**Conventional Commits:** https://www.conventionalcommits.org/

**Formaat:**
```
<type>(<scope>): <subject>

<body>

<footer>
```

**Näited:**
```
feat(auth): lisa JWT autentimine

Implementeeri JWT põhine autentimine kasutades jsonwebtoken teeki.
- Lisa login endpoint
- Lisa token verification middleware
- Lisa refresh token funktsioon

Closes #123
```

```
fix(database): paranda connection pool leak

Connection'id ei sulgunud korrektselt, põhjustades pool exhaustion'i.

Fixes #456
```

---

### 10.5. .env Failid ja Secrets

**EI TOHI COMMIT'IDA:**
- `.env` failid
- API võtmed
- Paroolid
- Private keys
- Sertifikaadid

**Hea praktika:**
```bash
# Loo .env.example (ilma väärtusteta)
cat > .env.example << EOF
DATABASE_URL=
JWT_SECRET=
API_KEY=
EOF

# Commit .env.example
git add .env.example
git commit -m "docs: Lisa .env.example"

# Ära commit'i .env
echo ".env" >> .gitignore
```

---

### 10.6. Git Alias'ed

Tee Git käskudest lühemad:

```bash
# Seadista alias'ed
git config --global alias.st status
git config --global alias.co checkout
git config --global alias.br branch
git config --global alias.ci commit
git config --global alias.unstage 'reset HEAD --'
git config --global alias.last 'log -1 HEAD'
git config --global alias.lg 'log --oneline --graph --all --decorate'

# Nüüd saad kasutada:
git st        # asemel: git status
git co main   # asemel: git checkout main
git lg        # ilus log
```

---

## 11. Harjutused

### Harjutus 4.1: Esimene Git Repositoorium

**Eesmärk:** Luua ja seadistada Git repositoorium

**Sammud:**
1. Loo kataloog `git-harjutus`
2. Initsialiseeri Git: `git init`
3. Loo fail `index.html`
4. Lisa HTML5 boilerplate
5. Add ja commit
6. Vaata logi: `git log`

---

### Harjutus 4.2: Muudatuste Tegemine

**Eesmärk:** Harjutada git workflow'd

**Sammud:**
1. Muuda `index.html` (lisa sisu)
2. Vaata diff: `git diff`
3. Stage: `git add index.html`
4. Vaata staged diff: `git diff --staged`
5. Commit: `git commit -m "..."`
6. Kontrolli: `git log --oneline`

---

### Harjutus 4.3: Branch'id ja Merging

**Eesmärk:** Harjutada branch'idega töötamist

**Sammud:**
1. Loo branch: `git checkout -b feature-css`
2. Lisa `style.css` fail
3. Commit
4. Vaheta main'i: `git checkout main`
5. Merge: `git merge feature-css`
6. Kustuta branch: `git branch -d feature-css`

---

### Harjutus 4.4: GitHub Integratsioon

**Eesmärk:** Sidumine GitHubiga

**Sammud:**
1. Loo GitHub konto (kui ei ole)
2. Seadista SSH võtmed
3. Loo uus repo GitHubis
4. Lisa remote: `git remote add origin ...`
5. Push: `git push -u origin main`
6. Vaata GitHubis

---

### Harjutus 4.5: .gitignore

**Eesmärk:** Praktika .gitignore failiga

**Sammud:**
1. Loo kataloog `node_modules/` ja sinna fail
2. Loo `.env` fail
3. Vaata `git status` (näitab neid)
4. Loo `.gitignore`
5. Lisa:
   ```
   node_modules/
   .env
   ```
6. Vaata `git status` uuesti (ei näita enam)

---

### Harjutus 4.6: Merge Konflikt

**Eesmärk:** Lahenda merge konflikt

**Sammud:**
1. Main'is muuda `README.md`
2. Commit
3. Loo branch `feature-readme`
4. Muuda sama rea `README.md`
5. Commit
6. Vaheta main'i
7. Merge `feature-readme`
8. Lahenda konflikt
9. Commit merge

---

## 12. Kontrolliküsimused

### Teoreetilised Küsimused

1. **Mis on Git ja miks see on hajutatud VCS?**
   <details>
   <summary>Vastus</summary>
   Git on hajutatud versioonihaldussüsteem (Distributed Version Control System). See on hajutatud, sest iga arendaja koopiab kogu repositooriumi koos täieliku ajalooga oma masinasse. Ei sõltu ühest keskserverist ja saab töötada offline'is.
   </details>

2. **Mis vahe on git add, git commit ja git push vahel?**
   <details>
   <summary>Vastus</summary>
   - `git add`: Lisa muudatused staging area'sse (valmista ette commit'imiseks)
   - `git commit`: Salvesta staged muudatused lokaalse repositooriumi ajalukku
   - `git push`: Saada lokaalsed commit'id remote repositooriumisse (nt GitHubi)
   </details>

3. **Mis on branch ja miks see on kasulik?**
   <details>
   <summary>Vastus</summary>
   Branch (haru) on sõltumatu arendusliin, mis võimaldab paralleelselt töötada ilma main branchi mõjutamata. Kasulik uute funktsioonide arendamiseks, eksperimenteerimiseks ja paralleelse töö tegemiseks.
   </details>

4. **Mis on .gitignore fail ja miks seda kasutatakse?**
   <details>
   <summary>Vastus</summary>
   .gitignore fail määrab, milliseid faile ja katalooge Git peaks ignoreerima (mitte jälgima). Kasutatakse secrets'te, temporary files, build artefacts, dependencies kataloogide (nt node_modules) ignoreerimiseks.
   </details>

5. **Mis vahe on git merge ja git rebase vahel?**
   <details>
   <summary>Vastus</summary>
   - `git merge`: Ühendab branch'e, luues merge commit'i. Säilitab täieliku ajaloo.
   - `git rebase`: "Kirjutab ajalugu ümber", asetades commit'id branch'ist teise branch'i peale. Loob lineaarse ajaloo, aga muudab commit'ide hash'e.
   </details>

---

### Praktilised Küsimused

6. **Kuidas initsaliseerida uus Git repositoorium?**
   <details>
   <summary>Vastus</summary>
   ```bash
   git init
   ```
   </details>

7. **Kuidas vaadata, millised failid on muudetud?**
   <details>
   <summary>Vastus</summary>
   ```bash
   git status
   ```
   </details>

8. **Kuidas lisada kõik muudetud failid staging'u?**
   <details>
   <summary>Vastus</summary>
   ```bash
   git add .
   # VÕI
   git add -A
   ```
   </details>

9. **Kuidas luua uus branch ja kohe sinna vahetada?**
   <details>
   <summary>Vastus</summary>
   ```bash
   git checkout -b branch-nimi
   # VÕI uuema süntaksiga:
   git switch -c branch-nimi
   ```
   </details>

10. **Kuidas vaadata commit'ide ajalugu?**
    <details>
    <summary>Vastus</summary>
    ```bash
    git log
    # VÕI lühike:
    git log --oneline
    # VÕI graafiline:
    git log --oneline --graph --all
    ```
    </details>

11. **Kuidas võtta tagasi staged fail (unstage)?**
    <details>
    <summary>Vastus</summary>
    ```bash
    git restore --staged failinimi
    # VÕI vanem süntaks:
    git reset HEAD failinimi
    ```
    </details>

12. **Kuidas kustutada branch?**
    <details>
    <summary>Vastus</summary>
    ```bash
    git branch -d branch-nimi
    # VÕI force delete:
    git branch -D branch-nimi
    ```
    </details>

---

## 13. Lisamaterjalid

### 📚 Soovitatud Lugemine

#### Git Alused
- [Pro Git Book](https://git-scm.com/book/en/v2) - Tasuta, põhjalik
- [Git Documentation](https://git-scm.com/doc)
- [GitHub Git Guides](https://github.com/git-guides)
- [Atlassian Git Tutorials](https://www.atlassian.com/git/tutorials)

#### Interaktiivsed Õppevahendid
- [Learn Git Branching](https://learngitbranching.js.org/) - Visuaalne õppetool
- [Git-it](https://github.com/jlord/git-it-electron) - Desktop app
- [Oh My Git!](https://ohmygit.org/) - Git mäng

---

### 🛠️ Kasulikud Tööriistad

#### GUI Kliendid
- **GitKraken** - Cross-platform, visuaalne
- **GitHub Desktop** - Lihtne, integreeritud GitHubiga
- **Sourcetree** - Atlassian, tasuta
- **Git Extensions** - Windows

#### VS Code Extensions
- **GitLens** - Git supercharged
- **Git Graph** - Visualiseerimine
- **Git History** - File history viewer

#### Terminal Tools
- **tig** - Text-mode interface for Git
- **lazygit** - Simple terminal UI
- **delta** - Syntax-highlighting pager

```bash
# Paigalda tig
sudo apt install tig

# Kasuta
tig
# VÕI
tig --all
```

---

### 🎥 Video Ressursid

- **The Net Ninja** - Git & GitHub Tutorial for Beginners
- **Traversy Media** - Git Crash Course
- **Corey Schafer** - Git Tutorial for Beginners

---

### 📖 Git Cheat Sheet

```bash
# === Seadistamine ===
git config --global user.name "Nimi"
git config --global user.email "email"

# === Alustamine ===
git init                    # Initsialiseeri repo
git clone <url>             # Klooni repo

# === Põhikäsud ===
git status                  # Vaata staatust
git add <fail>              # Lisa staging'u
git add .                   # Lisa kõik
git commit -m "sõnum"       # Commit
git log                     # Vaata ajalugu
git diff                    # Vaata muudatusi

# === Branch'id ===
git branch                  # Loe branch'e
git branch <nimi>           # Loo branch
git checkout <nimi>         # Vaheta branch'i
git checkout -b <nimi>      # Loo ja vaheta
git merge <nimi>            # Merge branch
git branch -d <nimi>        # Kustuta branch

# === Remote ===
git remote add origin <url> # Lisa remote
git push -u origin main     # Push first time
git push                    # Push
git pull                    # Pull
git fetch                   # Fetch ilma merge'ta

# === Tagasivõtmine ===
git restore <fail>          # Restore working directory
git restore --staged <fail> # Unstage
git reset HEAD~1            # Undo viimane commit (soft)
git revert <commit>         # Loo uus commit, mis tühistab

# === Info ===
git log --oneline           # Lühike log
git log --graph --all       # Graafiline
git show <commit>           # Näita commit'i
git blame <fail>            # Vaata, kes muutis
```

---

## Kokkuvõte

Selles peatükis said:

✅ **Õppisid versioonihalduse põhimõtteid** - Miks Git on oluline
✅ **Seadistasid Git'i** - Nimi, email, editor
✅ **Lõid repositooriume** - Lokaalselt ja GitHubis
✅ **Õppisid põhikäske** - add, commit, push, pull, log
✅ **Branch'idega töötamist** - Loomine, merging, konfliktid
✅ **GitHub integratsioon** - SSH võtmed, remote repositories
✅ **.gitignore kasutamine** - Secrets ja failide ignoreerimine
✅ **Merge konfliktide lahendamine** - Käsitsi ja tööriistadega
✅ **Best practices** - Commit sõnumid, workflow'd

---

## Järgmine Peatükk

**Peatükk 5: Node.js ja Express.js Alused**

Järgmises peatükis:
- Node.js arhitektuur ja V8 engine
- npm ja package.json
- Express.js raamistik
- Middleware kontseptsioon
- Routing ja HTTP meetodid
- Esimene REST API
- Environment variables

**Moodul 2 algab!** 🚀 Liigume backend arendusse.

---

## Troubleshooting

### Probleem 1: "Permission denied (publickey)" GitHubis

**Lahendus:**
```bash
# Kontrolli SSH võtmeid
ls ~/.ssh/

# Testi GitHubiga ühendust
ssh -T git@github.com

# Kui ei tööta, lisa võti GitHubi (vaata sektsiooni 7.3)
```

---

### Probleem 2: Merge konflikt, ei tea kuidas lahendada

**Lahendus:**
```bash
# Abort merge
git merge --abort

# VÕI kasuta merge tool
git mergetool

# VÕI ava fail VS Code'is (näitab konflikte visuaalselt)
code .
```

---

### Probleem 3: Commit'isin kogemata .env faili

**Lahendus:**
```bash
# Eemalda failist, aga hoia lokaalselt
git rm --cached .env

# Lisa .gitignore'i
echo ".env" >> .gitignore

# Commit
git add .gitignore
git commit -m "chore: Eemalda .env ja lisa .gitignore"

# HOIATUS: Kui juba push'isid GitHubi,
# secrets on avalikud! Vaheta paroolid kohe!
```

---

**Autor:** Koolituskava v1.0
**Kuupäev:** 2025-11-14
**Järgmine uuendus:** Peatükk 5 lisamine
