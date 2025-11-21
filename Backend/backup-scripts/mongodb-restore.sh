#!/bin/bash

# MongoDB Restore Script for Community Calendar
# Usage: ./mongodb-restore.sh <backup-file.tar.gz>

if [ -z "$1" ]; then
    echo "❌ Error: Please provide a backup file"
    echo "Usage: ./mongodb-restore.sh <backup-file.tar.gz>"
    exit 1
fi

BACKUP_FILE="$1"
MONGODB_URI="${MONGODB_URI:-mongodb://localhost:27017}"
DATABASE_NAME="community_calendar"
TEMP_DIR="/tmp/mongodb-restore-$$"

if [ ! -f "$BACKUP_FILE" ]; then
    echo "❌ Error: Backup file not found: $BACKUP_FILE"
    exit 1
fi

echo "🔄 Starting MongoDB restore..."
echo "📂 Backup file: $BACKUP_FILE"
echo "📍 Database: $DATABASE_NAME"

# Create temp directory
mkdir -p "$TEMP_DIR"

# Extract backup
echo "📦 Extracting backup..."
tar -xzf "$BACKUP_FILE" -C "$TEMP_DIR"

# Find the backup directory
BACKUP_SUBDIR=$(find "$TEMP_DIR" -name "$DATABASE_NAME" -type d | head -n 1)

if [ -z "$BACKUP_SUBDIR" ]; then
    echo "❌ Error: Could not find database backup in archive"
    rm -rf "$TEMP_DIR"
    exit 1
fi

# Restore database
echo "🔄 Restoring database..."
mongorestore --uri="$MONGODB_URI" --db="$DATABASE_NAME" --drop "$BACKUP_SUBDIR"

if [ $? -eq 0 ]; then
    echo "✅ Restore completed successfully!"
else
    echo "❌ Restore failed!"
    rm -rf "$TEMP_DIR"
    exit 1
fi

# Cleanup
rm -rf "$TEMP_DIR"

echo "🎉 All done!"
