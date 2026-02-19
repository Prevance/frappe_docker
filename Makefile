# Prevance Health — frappe_docker development helpers
#
# Usage (first time on a new machine):
#   make reset-site   # clean rebuild: wipe volumes, start stack, install prevance_health
#
# After a plain `docker compose down` (no -v, volumes kept):
#   make start        # bring services back up — site data is intact
#
# After pulling new app code:
#   make migrate      # run bench migrate to pick up schema changes
#
# Run integration tests (T067):
#   make test

COMPOSE_FILES := -f pwd.yml -f docker-compose.override.yml
CONTAINER     := frappe_docker-backend-1
SITE          := frontend

.PHONY: start stop restart new-site migrate reset-site test help

## Bring up all services (detached)
start:
	docker compose $(COMPOSE_FILES) up -d

## Stop all services (volumes are preserved)
stop:
	docker compose $(COMPOSE_FILES) down

## Stop and restart
restart: stop start

## Install prevance_health into a running site (idempotent — safe to re-run)
##
## Use after `make start` on an already-created site to ensure prevance_health
## is pip-installed and migrated. The pwd.yml create-site only installs erpnext;
## this target adds prevance_health on top.
new-site:
	@echo ">>> pip-installing prevance_health and coverage into backend ..."
	docker exec $(CONTAINER) /home/frappe/frappe-bench/env/bin/pip install -q -e /home/frappe/frappe-bench/apps/prevance_health coverage
	@echo ">>> Installing prevance_health on site '$(SITE)' ..."
	docker exec $(CONTAINER) bench --site $(SITE) install-app prevance_health \
		|| echo "(prevance_health already installed — skipping)"
	@echo ">>> Running migrate ..."
	docker exec $(CONTAINER) bench --site $(SITE) migrate
	@echo ">>> Enabling tests ..."
	docker exec $(CONTAINER) bench --site $(SITE) set-config allow_tests true
	@echo ">>> Done. Site ready at http://localhost:8080"

## Run bench migrate on the site (use after pulling new app code)
migrate:
	docker exec $(CONTAINER) bench --site $(SITE) migrate

## Run the full integration test suite with coverage (T067)
test:
	docker compose $(COMPOSE_FILES) exec backend \
		bench --site $(SITE) run-tests --app prevance_health --coverage

## Wipe volumes and rebuild from scratch (destructive — loses all data).
##
## pwd.yml's create-site service auto-creates the site and installs frappe+erpnext.
## After start we wait for create-site to finish, then add prevance_health.
reset-site:
	docker compose $(COMPOSE_FILES) down -v
	$(MAKE) start
	@echo ">>> Waiting for create-site to complete (frappe + erpnext install) ..."
	docker wait frappe_docker-create-site-1
	$(MAKE) new-site

help:
	@grep -E '^##' Makefile | sed 's/## //'
