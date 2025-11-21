#!/bin/bash

# MongoDB Backup Script for Community Calendar
# Usage: ./mongodb-backup.sh

# Configuration
MONGODB_URI="${MONGODB_URI:-mongodb://localhost:27017}"
DATABASE_NAME="community_calendar"
BACKUP_DIR="${BACKUP_DIR:-$HOME/backups/mongodb}"
DATE=$(date +%Y-%m-%d-%H%M%S)
BACKUP_PATH="$BACKUP_DIR/$DATABASE_NAME-$DATE"
RETENTION_DAYS=7  # Keep backups for 7 days

# Create backup directory
mkdir -p "$BACKUP_DIR"

echo "🗄️  Starting MongoDB backup..."
echo "📍 Database: $DATABASE_NAME"
echo "📂 Backup location: $BACKUP_PATH"

# Perform backup
mongodump --uri="$MONGODB_URI" --db="$DATABASE_NAME" --out="$BACKUP_PATH"

if [ $? -eq 0 ]; then
    echo "✅ Backup completed successfully!"

    # Compress backup
    echo "📦 Compressing backup..."
    cd "$BACKUP_DIR"
    tar -czf "$DATABASE_NAME-$DATE.tar.gz" "$DATABASE_NAME-$DATE"
    rm -rf "$DATABASE_NAME-$DATE"

    echo "✅ Backup compressed: $DATABASE_NAME-$DATE.tar.gz"

    # Remove old backups
    echo "🗑️  Removing backups older than $RETENTION_DAYS days..."
    find "$BACKUP_DIR" -name "$DATABASE_NAME-*.tar.gz" -mtime +$RETENTION_DAYS -delete

    echo "✅ Cleanup completed!"
else
    echo "❌ Backup failed!"
    exit 1
fi

# Optional: Upload to cloud storage
# Uncomment and configure for your cloud provider

# AWS S3
# aws s3 cp "$BACKUP_DIR/$DATABASE_NAME-$DATE.tar.gz" s3://your-bucket/backups/

# Google Cloud Storage
# gsutil cp "$BACKUP_DIR/$DATABASE_NAME-$DATE.tar.gz" gs://your-bucket/backups/

# Azure Blob Storage
# az storage blob upload --account-name youraccount --container-name backups --file "$BACKUP_DIR/$DATABASE_NAME-$DATE.tar.gz"

echo "🎉 All done!"
