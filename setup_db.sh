#!/usr/bin/env bash
set -e
SUDOPW="Kasahai12@"

echo "$SUDOPW" | sudo -S -u postgres psql -c "ALTER USER postgres WITH PASSWORD 'postgres';"
echo "$SUDOPW" | sudo -S -u postgres psql -c "\l"

# Create default and test databases if they don't exist
PGPASSWORD=postgres psql -h localhost -p 5432 -U postgres -d postgres -tc "SELECT 1 FROM pg_database WHERE datname='default'" | grep -q 1 || PGPASSWORD=postgres createdb -h localhost -p 5432 -U postgres default
PGPASSWORD=postgres psql -h localhost -p 5432 -U postgres -d postgres -tc "SELECT 1 FROM pg_database WHERE datname='test'" | grep -q 1 || PGPASSWORD=postgres createdb -h localhost -p 5432 -U postgres test

echo "Databases verified:"
PGPASSWORD=postgres psql -h localhost -p 5432 -U postgres -d postgres -tc "SELECT datname FROM pg_database;"
