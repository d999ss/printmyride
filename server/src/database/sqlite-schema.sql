-- Multi-user PrintMyRide database schema (SQLite version)
-- Compatible with Strava's Nov 2024 API requirements

-- App users (our own user system)
CREATE TABLE IF NOT EXISTS users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    email TEXT UNIQUE NOT NULL,
    name TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Passwordless login tokens (magic links)
CREATE TABLE IF NOT EXISTS login_tokens (
    token TEXT PRIMARY KEY,
    email TEXT NOT NULL,
    expires_at DATETIME NOT NULL,
    used BOOLEAN DEFAULT FALSE,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Map our users to external provider identities
CREATE TABLE IF NOT EXISTS user_identities (
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    provider TEXT NOT NULL,           -- 'strava'
    provider_user_id INTEGER NOT NULL, -- Strava athlete_id
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (provider, provider_user_id)
);

-- Strava OAuth tokens per athlete
CREATE TABLE IF NOT EXISTS strava_tokens (
    athlete_id INTEGER PRIMARY KEY,
    access_token TEXT NOT NULL,
    refresh_token TEXT NOT NULL,
    expires_at INTEGER NOT NULL,       -- Unix timestamp
    token_type TEXT DEFAULT 'Bearer',
    scope TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Cached Strava activities (privacy: each user sees only their own)
CREATE TABLE IF NOT EXISTS strava_activities (
    id INTEGER PRIMARY KEY,            -- Strava activity ID
    athlete_id INTEGER NOT NULL REFERENCES strava_tokens(athlete_id) ON DELETE CASCADE,
    payload TEXT NOT NULL,           -- Raw Strava activity JSON
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Optional: Download links for async GPX exports
CREATE TABLE IF NOT EXISTS download_links (
    token TEXT PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    file_path TEXT NOT NULL,
    expires_at DATETIME NOT NULL,
    used BOOLEAN DEFAULT FALSE,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_login_tokens_expires ON login_tokens(expires_at);
CREATE INDEX IF NOT EXISTS idx_user_identities_user_id ON user_identities(user_id);
CREATE INDEX IF NOT EXISTS idx_strava_activities_athlete_id ON strava_activities(athlete_id);
CREATE INDEX IF NOT EXISTS idx_strava_activities_created ON strava_activities(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_download_links_expires ON download_links(expires_at);