# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

---

## Repository Overview

This is a comprehensive **Estonian-language DevOps training program** combining:
- **31 theory chapters** (~52,000-65,000 words) organized in 7 phases (FAASID)
- **10 hands-on labs** (~45 hours) with progressive complexity
- **3 pre-built microservices** used across all labs for practical exercises

**Target Audience:** IT professionals learning DevOps administration (infrastructure, containerization, orchestration, CI/CD, monitoring, security)

**Key Documentation:**
- `README.md` - Main program overview
- `DEVOPS-KOOLITUSKAVA-PLAAN-2025.md` - Master plan (phases, chapter specs, timeline, quality checklist)
- `TERMINOLOOGIA.md` - **MANDATORY** Estonian/English terminology standards
- `labs/CLAUDE.md` - Lab-specific guidance (separate from this file)

---

## Repository Structure

```
/home/janek/projects/hostinger/
├── README.md                                 # Main overview
├── DEVOPS-KOOLITUSKAVA-PLAAN-2025.md        # Master plan
├── TERMINOLOOGIA.md                         # Terminology standards
├── CLAUDE.md                                # This file
│
├── resource/                                 # ALL theory chapters go here
│   ├── 05-Docker-Pohimotted.md              ✅ (16 pages)
│   ├── 06-Dockerfile-Rakenduste-Konteineriseerimise-Detailid.md ✅ (18 pages)
│   ├── 06A-Java-SpringBoot-NodeJS-Konteineriseerimise-Spetsiifika.md ✅ (20 pages)
│   └── 08A-Docker-Compose-Production-Development-Seadistused.md ✅ (15 pages)
│
└── labs/                                     # All 10 labs + microservices
    ├── README.md, CLAUDE.md
    ├── apps/                                # Pre-built services
    └── 01-docker-lab/ through 10-terraform-iac-lab/
```

**Critical:** All theory chapters are created in `resource/` directory, NOT in root.

---

## Program Structure: 7 Phases

| Phase | Chapters | Topics | Status |
|-------|----------|--------|--------|
| **FAAS 1** | 1-4 | DevOps basics, Linux, Git, Networking | ⏳ Planned |
| **FAAS 2** | 5-9 | Docker, Dockerfile, Compose, PostgreSQL | 🏗️ 57% (4/7) |
| **FAAS 3** | 10-17 | Kubernetes basics | ⏳ Planned |
| **FAAS 4** | 18-21 | K8s advanced, Helm, CI/CD | ⏳ Planned |
| **FAAS 5** | 22-24 | Monitoring, Logging, Alerting | ⏳ Planned |
| **FAAS 6** | 25-27 | Security, Vault, RBAC | ⏳ Planned |
| **FAAS 7** | 28-30 | GitOps, Backup, Terraform | ⏳ Planned |

**Current Status (2025-01-25):** 4/31 chapters complete (12.9%), FAAS 2 in progress

---

## Chapter Structure (MANDATORY TEMPLATE)

Every chapter must follow this structure:

```markdown
# Peatükk X: [Title]

## Õpieesmärgid (Learning Objectives)
After this chapter, you can:
- ✅ Objective 1 (concrete, measurable)
- ✅ Objective 2
- ✅ Objective 3-5

## Põhimõisted (Key Concepts)
- **Eesti Term (English term):** Definition
- Follow TERMINOLOOGIA.md!

## Teooria (Theory - 70%)
### Subtopic 1
Explanation with diagrams (ASCII art or Mermaid)

### Subtopic 2
Concepts, architecture, best practices

## Praktilised Näited (Practical Examples - 30%)
### Example 1: [Scenario]
```bash
# Working code with explanations
```

## Levinud Probleemid ja Lahendused (Troubleshooting)
### Problem 1
**Sümptom:** What user sees
**Põhjus:** Why it happens
**Lahendus:** How to fix

## Best Practices
- ✅ DO: Recommendation 1
- ❌ DON'T: Avoid this 1

## Kokkuvõte (Summary)
3-5 key takeaways

## Viited ja Edasine Lugemine (References)
- Official documentation links
- Best practices guides

---

**Viimane uuendus:** YYYY-MM-DD
**Seos laboritega:** Lab X (topic)
**Eelmine peatükk:** XX-Previous.md
**Järgmine peatükk:** XX-Next.md
```

---

## Terminology Standards (CRITICAL!)

**MUST READ AND FOLLOW:** `TERMINOLOOGIA.md`

### Core Principle
Use **Estonian terms** with **English in parentheses**:

```
✅ Correct: "Ehita Docker pilt (image) kasutades mitme-sammulist (multi-stage) build'i"
❌ Wrong: "Build Docker image using multi-stage build"
```

