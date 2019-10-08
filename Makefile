include .env

# Get user/group id to manage permissions between host and containers.
LOCAL_UID := $(shell id -u)
LOCAL_GID := $(shell id -g)

# Evaluate recursively.
CUID ?= $(LOCAL_UID)
CGID ?= $(LOCAL_GID)

## help		:	Print commands help.
.PHONY: help
help : Makefile
	@sed -n 's/^##//p' $<

## info		:	About the project and site URL.
.PHONY: info
info: url
	@grep -v '^ *#\|^ *$$' .env | head -n17

##
## up		:	Re-create containers or starting up only containers.
.PHONY: up
up:
	@echo "Starting up containers for $(PROJECT_NAME)..."
	docker-compose pull
	docker-compose up -d --remove-orphans

## upnewsite	:	Deployment local vanilla drupal 8.
.PHONY: upnewsite
upnewsite: gitclone up coin addsettings druinsi url

## upsite		:	Automatic deploy local site.
#default up coin addsettings (druinsi drusim)_or_(restoredb) hook url
.PHONY: upsite
upsite: up coin addsettings druinsi drusim hook url

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

##
## shell		:	Access `php` container via shell.
.PHONY: shell
shell:
	docker exec -ti --user $(CUID):$(CGID) -e  COLUMNS=$(shell tput cols) -e LINES=$(shell tput lines) $(shell docker ps --filter name='$(PROJECT_NAME)_php' --format "{{ .ID }}") sh

## composer	:	Executes `composer` command in a specified `COMPOSER_ROOT` directory. Example: make composer "update drupal/core --with-dependencies"
.PHONY: composer
composer:
	docker exec --user $(CUID):$(CGID) $(shell docker ps --filter name='^/$(PROJECT_NAME)_php' --format "{{ .ID }}") composer --working-dir=$(COMPOSER_ROOT) $(filter-out $@,$(MAKECMDGOALS))

## drush		:	Executes `drush` command in a specified root site directory. Example: make drush "watchdog:show --type=cron"
.PHONY: drush
drush:
	@docker exec -i --user $(CUID):$(CGID) $(shell docker ps --filter name='^/$(PROJECT_NAME)_php' --format "{{ .ID }}") drush -r $(COMPOSER_ROOT)/$(SITE_ROOT) $(filter-out $@,$(MAKECMDGOALS))

## phpcs		:	Check codebase with phpcs sniffers to make sure it conforms https://www.drupal.org/docs/develop/standards.
.PHONY: phpcs
phpcs:
	docker run --rm -v $(shell pwd)/$(SITE_ROOT)profiles:/work/profile -v $(shell pwd)/$(SITE_ROOT)modules/custom:/work/modules -v $(shell pwd)/$(SITE_ROOT)themes/custom:/work/themes $(CODETESTER) phpcs --standard=Drupal,DrupalPractice --extensions=php,module,inc,install,test,profile,theme --ignore="*.features.*,*.pages*.inc" --colors .

## phpcbf		:	Fix codebase according to Drupal standards https://www.drupal.org/docs/develop/standards.
.PHONY: phpcbf
phpcbf:
	docker run --rm -v $(shell pwd)/$(SITE_ROOT)profiles:/work/profile -v $(shell pwd)/$(SITE_ROOT)modules/custom:/work/modules -v $(shell pwd)/$(SITE_ROOT)themes/custom:/work/themes $(CODETESTER) phpcbf --standard=Drupal,DrupalPractice --extensions=php,module,inc,install,test,profile,theme --ignore="*.features.*,*.pages*.inc" --colors .

## node		:       Up node container and run "yarn install && yarn run start".
.PHONY: node
node:
	docker run --rm --entrypoint bash -it -v $(shell pwd)/:/var/www/html -w /var/www/html/frontend wodby/node:$(NODE_TAG) -c "yarn install && yarn build && rm -rf /var/www/html/frontend/node_modules && rm -rf frontend/node_modules"

##
## ps		:	List running containers.
.PHONY: ps
ps:
	@docker ps --filter name='$(PROJECT_NAME)*'

## logs		:	View containers logs.
.PHONY: logs
logs:
	@docker-compose logs -f $(filter-out $@,$(MAKECMDGOALS))

## prune		:	Remove containers and their volumes.
.PHONY: prune
prune:
	@echo "Removing containers for $(PROJECT_NAME)..."
	@docker-compose down -v $(filter-out $@,$(MAKECMDGOALS))

#url		:	Site URL.
.PHONY: url
url:
	@echo "\nSite URL is $(PROJECT_BASE_URL):$(PORT)\n"

#hook		:	Add pre-commit hook.
.PHONY: hook
hook:
	@touch .git/hooks/pre-commit
	@echo "#!/bin/bash\nmake phpcs" >> .git/hooks/pre-commit
	@chmod +x .git/hooks/pre-commit

#gitclone	:	Gitclone vanilla drupal 8 project.
.PHONY: gitclone
gitclone:
	@git clone -b 8.x https://github.com/drupal-composer/drupal-project.git
	@cp -a -f drupal-project/drush drupal-project/scripts drupal-project/composer.json drupal-project/load.environment.php .
	@rm -rf drupal-project

#restoredb	:	Mounts last modified sql database file from root dir.
.PHONY: restoredb
restoredb:pw
	@echo "\nDeploy `ls *.sql -t | head -n1` database"
	@docker exec -i --user $(CUID):$(CGID) $(shell docker ps --filter name='^/$(PROJECT_NAME)_php' --format "{{ .ID }}") drush -r $(COMPOSER_ROOT)/$(SITE_ROOT) sql-cli < `ls *.sql -t | head -n1`

#addsettings	:	Compile settings.php.
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
	@sleep 5

#coin		:	Сomposer install.
.PHONY: coin
coin:
	@echo "\nСomposer install"
	@docker exec --user $(CUID):$(CGID) $(shell docker ps --filter name='^/$(PROJECT_NAME)_php' --format "{{ .ID }}") composer --working-dir=$(COMPOSER_ROOT) install

#drusim		:	Import configs.
.PHONY: drusim
drusim:
	@docker exec -i --user $(CUID):$(CGID) $(shell docker ps --filter name='^/$(PROJECT_NAME)_php' --format "{{ .ID }}") drush -r $(COMPOSER_ROOT)/$(SITE_ROOT) ev '\Drupal::entityManager()->getStorage("shortcut_set")->load("default")->delete();'
	@docker exec -i --user $(CUID):$(CGID) $(shell docker ps --filter name='^/$(PROJECT_NAME)_php' --format "{{ .ID }}") drush -r $(COMPOSER_ROOT)/$(SITE_ROOT) cim -y

#druinsi		:	Drush install site.
.PHONY: druinsi
druinsi:
	@docker exec -i --user $(CUID):$(CGID) $(shell docker ps --filter name='^/$(PROJECT_NAME)_php' --format "{{ .ID }}") drush -r $(COMPOSER_ROOT)/$(SITE_ROOT) si -y standard --account-name=$(DRUPALADMIN) --account-pass=$(DRUPALLPASS)
	@docker exec -i --user $(CUID):$(CGID) $(shell docker ps --filter name='^/$(PROJECT_NAME)_php' --format "{{ .ID }}") drush -r $(COMPOSER_ROOT)/$(SITE_ROOT) cset system.site uuid c7635c29-335d-4655-b2b6-38cb111042d9
%:
	@:
