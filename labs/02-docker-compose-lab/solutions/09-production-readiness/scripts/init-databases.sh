#!/bin/bash
# Database Initialization Script for Production Stack
# Creates PostgreSQL volumes and initializes database schemas

set -e  # Exit on error

echo "========================================="
echo "Database Initialization Script"
echo "========================================="
echo ""

# Load environment variables
if [ -f .env.prod ]; then
    source .env.prod
    echo "✅ Loaded .env.prod"
else
    echo "⚠️  .env.prod not found, using defaults"
    DB_PASSWORD="dbpass123"
fi

echo ""
echo "Creating PostgreSQL volumes..."

# Create volumes
docker volume create postgres-user-data-prod || true
docker volume create postgres-todo-data-prod || true

echo "✅ Volumes created"
echo ""

# Start temporary PostgreSQL containers for initialization
echo "Starting temporary PostgreSQL containers..."

docker run -d --name temp-postgres-user \
  -e POSTGRES_USER=dbuser \
  -e POSTGRES_PASSWORD=${DB_PASSWORD} \
  -e POSTGRES_DB=user_service_db \
  -v postgres-user-data-prod:/var/lib/postgresql/data \
  postgres:16-alpine

docker run -d --name temp-postgres-todo \
  -e POSTGRES_USER=dbuser \
  -e POSTGRES_PASSWORD=${DB_PASSWORD} \
  -e POSTGRES_DB=todo_service_db \
  -v postgres-todo-data-prod:/var/lib/postgresql/data \
  postgres:16-alpine

echo "✅ Temporary containers started"
echo ""
echo "Waiting for PostgreSQL to be ready (15 seconds)..."
sleep 15

# Initialize user service database
echo ""
echo "Initializing user_service_db schema..."

docker exec -it temp-postgres-user psql -U dbuser -d user_service_db <<'EOF'
CREATE TABLE IF NOT EXISTS users (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    role VARCHAR(50) DEFAULT 'USER',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);

-- Insert test data (optional - remove in production)
INSERT INTO users (name, email, password, role)
VALUES ('Admin User', 'admin@example.com', '$2b$10$YourHashedPasswordHere', 'ADMIN')
ON CONFLICT (email) DO NOTHING;
EOF

echo "✅ user_service_db initialized"

# Initialize todo service database
echo ""
echo "Initializing todo_service_db schema..."

docker exec -it temp-postgres-todo psql -U dbuser -d todo_service_db <<'EOF'
CREATE TABLE IF NOT EXISTS todos (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    completed BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_todos_user_id ON todos(user_id);
CREATE INDEX IF NOT EXISTS idx_todos_completed ON todos(completed);

-- Trigger to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_todos_updated_at BEFORE UPDATE ON todos
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
EOF

echo "✅ todo_service_db initialized"

# Clean up temporary containers
echo ""
echo "Cleaning up temporary containers..."

docker stop temp-postgres-user temp-postgres-todo
docker rm temp-postgres-user temp-postgres-todo

echo "✅ Cleanup complete"
echo ""
echo "========================================="
echo "✅ Database initialization successful!"
echo "========================================="
echo ""
echo "Volumes created:"
echo "  - postgres-user-data-prod"
echo "  - postgres-todo-data-prod"
echo ""
echo "Next steps:"
echo "  1. Review .env.prod settings"
echo "  2. Generate SSL certificates: cd nginx/ssl && ./generate-ssl.sh"
echo "  3. Start production stack: docker compose -f docker-compose.prod.yml up -d"