### What Stays in English
- Commands: `docker build`, `kubectl apply`, `docker-compose up`
- File names: `Dockerfile`, `package.json`, `.dockerignore`
- Parameters: `--name`, `-p`, `-d`, `--network`
- Code keywords: `FROM`, `WORKDIR`, `COPY`, `RUN`, `CMD`

### Common Terms
| Estonian | English | Example |
|----------|---------|---------|
| ehita | build | Ehita Docker pilt (image) |
| pilt | image | Docker pilt (image) |
| konteiner | container | Docker konteiner |
| andmehoidla | volume | PostgreSQL andmehoidla (volume) |
| võrk | network | Docker võrk (network) |
| kiht | layer | Iga RUN käsk loob kihi (layer) |

### New Terms
When encountering new technical terms not in TERMINOLOOGIA.md:
1. **Ask user:** Should this be added to TERMINOLOOGIA.md?
2. **Propose:** Estonian translation + English original + usage example
3. **Add to file** after approval to maintain consistency

---

## Creating New Training Materials

### Step 1: Check Master Plan
Read `DEVOPS-KOOLITUSKAVA-PLAAN-2025.md` for:
- Chapter specifications
- Learning objectives
- Related labs
- Prerequisites

### Step 2: File Placement
**Location:** `/home/janek/projects/hostinger/resource/`
**Naming:** `XX-Title-With-Dashes.md`
**Examples:**
- `07-Docker-Imagite-Haldamine-Optimeerimine.md`
- `10-Kubernetes-Sissejuhatus.md`

### Step 3: Follow Template
Use the mandatory chapter structure above (70% theory, 30% examples)

### Step 4: Terminology Review
1. Check every technical term against `TERMINOLOOGIA.md`
2. For new terms, ask user before adding
3. Keep Estonian text with English terms in parentheses

### Step 5: Quality Checklist
Before completing a chapter, verify:
- [ ] Learning objectives clear (3-5 items)
- [ ] Key concepts defined (Estonian + English)
- [ ] Theory section substantial (70%)
- [ ] All code examples tested and working
- [ ] Troubleshooting covers real scenarios
- [ ] Best practices included
- [ ] Terminology consistent with TERMINOLOOGIA.md
- [ ] Lab references correct
- [ ] Metadata complete (dates, prev/next chapter)
- [ ] Estonian spelling correct

### Step 6: Update Progress
After completing a chapter:
1. Update `DEVOPS-KOOLITUSKAVA-PLAAN-2025.md` status: ⏳ → ✅
2. Update progress percentages
3. Update `README.md` if needed

---

## Theory Extraction Pattern ⭐ IMPORTANT

**When lab exercises need extensive theoretical explanations:**

### Pattern to Follow
1. **Extract theory to a dedicated chapter** in `resource/`
2. **Keep brief summary in lab** (comparison table, key points)
3. **Add reference link** from lab to theory chapter
4. **Update master plan** to include new chapter

### Example (Lab 2, Exercise 3)
**Situation:** Exercise needed 136 lines explaining production vs development port configurations

**Solution Applied:**
1. ✅ Created: `resource/08A-Docker-Compose-Production-Development-Seadistused.md` (15 pages)
2. ✅ Lab kept: Comparison table + reference link to chapter
3. ✅ Updated: `DEVOPS-KOOLITUSKAVA-PLAAN-2025.md` with chapter 8A details
4. ✅ Updated: `README.md` progress tracking

**Result:** Theory reusable across multiple labs, exercise remains focused on practice

### When to Apply This Pattern
Apply when:
- ✅ Lab explanation exceeds 50-100 lines
- ✅ Content is conceptual/theoretical rather than step-by-step
- ✅ Same concepts apply to multiple scenarios
- ✅ Topic deserves standalone reference material
- ✅ User requests: "Kas selle saaks panna koolituskavas hoopis kuhugile?"

**DO NOT apply when:**
- ❌ Content is purely procedural (do step 1, 2, 3...)
- ❌ Specific to this exact lab exercise only
- ❌ Already covered in existing chapters

### Checklist for Theory Extraction
When extracting theory from lab to training materials:
- [ ] Create chapter file in `resource/` with descriptive name
- [ ] Add chapter to `DEVOPS-KOOLITUSKAVA-PLAAN-2025.md` (under correct FAAS)
- [ ] Replace long explanation in lab with:
  - [ ] Brief comparison table or bullet points
  - [ ] Link to theory chapter: `[Peatükk XXX: Title](../../../resource/XX-Title.md)`
  - [ ] Short context: what theory chapter covers
- [ ] Update `README.md` with new chapter (if FAAS 2 or major)
- [ ] Update progress tracking in both files
- [ ] Verify link works from lab exercise

