export const PFT_DATABASE_NAME = 'pft_local'
export const PFT_DATABASE_VERSION = 1

export const PFT_SCHEMA = `
PRAGMA foreign_keys = ON;

CREATE TABLE IF NOT EXISTS sites (
  id TEXT PRIMARY KEY NOT NULL,
  name TEXT NOT NULL,
  client TEXT NOT NULL DEFAULT '',
  address TEXT NOT NULL DEFAULT '',
  start_date TEXT NOT NULL DEFAULT '',
  end_date TEXT NOT NULL DEFAULT '',
  status TEXT NOT NULL,
  created_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS workers (
  id TEXT PRIMARY KEY NOT NULL,
  name TEXT NOT NULL,
  phone TEXT NOT NULL DEFAULT '',
  team TEXT NOT NULL DEFAULT '',
  role TEXT NOT NULL,
  daily_rate INTEGER NOT NULL DEFAULT 0,
  active INTEGER NOT NULL DEFAULT 1,
  created_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS attendance_records (
  id TEXT PRIMARY KEY NOT NULL,
  work_date TEXT NOT NULL,
  site_id TEXT NOT NULL,
  worker_id TEXT NOT NULL,
  work_role TEXT NOT NULL DEFAULT 'painter',
  status TEXT NOT NULL,
  start_time TEXT NOT NULL DEFAULT '',
  end_time TEXT NOT NULL DEFAULT '',
  overtime_hours REAL NOT NULL DEFAULT 0,
  daily_rate INTEGER NOT NULL DEFAULT 0,
  note TEXT NOT NULL DEFAULT '',
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  UNIQUE(work_date, site_id, worker_id),
  FOREIGN KEY(site_id) REFERENCES sites(id),
  FOREIGN KEY(worker_id) REFERENCES workers(id)
);

CREATE INDEX IF NOT EXISTS idx_attendance_date_site
  ON attendance_records(work_date, site_id);
CREATE INDEX IF NOT EXISTS idx_attendance_worker
  ON attendance_records(worker_id);
`
