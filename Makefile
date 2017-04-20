COMPOSE_PROJECT_NAME=$(shell python docker_dev/extract-env.py COMPOSE_PROJECT_NAME)
DATABASE_TYPE=$(shell python docker_dev/extract-env.py DATABASE_TYPE)
DJANGO_PROJECT_DIR=$(shell python docker_dev/extract-env.py DJANGO_PROJECT_DIR)
WEBSITE_PORT=$(shell python docker_dev/extract-env.py WEBSITE_PORT)


# Display help; this is the default rule
.PHONY: help
help:
	@cat docker_dev/Makefile-help


# Start the services
.PHONY: start _start
start: _start
	@echo
	@echo "Point your web browser to http://127.0.0.1:$(WEBSITE_PORT)"
	@echo "Note that it may take a short time for docker to finish connecting the ports"
_start: prerequisites
	docker-compose up -d


# Stop the services
.PHONY: stop
stop:
	docker-compose stop


# Force rebuild of images if necessary (normally it's not)
.PHONY: build _build
build: _build prerequisites
_build: build_prerequisites
	docker-compose build


# Open a shell to the web service
.PHONY: shell
shell: _start
	docker-compose exec web /bin/bash


# Open a sql shell to the db service
.PHONY: sql
sql: _start _sql_$(DATABASE_TYPE)
_sql_postgres:
	docker-compose exec db psql --dbname=devdb --username=postgres
_sql_mysql:
	docker-compose exec db mysql --user=root --password=dev-password devdb
_sql_sqlite:
	docker-compose exec web python $(DJANGO_PROJECT_DIR)/manage.py dbshell


# Run the web service in such a way as to allow pdb debugging
.PHONY: debug
debug:
	docker-compose stop web
	docker-compose run --rm --service-ports --name $(COMPOSE_PROJECT_NAME)_web_debug web


# Display and follow the logs
.PHONY: logs
logs:
	docker-compose logs db
	docker-compose logs -f web


# Run django unit tests
.PHONY: tests
tests: _start
	docker-compose exec web python $(DJANGO_PROJECT_DIR)/manage.py test


# Clean all project-specific docker artifacts, print details about how to clean everything else
.PHONY: clean
clean: stop
	docker-compose down --rmi 'local'
	docker rmi $(COMPOSE_PROJECT_NAME)_web
	@echo
	@echo "*************************************************"
	@echo "Note that this doesn't delete docker base images"
	@echo "that might be used by other docker projects."
	@echo "To list the installed images, use 'docker images';"
	@echo "To delete unused ones, use 'docker rmi image-name-or-id'."
	@echo "This also doesn't delete any source files."
	@echo "Nor does it delete the actual database files,"
	@echo "which are in the ../data directory."


# Make sure prerequisites are met
.PHONY: build_prerequisites
build_prerequisites: $(DJANGO_PROJECT_DIR) $(DJANGO_PROJECT_DIR)/requirements.txt
$(DJANGO_PROJECT_DIR):
	mkdir $(DJANGO_PROJECT_DIR)
$(DJANGO_PROJECT_DIR)/requirements.txt:
	touch $(DJANGO_PROJECT_DIR)/requirements.txt

# Make sure prerequisites are met
.PHONY: prerequisites prerequisites-django
prerequisites: $(DJANGO_PROJECT_DIR)/manage.py
$(DJANGO_PROJECT_DIR)/manage.py:  # Start a django project if there isn't one already
	docker-compose run --rm --name $(COMPOSE_PROJECT_NAME)_web_django web django-admin startproject $(DJANGO_PROJECT_DIR) $(DJANGO_PROJECT_DIR)
