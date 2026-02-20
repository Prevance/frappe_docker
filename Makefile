# Prevance Health — frappe_docker development helpers
#
# ─── FIRST TIME ON A NEW MACHINE ────────────────────────────────────────────
#   cp example.env .env                  # REQUIRED — see example.env header
#   make reset-site                      # wipe volumes, start stack, install
#
# ─── AFTER A PLAIN `docker compose down` (volumes kept) ─────────────────────
#   make start        # bring services back up — site data is intact
#
# ─── AFTER PULLING NEW APP CODE ─────────────────────────────────────────────
#   make migrate      # run bench migrate to pick up schema changes
#
# ─── POST-CONTAINER-RECREATION (packages lost on backend image rebuild) ──────
#   make new-site     # re-installs: prevance_health, argon2-cffi, pytest, coverage
#
# ─── INTEGRATION TESTS ──────────────────────────────────────────────────────
#   make test
#
# ─── CANONICAL DEV START COMMAND (for reference) ────────────────────────────
#   ERPNEXT_VERSION=v16.5.0 docker compose -f pwd.yml -f docker-compose.override.yml up -d
#   (make start runs this automatically via COMPOSE_FILES)

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
	@echo ">>> Registering prevance_health in global apps registry ..."
	docker exec $(CONTAINER) bash -c \
		"grep -q prevance_health /home/frappe/frappe-bench/sites/apps.txt \
		 || echo prevance_health >> /home/frappe/frappe-bench/sites/apps.txt"
	@echo ">>> pip-installing prevance_health, argon2-cffi, pytest, and coverage into backend ..."
	docker exec $(CONTAINER) /home/frappe/frappe-bench/env/bin/pip install -q -e /home/frappe/frappe-bench/apps/prevance_health argon2-cffi pytest coverage
	@echo ">>> Installing prevance_health on site '$(SITE)' (skip if already installed) ..."
	docker exec $(CONTAINER) bash -c \
		"grep -q prevance_health /home/frappe/frappe-bench/sites/$(SITE)/apps.txt 2>/dev/null \
		 || bench --site $(SITE) install-app prevance_health \
		 || (echo 'ERROR: bench install-app prevance_health failed'; exit 1)"
	@echo ">>> Verifying prevance_health is listed in installed apps ..."
	docker exec $(CONTAINER) grep -q prevance_health /home/frappe/frappe-bench/sites/$(SITE)/apps.txt \
		|| (echo "ERROR: prevance_health not listed after install — aborting"; exit 1)
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
