-- =====================================================
-- Todo Service Database Setup
-- =====================================================
-- NOTE: Database is already created by POSTGRES_DB environment variable
-- This script runs inside that database automatically via /docker-entrypoint-initdb.d/
--
-- Selle skripti eesmärk on luua tabelid Todo Service rakenduse jaoks.
--
-- Käsitsi kasutamine Docker'is:
--   docker exec -i postgres-todo psql -U postgres -d todo_service_db < database-setup.sql
-- =====================================================

-- 1. LOO TODOS TABEL
CREATE TABLE IF NOT EXISTS todos (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    completed BOOLEAN DEFAULT FALSE,
    priority VARCHAR(20) DEFAULT 'medium',
    due_date TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    -- Validatsioon: priority saab olla ainult 'low', 'medium' või 'high'
    CONSTRAINT priority_check CHECK (priority IN ('low', 'medium', 'high'))
);

-- 3. LOO INDEKSID (parema jõudluse jaoks)
CREATE INDEX IF NOT EXISTS idx_todos_user_id ON todos(user_id);
CREATE INDEX IF NOT EXISTS idx_todos_completed ON todos(completed);
CREATE INDEX IF NOT EXISTS idx_todos_priority ON todos(priority);
CREATE INDEX IF NOT EXISTS idx_todos_due_date ON todos(due_date);
CREATE INDEX IF NOT EXISTS idx_todos_created_at ON todos(created_at);

-- 4. LOO TRIGGER updated_at automaatseks uuendamiseks
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

DROP TRIGGER IF EXISTS update_todos_updated_at ON todos;
CREATE TRIGGER update_todos_updated_at
    BEFORE UPDATE ON todos
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- 5. LISA NÄIDISANDMED (testimiseks, optsionaalne)
-- Märkus: user_id peab viitama User Service'i kasutajale
-- Kui User Service'is on kasutaja id=1, saad kasutada seda

-- Esmalt kustuta vanad näidisandmed, kui need on olemas
DELETE FROM todos WHERE title IN (
    'Õpi Docker põhitõed',
    'Seadista PostgreSQL',
    'Loo REST API',
    'Implementeeri JWT autentimine',
    'Paigalda Kubernetes'
);

-- Lisa uued näidisandmed
INSERT INTO todos (user_id, title, description, priority, due_date, completed)
VALUES
    (1, 'Õpi Docker põhitõed', 'Läbi töötada Lab 1 harjutused ja õppida konteinerte', 'high', '2025-11-20 18:00:00', false),
    (1, 'Seadista PostgreSQL', 'Paigalda ja konfigureeri PostgreSQL andmebaas VPS serverisse', 'high', '2025-11-18 12:00:00', true),
    (1, 'Loo REST API', 'Välja töötada Node.js backend koos Express raamistikuga', 'medium', '2025-11-22 15:00:00', false),
    (1, 'Implementeeri JWT autentimine', 'Lisa JWT token-põhine autentimine kasutajate jaoks', 'high', '2025-11-19 10:00:00', true),
    (1, 'Paigalda Kubernetes', 'Õpi Kubernetes põhitõed ja paigalda esimene klaster', 'low', NULL, false);
