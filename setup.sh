#!/bin/sh
docker compose pull
docker compose build
docker compose run inferno_web bundle exec rake web:generate
docker compose run inferno_web /opt/inferno/migrate.sh
