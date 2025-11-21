# GEMINI.md: Project Overview and Context

This document provides a comprehensive overview of the `hostinger/labs` project, intended as a context file for AI assistants.

## Directory Overview

This repository contains a series of hands-on labs designed for DevOps training. The project is not a single application but rather an educational toolkit. It is structured as a series of labs (`01-docker-lab`, `02-docker-compose-lab`, etc.) that guide the user through various DevOps practices.

The labs use a consistent set of pre-built microservices, which are located in the `apps/` directory. The primary goal is to learn how to deploy, manage, and monitor these applications, not to develop the applications themselves.

**Project Type:** Educational / DevOps Training Labs

---

## Architecture and Key Components

The labs are based on a microservices architecture consisting of three main applications:

1.  **Frontend (`apps/frontend/`)**
    *   **Purpose:** A static web UI for interacting with the backend services.
    *   **Technology:** HTML, CSS, Vanilla JavaScript.
    *   **Port:** `8080`

2.  **User Service (`apps/backend-nodejs/`)**
    *   **Purpose:** A REST API for user management and authentication (JWT).
    *   **Technology:** Node.js, Express.js.
    *   **Port:** `3000`
    *   **Database:** PostgreSQL on port `5432`.

3.  **Todo Service (`apps/backend-java-spring/`)**
    *   **Purpose:** A REST API for managing "todo" items.
    *   **Technology:** Java, Spring Boot, Gradle.
    *   **Port:** `8081`
    *   **Database:** PostgreSQL on port `5433`.

The core of the project lies in the lab directories (`01-*` to `06-*`), which provide step-by-step exercises for containerization, orchestration, CI/CD, and monitoring.

---

## How to Build, Run, and Test

The entire application stack is designed to be run with Docker.

### Running the Full Stack (Recommended)

The easiest way to get all services running is to use the main `docker-compose.yml` file located in the `apps/` directory.

1.  **Navigate to the apps directory:**
    ```bash
    cd apps
    ```

2.  **Start all services in detached mode:**
    ```bash
    docker-compose up -d
    ```

3.  **Check the status of the containers:**
    ```bash
    docker-compose ps
    ```

4.  **View logs:**
    ```bash
    docker-compose logs -f
    ```

5.  **Stop and remove all containers, networks, and volumes:**
    ```bash
t    docker-compose down
    ```

### Health Checks

You can verify that each service is running by accessing its health endpoint:

*   **User Service:** `curl http://localhost:3000/health`
*   **Todo Service:** `curl http://localhost:8081/health`
*   **Frontend:** `curl http://localhost:8080`

---

## Development and Lab Conventions

*   **Focus on DevOps, Not Code:** The application source code in `apps/` is pre-written and complete. The exercises focus exclusively on DevOps tasks like containerizing, deploying, scaling, and monitoring these apps.
*   **Sequential Labs:** The labs are designed to be completed in order, as each one builds upon concepts from the previous one.
*   **Solutions Provided:** Each lab directory contains a `solutions/` subdirectory with working examples and configurations.
*   **Reset Scripts:** Each lab includes a `reset.sh` script to clean up all generated resources (Docker containers, Kubernetes objects, etc.), allowing the user to start fresh.
*   **CI/CD:** The `05-cicd-lab` uses GitHub Actions for building and deploying the applications. The workflow definitions can be found in `.github/workflows/`.
