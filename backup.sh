#!/bin/bash

# V Rising ARM64 Backup Script
# Creates timestamped backups of save data with rotation

set -e

# Configuration
BACKUP_DIR="${BACKUP_DIR:-/data/backups}"
SAVE_DIR="${SAVE_DIR:-/data/save-data}"
MAX_BACKUPS="${MAX_BACKUPS:-7}"  # Keep last 7 backups
BACKUP_PREFIX="vrising-backup"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

# Check if save directory exists and has content
if [ ! -d "$SAVE_DIR" ]; then
    log_error "Save directory $SAVE_DIR does not exist!"
    exit 1
fi

if [ -z "$(ls -A $SAVE_DIR 2>/dev/null)" ]; then
    log_warn "Save directory $SAVE_DIR is empty. Nothing to backup."
    exit 0
fi

# Create timestamp for backup
TIMESTAMP=$(date '+%Y%m%d_%H%M%S')
BACKUP_NAME="${BACKUP_PREFIX}_${TIMESTAMP}.tar.gz"
BACKUP_PATH="${BACKUP_DIR}/${BACKUP_NAME}"

# Create the backup
log_info "Creating backup: $BACKUP_NAME"
log_info "Source: $SAVE_DIR"
log_info "Destination: $BACKUP_PATH"

if tar -czf "$BACKUP_PATH" -C "$(dirname $SAVE_DIR)" "$(basename $SAVE_DIR)"; then
    BACKUP_SIZE=$(du -h "$BACKUP_PATH" | cut -f1)
    log_info "Backup created successfully! Size: $BACKUP_SIZE"
else
    log_error "Backup failed!"
    exit 1
fi

# Rotate old backups (keep only MAX_BACKUPS)
log_info "Rotating backups (keeping last $MAX_BACKUPS)..."

BACKUP_COUNT=$(ls -1 "${BACKUP_DIR}/${BACKUP_PREFIX}"*.tar.gz 2>/dev/null | wc -l)

if [ "$BACKUP_COUNT" -gt "$MAX_BACKUPS" ]; then
    REMOVE_COUNT=$((BACKUP_COUNT - MAX_BACKUPS))
    log_info "Removing $REMOVE_COUNT old backup(s)..."
    
    ls -1t "${BACKUP_DIR}/${BACKUP_PREFIX}"*.tar.gz | tail -n "$REMOVE_COUNT" | while read old_backup; do
        log_info "Removing: $(basename $old_backup)"
        rm -f "$old_backup"
    done
fi

# Show current backups
log_info "Current backups:"
ls -lh "${BACKUP_DIR}/${BACKUP_PREFIX}"*.tar.gz 2>/dev/null || log_warn "No backups found"

# Calculate total backup size
TOTAL_SIZE=$(du -sh "$BACKUP_DIR" 2>/dev/null | cut -f1)
log_info "Total backup storage used: $TOTAL_SIZE"

log_info "Backup complete!"
