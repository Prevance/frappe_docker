# Prevance Health — frappe_docker development helpers
#
# Usage (first time on a new machine):
#   make start       # bring up all containers
#   make new-site    # create site + install apps (only needed once per volume)
#
# After a `docker compose down -v` (volumes wiped) you need to re-run new-site.
# A plain `docker compose down` (no -v) keeps the site intact — just `make start`.

COMPOSE_FILES := -f compose.yaml -f docker-compose.override.yml
CONTAINER     := frappe_docker-backend-1
SITE          := frontend
DB_ROOT_PW    := admin
ADMIN_PW      := admin

.PHONY: start stop restart new-site migrate reset-site help

## Bring up all services (detached)
start:
	docker compose $(COMPOSE_FILES) up -d

## Stop all services (volumes are preserved)
stop:
	docker compose $(COMPOSE_FILES) down

## Stop and restart
restart: stop start

## Create the site and install all apps (run once after `make start` on a clean volume)
##
## Safe to re-run: bench new-site will fail gracefully if the site already exists,
## install-app is idempotent, and migrate is always safe to re-run.
new-site:
	@echo ">>> Creating site '$(SITE)' ..."
	docker exec $(CONTAINER) bench new-site $(SITE) \
		--mariadb-root-password $(DB_ROOT_PW) \
		--admin-password $(ADMIN_PW) \
		--install-app frappe \
		|| echo "(site already exists — skipping new-site)"
	@echo ">>> Installing erpnext ..."
	docker exec $(CONTAINER) bench --site $(SITE) install-app erpnext \
		|| echo "(erpnext already installed — skipping)"
	@echo ">>> Installing prevance_health ..."
	docker exec $(CONTAINER) bench --site $(SITE) install-app prevance_health \
		|| echo "(prevance_health already installed — skipping)"
	@echo ">>> Running migrate ..."
	docker exec $(CONTAINER) bench --site $(SITE) migrate
	@echo ">>> Done. Site is ready at http://localhost:8080"

## Run bench migrate on the site (use after pulling new app code)
migrate:
	docker exec $(CONTAINER) bench --site $(SITE) migrate

## Wipe the site volume and start fresh (destructive — loses all data)
reset-site:
	docker compose $(COMPOSE_FILES) down -v
	$(MAKE) start
	$(MAKE) new-site

help:
	@grep -E '^##' Makefile | sed 's/## //'
