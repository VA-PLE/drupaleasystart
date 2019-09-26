include .env

default: help

## help		:	Print commands help.
.PHONY: help
ifneq (,$(wildcard docker.mk))
help : docker.mk
	@sed -n 's/^##//p' $<
else
help : Makefile
	@sed -n 's/^##//p' $<
endif

## info		:	About the project.
.PHONY: info
info: url
	@grep -v '^ *#\|^ *$$' .env

## url		:	Site URL.
.PHONY: url
url:
	@echo "\nSite URL is $(PROJECT_BASE_URL):$(PORT)\n"

.PHONY: up
up:
	@echo "Starting up containers for $(PROJECT_NAME)..."
	docker-compose pull
	docker-compose up -d --remove-orphans

.PHONY: hook
hook:
	touch .git/hooks/pre-commit
	@echo "#!/bin/bash" >> .git/hooks/pre-commit
	@echo "make phpcs" >> .git/hooks/pre-commit
	chmod +x .git/hooks/pre-commit

## upnewsite	:	Deployment drupal 8.
##		Start up containers > Сomposer install > Compile settings.php
.PHONY: upnewsite
upnewsite: up coin addsettings url

## up8		:	Deploying local site. For drupal 8.
##		Start up containers > Сomposer install > Compile settings.php > Mounting database
.PHONY: up8
up8: up coin addsettings restoredb url

## up7		:	Deploying local site. For drupal 7.
##		Start up containers > Compile settings.php > Mounting database
.PHONY: up7
up7: up addsettings restoredb url

## start		:	Start containers without updating.
.PHONY: start
start:
	@echo "Starting containers for $(PROJECT_NAME) from where you left off..."
	@docker-compose start

## stop		:	Stop containers.
.PHONY: stop
stop:
	@echo "Stopping containers for $(PROJECT_NAME)..."
	@docker-compose stop

## prune		:	Remove containers and their volumes.
.PHONY: prune
prune:
	@echo "Removing containers for $(PROJECT_NAME)..."
	@docker-compose down -v $(filter-out $@,$(MAKECMDGOALS))

## composer	:	Executes `composer` command in a specified `COMPOSER_ROOT` directory.
##		For example: make composer "update drupal/core --with-dependencies"
.PHONY: composer
composer:
	docker exec $(shell docker ps --filter name='^/$(PROJECT_NAME)_php' --format "{{ .ID }}") composer --working-dir=$(COMPOSER_ROOT) $(filter-out $@,$(MAKECMDGOALS))

## drush		:	Executes `drush` command in a specified root site directory.
##		For example: make drush "watchdog:show --type=cron"
.PHONY: drush
drush:
	@docker exec -i $(shell docker ps --filter name='^/$(PROJECT_NAME)_php' --format "{{ .ID }}") drush -r $(COMPOSER_ROOT)/$(SITE_ROOT) $(filter-out $@,$(MAKECMDGOALS))

## phpcs		:	Check codebase with phpcs sniffers to make sure it conforms https://www.drupal.org/docs/develop/standards.
.PHONY: phpcs
phpcs:
	docker run --rm -v $(shell pwd)/$(SITE_ROOT)profiles:/work/profile -v $(shell pwd)/$(SITE_ROOT)modules/custom:/work/modules -v $(shell pwd)/$(SITE_ROOT)themes/custom:/work/themes skilldlabs/docker-phpcs-drupal:new phpcs --standard=Drupal,DrupalPractice --extensions=php,module,inc,install,test,profile,theme --ignore="*.features.*,*.pages*.inc" --colors .

## phpcbf		:	Fix codebase according to Drupal standards https://www.drupal.org/docs/develop/standards.
.PHONY: phpcbf
phpcbf:
	docker run --rm -v $(shell pwd)/$(SITE_ROOT)profiles:/work/profile -v $(shell pwd)/$(SITE_ROOT)modules/custom:/work/modules -v $(shell pwd)/$(SITE_ROOT)themes/custom:/work/themes skilldlabs/docker-phpcs-drupal:new phpcbf --standard=Drupal,DrupalPractice --extensions=php,module,inc,install,test,profile,theme --ignore="*.features.*,*.pages*.inc" --colors .

## restoredb	:	Mounts last modified sql database file from root dir.
.PHONY: restoredb
restoredb:pw
	@echo "\nDeploy `ls *.sql -t | head -n1` db"
	@docker exec -i $(shell docker ps --filter name='^/$(PROJECT_NAME)_php' --format "{{ .ID }}") drush -r $(COMPOSER_ROOT)/$(SITE_ROOT) sql-cli < `ls *.sql -t | head -n1`

## addsettings	:	Compile settings.php.
.PHONY: addsettings
addsettings:
	@echo "\nCompile settings.php."
	@cp -f $(SETTINGS_ROOT)/default.settings.php $(SETTINGS_ROOT)/settings.php
	@echo '$$settings["hash_salt"] = "randomnadich";' >> $(SETTINGS_ROOT)/settings.php
	@echo '$$config_directories["sync"] = "config/sync";' >> $(SETTINGS_ROOT)/settings.php
	@echo '$$config["system.file"]["path"]["temporary"] = "tmp";' >> $(SETTINGS_ROOT)/settings.php
	@echo '$$databases["default"]["default"] = array (' >> $(SETTINGS_ROOT)/settings.php
	@echo "  'database' => '$(DB_NAME)'," >> $(SETTINGS_ROOT)/settings.php
	@echo "  'username' => '$(DB_USER)'," >> $(SETTINGS_ROOT)/settings.php
	@echo "  'password' => '$(DB_PASSWORD)'," >> $(SETTINGS_ROOT)/settings.php
	@echo "  'prefix' => ''," >> $(SETTINGS_ROOT)/settings.php
	@echo "  'host' => '$(DB_HOST)'," >> $(SETTINGS_ROOT)/settings.php
	@echo "  'port' => '3306'," >> $(SETTINGS_ROOT)/settings.php
	@echo "  'namespace' => 'Drupal\\\\\\\Core\\\\\\\Database\\\\\\\Driver\\\\\\\mysql'," >> $(SETTINGS_ROOT)/settings.php
	@echo "  'driver' => '$(DB_DRIVER)'," >> $(SETTINGS_ROOT)/settings.php
	@echo ");" >> $(SETTINGS_ROOT)/settings.php
	@sleep 10

## coin		:	Сomposer install.
.PHONY: coin
coin:
	@echo "\nСomposer install"
	@docker exec $(shell docker ps --filter name='^/$(PROJECT_NAME)_php' --format "{{ .ID }}") composer --working-dir=$(COMPOSER_ROOT) install

## ps		:	List running containers.
.PHONY: ps
ps:
	@docker ps --filter name='$(PROJECT_NAME)*'

## shell		:	Access `php` container via shell.
.PHONY: shell
shell:
	docker exec -ti -e COLUMNS=$(shell tput cols) -e LINES=$(shell tput lines) $(shell docker ps --filter name='$(PROJECT_NAME)_php' --format "{{ .ID }}") sh

## logs		:	View containers logs.
.PHONY: logs
logs:
	@docker-compose logs -f $(filter-out $@,$(MAKECMDGOALS))

# https://stackoverflow.com/a/6273809/1826109
%:
	@:
