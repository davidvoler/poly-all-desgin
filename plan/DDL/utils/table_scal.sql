SELECT
  schemaname,
  relname,
  seq_scan,
  seq_tup_read,
  idx_scan,
  seq_tup_read / GREATEST(seq_scan, 1) AS avg_rows_per_seq_scan,
  n_live_tup AS est_rows
FROM pg_stat_user_tables
WHERE seq_scan > 0
ORDER BY seq_tup_read DESC
LIMIT 20;
