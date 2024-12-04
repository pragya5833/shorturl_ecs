-- Ensure the schema exists without recreating it
CREATE SCHEMA IF NOT EXISTS deeplink;

-- Drop existing tables if they exist (optional: remove in production to avoid data loss)
DROP TABLE IF EXISTS deeplink.url_hits;
DROP TABLE IF EXISTS deeplink.urls;
DROP TABLE IF EXISTS deeplink.users;

-- Create users table
CREATE TABLE deeplink.users (
  id SERIAL PRIMARY KEY,
  google_id VARCHAR(255) UNIQUE,
  email VARCHAR(255) UNIQUE,
  name VARCHAR(255),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create urls table with a foreign key reference to the users table
CREATE TABLE deeplink.urls (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL REFERENCES deeplink.users(id),
  short_url VARCHAR(10) UNIQUE NOT NULL,
  android_url TEXT NOT NULL,
  ios_url TEXT NOT NULL,
  web_url TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  is_active BOOLEAN NOT NULL DEFAULT TRUE
);

-- Create url_hits table to track hits on URLs
CREATE TABLE deeplink.url_hits (
  id SERIAL PRIMARY KEY,
  url_id INTEGER NOT NULL REFERENCES deeplink.urls(id),
  platform VARCHAR(50),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Indexes for users table
CREATE INDEX idx_users_google_id ON deeplink.users(google_id);

-- Indexes for urls table
CREATE INDEX idx_urls_user_id ON deeplink.urls(user_id);
CREATE INDEX idx_urls_short_url ON deeplink.urls(short_url);

-- Additional indexes for url_hits table
CREATE INDEX idx_url_hits_url_id ON deeplink.url_hits(url_id);
CREATE INDEX idx_url_hits_created_at ON deeplink.url_hits(created_at);

-- Dummy data insertion for users (adjust or extend as necessary)
INSERT INTO deeplink.users (google_id, email, name) VALUES
('g-001', 'user1@example.com', 'User One'),
('g-002', 'user2@example.com', 'User Two');

-- Dummy data insertion for urls
INSERT INTO deeplink.urls (user_id, short_url, android_url, ios_url, web_url, created_at, updated_at, is_active)
SELECT 
    1 as user_id,
    'short_' || generate_series(1, 100) as short_url,
    'https://android.example.com/' || generate_series(1, 100) as android_url,
    'https://ios.example.com/' || generate_series(1, 100) as ios_url,
    'https://web.example.com/' || generate_series(1, 100) as web_url,
    now() - (random() * (interval '90 days')) as created_at,
    now() - (random() * (interval '30 days')) as updated_at,
    TRUE as is_active;

-- Dummy hit data for each URL
INSERT INTO deeplink.url_hits (url_id, platform, created_at)
SELECT 
    u.id as url_id,
    (ARRAY['android', 'ios', 'web'])[floor(random() * 3 + 1)] as platform,
    u.created_at + (random() * (now() - u.created_at)) as created_at
FROM 
    deeplink.urls u,
    generate_series(1, (random() * 1000)::int); -- Random number of hits for each URL
