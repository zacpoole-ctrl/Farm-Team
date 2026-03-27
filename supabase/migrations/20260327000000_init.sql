-- League state (single row, id=1)
CREATE TABLE IF NOT EXISTS league_state (
  id int PRIMARY KEY,
  data jsonb NOT NULL,
  updated_at timestamptz DEFAULT now(),
  updated_by text
);

-- Activity log
CREATE TABLE IF NOT EXISTS activity_log (
  id bigserial PRIMARY KEY,
  ts timestamptz DEFAULT now(),
  type text,
  actor text,
  details text
);

-- Trade proposals
CREATE TABLE IF NOT EXISTS trade_proposals (
  id text PRIMARY KEY,
  ts timestamptz DEFAULT now(),
  proposed_by text,
  status text DEFAULT 'pending',
  side1 jsonb,
  side2 jsonb
);

-- App users
CREATE TABLE IF NOT EXISTS app_users (
  username text PRIMARY KEY,
  password text,
  email text,
  role text,
  owner_id int
);

-- Enable realtime
ALTER PUBLICATION supabase_realtime ADD TABLE league_state;
ALTER PUBLICATION supabase_realtime ADD TABLE activity_log;
ALTER PUBLICATION supabase_realtime ADD TABLE trade_proposals;
