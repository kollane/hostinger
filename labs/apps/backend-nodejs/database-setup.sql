-- Create database
CREATE DATABASE user_service_db;

-- Connect to the database
\c user_service_db;

-- Create users table
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    role VARCHAR(20) DEFAULT 'user' CHECK (role IN ('user', 'admin')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for better performance
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_role ON users(role);
CREATE INDEX idx_users_created_at ON users(created_at DESC);

-- Insert sample users
-- Password for all users: password123

-- Admin user
INSERT INTO users (name, email, password, role) VALUES
('Admin User', 'admin@example.com', '$2b$10$YYlz1QfZ3R3X8X0X8X0X8examplehashedpassword1', 'admin');

-- Regular users
INSERT INTO users (name, email, password, role) VALUES
('John Doe', 'john@example.com', '$2b$10$YYlz1QfZ3R3X8X0X8X0X8examplehashedpassword2', 'user'),
('Jane Smith', 'jane@example.com', '$2b$10$YYlz1QfZ3R3X8X0X8X0X8examplehashedpassword3', 'user'),
('Bob Johnson', 'bob@example.com', '$2b$10$YYlz1QfZ3R3X8X0X8X0X8examplehashedpassword4', 'user');

-- Verify tables
\dt

-- Show users
SELECT id, name, email, role, created_at FROM users;
