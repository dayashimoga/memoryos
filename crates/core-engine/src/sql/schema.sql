-- MemoryOS SQLite Schema (schema.sql)
-- Applied via run_migrations() in database.rs

CREATE TABLE IF NOT EXISTS files (
    id                TEXT PRIMARY KEY,
    path              TEXT NOT NULL UNIQUE,
    filename          TEXT NOT NULL,
    extension         TEXT NOT NULL DEFAULT '',
    file_type         TEXT NOT NULL DEFAULT '"Unknown"',
    size_bytes        INTEGER NOT NULL DEFAULT 0,
    sha256_hash       TEXT,
    phash             TEXT,
    ocr_text          TEXT,
    summary           TEXT,
    embedding_id      INTEGER,
    is_encrypted      INTEGER NOT NULL DEFAULT 0,
    indexing_status   TEXT NOT NULL DEFAULT '"Pending"',
    created_at        TEXT NOT NULL,
    modified_at       TEXT NOT NULL,
    indexed_at        TEXT
);

CREATE INDEX IF NOT EXISTS idx_files_path ON files(path);
CREATE INDEX IF NOT EXISTS idx_files_extension ON files(extension);
CREATE INDEX IF NOT EXISTS idx_files_indexing_status ON files(indexing_status);
CREATE INDEX IF NOT EXISTS idx_files_sha256 ON files(sha256_hash);
CREATE INDEX IF NOT EXISTS idx_files_phash ON files(phash);

CREATE VIRTUAL TABLE IF NOT EXISTS files_fts USING fts5(
    id,
    filename,
    ocr_text,
    summary,
    content='files',
    content_rowid='rowid'
);

CREATE TABLE IF NOT EXISTS tags (
    id         TEXT PRIMARY KEY,
    name       TEXT NOT NULL UNIQUE,
    color      TEXT,
    created_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS file_tags (
    file_id TEXT NOT NULL REFERENCES files(id) ON DELETE CASCADE,
    tag_id  TEXT NOT NULL REFERENCES tags(id) ON DELETE CASCADE,
    PRIMARY KEY (file_id, tag_id)
);

CREATE INDEX IF NOT EXISTS idx_file_tags_file ON file_tags(file_id);
CREATE INDEX IF NOT EXISTS idx_file_tags_tag ON file_tags(tag_id);

CREATE TABLE IF NOT EXISTS collections (
    id          TEXT PRIMARY KEY,
    name        TEXT NOT NULL,
    description TEXT,
    icon        TEXT,
    file_count  INTEGER NOT NULL DEFAULT 0,
    created_at  TEXT NOT NULL,
    updated_at  TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS collection_files (
    collection_id TEXT NOT NULL REFERENCES collections(id) ON DELETE CASCADE,
    file_id       TEXT NOT NULL REFERENCES files(id) ON DELETE CASCADE,
    added_at      TEXT NOT NULL,
    PRIMARY KEY (collection_id, file_id)
);

CREATE TABLE IF NOT EXISTS user_settings (
    key   TEXT PRIMARY KEY,
    value TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS activity_log (
    id         INTEGER PRIMARY KEY AUTOINCREMENT,
    event_type TEXT NOT NULL,
    file_id    TEXT REFERENCES files(id) ON DELETE SET NULL,
    detail     TEXT,
    occurred_at TEXT NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_activity_occurred ON activity_log(occurred_at DESC);

CREATE TABLE IF NOT EXISTS knowledge_graph_nodes (
    id         TEXT PRIMARY KEY,
    node_type  TEXT NOT NULL,
    label      TEXT NOT NULL,
    properties TEXT
);

CREATE TABLE IF NOT EXISTS knowledge_graph_edges (
    id            INTEGER PRIMARY KEY AUTOINCREMENT,
    source_id     TEXT NOT NULL REFERENCES knowledge_graph_nodes(id) ON DELETE CASCADE,
    target_id     TEXT NOT NULL REFERENCES knowledge_graph_nodes(id) ON DELETE CASCADE,
    relationship  TEXT NOT NULL,
    weight        REAL NOT NULL DEFAULT 1.0
);

CREATE INDEX IF NOT EXISTS idx_kg_edges_source ON knowledge_graph_edges(source_id);
CREATE INDEX IF NOT EXISTS idx_kg_edges_target ON knowledge_graph_edges(target_id);

CREATE TABLE IF NOT EXISTS ai_models (
    id           TEXT PRIMARY KEY,
    name         TEXT NOT NULL,
    family       TEXT NOT NULL,
    size_bytes   INTEGER,
    file_path    TEXT,
    is_active    INTEGER NOT NULL DEFAULT 0,
    downloaded_at TEXT
);

CREATE TABLE IF NOT EXISTS flashcards (
    id           TEXT PRIMARY KEY,
    file_id      TEXT REFERENCES files(id) ON DELETE CASCADE,
    front        TEXT NOT NULL,
    back         TEXT NOT NULL,
    ease_factor  REAL NOT NULL DEFAULT 2.5,
    interval_days INTEGER NOT NULL DEFAULT 1,
    next_review  TEXT NOT NULL,
    created_at   TEXT NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_flashcards_next_review ON flashcards(next_review);