**Template for lab reference section:**
```markdown
### 📚 Põhjalik Teooria

**💡 Täielik selgitus:**

👉 **Loe enne jätkamist:** [Peatükk XXX: Title](../../../resource/XX-Title.md)

**See peatükk käsitleb:**
- ✅ Topic 1
- ✅ Topic 2
- ✅ Topic 3

---

### 📝 Lühikokkuvõte

| Aspekt | Variant A | Variant B |
|--------|-----------|-----------|
| ... | ... | ... |
```

---

## Chapter-Lab Mapping

Each lab depends on specific theory chapters:

| Lab | Duration | Topics | Supporting Chapters |
|-----|----------|--------|-------------------|
| **Lab 1** | 4h | Docker basics, multi-stage builds | 5, 6, 6A, 7 |
| **Lab 2** | 5.25h | Docker Compose, PostgreSQL | 8, 8A, 9 |
| **Lab 3** | 5h | Kubernetes basics | 10-16 |
| **Lab 4** | 5h | Ingress, HPA, Helm | 17-19 |
| **Lab 5** | 4h | CI/CD with GitHub Actions | 20, 21 |
| **Lab 6** | 4h | Prometheus, Grafana, Loki | 22-24 |
| **Lab 7** | 5h | Security, Vault, RBAC | 25-27 |
| **Lab 8** | 5h | GitOps with ArgoCD | 28 |
| **Lab 9** | 5h | Backup & Disaster Recovery | 29 |
| **Lab 10** | 5h | Terraform IaC | 30 |

**Learning Path:** Read chapter → Do lab → Verify understanding

---

## Working with Labs

For lab-specific guidance (apps, exercises, reset scripts, testing), see:
**`/home/janek/projects/hostinger/labs/CLAUDE.md`**

This file (root CLAUDE.md) focuses on theory chapter creation.

---

## Important Rules

### DO
- ✅ Create all chapters in `resource/` directory
- ✅ Follow the mandatory template structure
- ✅ Keep terminology consistent with TERMINOLOOGIA.md
- ✅ Test all code examples before including
- ✅ Update progress in DEVOPS-KOOLITUSKAVA-PLAAN-2025.md
- ✅ Ask about new technical terms before adding to TERMINOLOOGIA.md

### DON'T
- ❌ Create chapters in root directory
- ❌ Write chapters in English (should be 90%+ Estonian)
- ❌ Use technical terms without checking TERMINOLOOGIA.md
- ❌ Skip the quality checklist
- ❌ Create chapters that don't link to labs
- ❌ Include untested code examples

---

## Language Guidelines

**Primary language:** Estonian (explanations, instructions, theory)
**Technical terms:** English in parentheses after Estonian
**Commands:** English unchanged
**File names:** Original (Dockerfile, package.json)

**Pattern:**
```
Eesti sõna (English term) kasutades command käsku

Examples:
- Loo Docker pilt (image) kasutades docker build käsku
- Käivita konteiner taustal töötavas režiimis (detached mode)
- Iga RUN käsk loob uue kihi (layer), mis salvestatakse vahemällu (cache)
```

---

## Essential Files Reference

| File | Purpose | When to Read |
|------|---------|-------------|
| `DEVOPS-KOOLITUSKAVA-PLAAN-2025.md` | Chapter specifications, timeline | Before writing chapters |
| `TERMINOLOOGIA.md` | Terminology standards | Before writing ANY content |
| `README.md` | Program overview | For general context |
| `labs/CLAUDE.md` | Lab-specific guidance | When working with labs |
| `labs/apps/ARHITEKTUUR.md` | Microservices architecture | Understanding services |

---

## Current Priority (2025-01-25)

**Completed chapters (FAAS 2):**
1. ✅ Peatükk 5: Docker Põhimõtted (16 pages)
2. ✅ Peatükk 6: Dockerfile Detailid (18 pages)
3. ✅ Peatükk 6A: Java/Spring Boot ja Node.js Spetsiifika (20 pages)
4. ✅ Peatükk 8A: Production vs Development Seadistused (15 pages)

**Next chapters to create:**
1. Peatükk 7: Docker Image'ite Haldamine ja Optimeerimine (6-8 pages)
2. Peatükk 8: Docker Compose (8-10 pages)
3. Peatükk 9: PostgreSQL Konteinerites (5-7 pages)

**After FAAS 2 complete:**
- Test chapters 5-9 with Lab 1-2
- Verify all topics covered
- Start FAAS 3 (Kubernetes chapters 10-17)

---

**Repository Type:** DevOps Training Program (Theory + Labs)
**Language:** Estonian (primary) + English (technical terms)
**Status:** In Progress (FAAS 2: 57% complete - 4/7 chapters)
**Last Updated:** 2025-01-25
