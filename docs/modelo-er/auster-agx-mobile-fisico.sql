-- Modelo físico do cache offline do AusterAgX Mobile.
-- Arquivo gerado por scripts/gerar-modelos-er.mjs a partir de
-- lib/data/local/app_database.dart. Não edite manualmente.
--
-- Cada usuário autenticado possui um arquivo SQLite próprio, nomeado com o
-- hash SHA-256 do identificador. O cache não declara FOREIGN KEY: os vínculos
-- são lógicos e os payloads preservam o contrato da API. Tokens e perfil
-- autenticado ficam no flutter_secure_storage, fora do SQLite.

CREATE TABLE IF NOT EXISTS dashboard_items (
  id TEXT PRIMARY KEY,
  payload TEXT NOT NULL,
  updated_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS dashboard_overview (
  id INTEGER PRIMARY KEY CHECK (id = 1),
  payload TEXT NOT NULL,
  updated_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS demanda_details (
  id TEXT PRIMARY KEY,
  payload TEXT NOT NULL,
  updated_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS demanda_status_history (
  demanda_id TEXT PRIMARY KEY,
  payload TEXT NOT NULL,
  updated_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS status_fluxo (
  id INTEGER PRIMARY KEY CHECK (id = 1),
  payload TEXT NOT NULL,
  updated_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS sync_queue (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  operation_type TEXT NOT NULL,
  entity TEXT NOT NULL,
  entity_id TEXT NOT NULL,
  payload TEXT NOT NULL,
  created_at TEXT NOT NULL,
  attempts INTEGER NOT NULL DEFAULT 0,
  status TEXT NOT NULL DEFAULT 'pending'
);

CREATE TABLE IF NOT EXISTS location_captures (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  demanda_id TEXT NOT NULL,
  latitude REAL NOT NULL,
  longitude REAL NOT NULL,
  accuracy REAL,
  captured_at TEXT NOT NULL
);
