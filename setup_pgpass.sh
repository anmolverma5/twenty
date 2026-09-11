#!/usr/bin/env bash
set -e
echo "localhost:5432:*:postgres:postgres" > ~/.pgpass
echo "127.0.0.1:5432:*:postgres:postgres" >> ~/.pgpass
chmod 600 ~/.pgpass

psql -h localhost -p 5432 -U postgres -d default -c "SELECT name FROM pg_available_extensions WHERE name IN ('uuid-ossp', 'unaccent', 'citext');"
