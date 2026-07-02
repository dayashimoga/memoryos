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
    is_favorite       INTEGER NOT NULL DEFAULT 0,
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

-- ── Categories ────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS categories (
    id         TEXT PRIMARY KEY,
    name       TEXT NOT NULL UNIQUE,
    icon       TEXT,
    color      TEXT,
    created_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS file_categories (
    file_id     TEXT NOT NULL REFERENCES files(id) ON DELETE CASCADE,
    category_id TEXT NOT NULL REFERENCES categories(id) ON DELETE CASCADE,
    PRIMARY KEY (file_id, category_id)
);

CREATE INDEX IF NOT EXISTS idx_file_categories_file ON file_categories(file_id);
CREATE INDEX IF NOT EXISTS idx_file_categories_cat ON file_categories(category_id);

-- ── Search history ────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS search_history (
    id         INTEGER PRIMARY KEY AUTOINCREMENT,
    query      TEXT NOT NULL,
    result_count INTEGER NOT NULL DEFAULT 0,
    searched_at TEXT NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_search_history_time ON search_history(searched_at DESC);

-- ── Processing queue ──────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS processing_queue (
    id         INTEGER PRIMARY KEY AUTOINCREMENT,
    file_id    TEXT NOT NULL REFERENCES files(id) ON DELETE CASCADE,
    stage      TEXT NOT NULL DEFAULT 'pending',
    progress   INTEGER NOT NULL DEFAULT 0,
    error      TEXT,
    queued_at  TEXT NOT NULL,
    started_at TEXT,
    completed_at TEXT
);

CREATE INDEX IF NOT EXISTS idx_processing_queue_stage ON processing_queue(stage);

-- ── Timeline index ────────────────────────────────────────────────────────────

CREATE INDEX IF NOT EXISTS idx_files_created_at ON files(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_files_modified_at ON files(modified_at DESC);
CREATE INDEX IF NOT EXISTS idx_files_file_type ON files(file_type);

-- ── FTS triggers (keep FTS index in sync with files table) ────────────────────

CREATE TRIGGER IF NOT EXISTS files_fts_insert AFTER INSERT ON files BEGIN
    INSERT INTO files_fts(rowid, id, filename, ocr_text, summary)
    VALUES (new.rowid, new.id, new.filename, new.ocr_text, new.summary);
END;

CREATE TRIGGER IF NOT EXISTS files_fts_update AFTER UPDATE OF filename, ocr_text, summary ON files BEGIN
    DELETE FROM files_fts WHERE rowid = old.rowid;
    INSERT INTO files_fts(rowid, id, filename, ocr_text, summary)
    VALUES (new.rowid, new.id, new.filename, new.ocr_text, new.summary);
END;

CREATE TRIGGER IF NOT EXISTS files_fts_delete AFTER DELETE ON files BEGIN
    DELETE FROM files_fts WHERE rowid = old.rowid;
END;
