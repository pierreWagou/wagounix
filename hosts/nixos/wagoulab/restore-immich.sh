#!/usr/bin/env bash
# Restore Immich Postgres data — final approach
#
# The dump was created by Postgres 17 (NixOS native). The Immich container
# runs Postgres 14 which can't read the dump format directly.
#
# Strategy:
#   1. Use a plain postgres:17 container to restore the dump
#   2. Export all tables EXCEPT vector-dependent ones (face_search, smart_search)
#      as plain SQL — these use the vector extension which postgres:17 doesn't have
#   3. Restore the plain SQL into the Immich Postgres 14 container
#   4. Immich will regenerate ML embeddings automatically
#
# Usage: sudo bash /tmp/restore-immich-v2.sh

set -euo pipefail

DUMP="/var/backup/podman-migration-20260427-121634/immich-postgres.dump"
PLAIN_SQL="/var/backup/immich-plain.sql"
TEMP_CONTAINER="pg-restore-temp"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log()  { echo -e "${GREEN}[OK]${NC} $*"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
err()  { echo -e "${RED}[ERROR]${NC} $*"; exit 1; }

[ "$(id -u)" -ne 0 ] && err "Must run as root (sudo)"
[ -f "$DUMP" ] || err "Dump file not found: $DUMP"

echo "=== Immich Postgres Restore (v2) ==="
echo ""

# Clean up any previous temp container
podman rm -f "$TEMP_CONTAINER" 2>/dev/null || true

# Step 1: Ensure Immich stack is running
echo "--- Step 1: Ensuring Immich stack is running ---"
systemctl restart wagoulab-immich 2>/dev/null || true
sleep 10
until podman exec immich-postgres pg_isready -U postgres -q 2>/dev/null; do
  sleep 1
done
log "Immich Postgres is running"

# Step 2: Start Postgres 17 temp container
echo ""
echo "--- Step 2: Starting Postgres 17 temporary container ---"
podman run -d --name "$TEMP_CONTAINER" \
  -e POSTGRES_PASSWORD=postgres \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_DB=immich \
  postgres:17

echo "Waiting for Postgres 17 to be ready..."
until podman exec "$TEMP_CONTAINER" pg_isready -U postgres -q 2>/dev/null; do
  sleep 1
done
log "Postgres 17 temporary container ready"

# Step 3: Restore dump into Postgres 17 (will have vector extension errors — expected)
echo ""
echo "--- Step 3: Restoring dump into Postgres 17 ---"
podman exec -i "$TEMP_CONTAINER" pg_restore \
  --no-owner --no-privileges \
  -d immich -U postgres < "$DUMP" 2>&1 | grep -c "error:" || true
warn "Some errors are expected (vector/vchord extensions not available in plain postgres:17)"
warn "All non-vector tables should be restored correctly"

# Verify what was restored
TABLE_COUNT=$(podman exec "$TEMP_CONTAINER" psql -U postgres -d immich -t -c \
  "SELECT count(*) FROM information_schema.tables WHERE table_schema = 'public';")
ASSET_COUNT=$(podman exec "$TEMP_CONTAINER" psql -U postgres -d immich -t -c \
  "SELECT count(*) FROM asset;" 2>/dev/null || echo "0")
log "Temp container — tables: $TABLE_COUNT, assets: $ASSET_COUNT"

# Step 4: Export as plain SQL, excluding vector tables
echo ""
echo "--- Step 4: Exporting as plain SQL (excluding vector tables) ---"
podman exec "$TEMP_CONTAINER" pg_dump \
  -U postgres --format=plain --no-owner --no-privileges \
  --exclude-table=face_search \
  --exclude-table=smart_search \
  immich > "$PLAIN_SQL"
SQL_SIZE=$(du -h "$PLAIN_SQL" | cut -f1)
log "Exported to $PLAIN_SQL ($SQL_SIZE)"

# Step 5: Clean up temp container
echo ""
echo "--- Step 5: Cleaning up temporary container ---"
podman rm -f "$TEMP_CONTAINER"
log "Temporary container removed"

# Step 6: Stop Immich server, prepare database
echo ""
echo "--- Step 6: Preparing Immich Postgres for restore ---"
podman stop immich-server immich-ml 2>/dev/null || true
log "Stopped Immich server and ML"

podman exec immich-postgres psql -U postgres -c "DROP DATABASE IF EXISTS immich;"
podman exec immich-postgres psql -U postgres -c "CREATE DATABASE immich OWNER postgres;"
# Create the vector extensions that Immich needs
podman exec immich-postgres psql -U postgres -d immich -c "CREATE EXTENSION IF NOT EXISTS vector;"
podman exec immich-postgres psql -U postgres -d immich -c "CREATE EXTENSION IF NOT EXISTS vchord;" 2>/dev/null || true
log "Database recreated with extensions"

# Step 7: Restore plain SQL
echo ""
echo "--- Step 7: Restoring data ---"
ERROR_COUNT=$(podman exec -i immich-postgres psql -U postgres -d immich < "$PLAIN_SQL" 2>&1 | grep -c "ERROR" || true)
if [ "$ERROR_COUNT" -gt 0 ]; then
  warn "$ERROR_COUNT SQL errors (usually harmless — duplicate extensions, etc.)"
else
  log "No errors during restore"
fi

# Step 8: Verify
echo ""
echo "--- Step 8: Verification ---"
TABLE_COUNT=$(podman exec immich-postgres psql -U postgres -d immich -t -c \
  "SELECT count(*) FROM information_schema.tables WHERE table_schema = 'public';")
ASSET_COUNT=$(podman exec immich-postgres psql -U postgres -d immich -t -c \
  "SELECT count(*) FROM asset;" 2>/dev/null || echo "0 (table missing)")
USER_COUNT=$(podman exec immich-postgres psql -U postgres -d immich -t -c \
  "SELECT count(*) FROM users;" 2>/dev/null || echo "0 (table missing)")
ALBUM_COUNT=$(podman exec immich-postgres psql -U postgres -d immich -t -c \
  "SELECT count(*) FROM album;" 2>/dev/null || echo "0 (table missing)")

log "Tables: $TABLE_COUNT"
log "Assets (photos): $ASSET_COUNT"
log "Users: $USER_COUNT"
log "Albums: $ALBUM_COUNT"

# Step 9: Start Immich
echo ""
echo "--- Step 9: Starting Immich ---"
podman start immich-ml immich-server
log "Immich server and ML started"

echo ""
echo "=== Done ==="
echo ""
echo "Check Immich at https://pixel.wagou.fr"
echo ""
echo "Note: face_search and smart_search tables were not restored."
echo "Immich will regenerate ML embeddings automatically — this may take time"
echo "depending on the number of photos. Check the ML container logs:"
echo "  sudo podman logs -f immich-ml"
