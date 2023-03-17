include .env

GREEN=\033[1;32m
NORMAL=\033[0m

#help		:	Print commands help.
.PHONY: help
help:
	@sed -n 's/^##//p' Makefile

## info		:	About the project and site URL.
.PHONY: info
info: url
	@grep -v '^ *#\|^ *$$' .env | head -n16

##
## up		:	Re-create containers or starting up only containers.
.PHONY: up
up:
	@echo "${GREEN}\nStarting up containers for $(PROJECT_NAME)...${NORMAL}"
	@docker-compose pull
	@docker-compose up -d --remove-orphans

## upnewsite_D10	:	Deployment local new Drupal 10 site.
.PHONY: upnewsite_D10
upnewsite_D10: gitclone10 up coin addsettings updrush druinsi url

## upnewsite_D9	:	Deployment local new Drupal 9 site.
.PHONY: upnewsite_D9
upnewsite_D9: gitclone9 up coin addsettings updrush url

## upsite		:	Automatic deploy local site.
#default for Drupal sites: up coin addsettings (restoredb) url.
.PHONY: upsite
upsite: up coin addsettings url

## start		:	Start containers without updating.
.PHONY: start
start:
	@echo "${GREEN}\nStarting containers for $(PROJECT_NAME) from where you left off...${NORMAL}"
	@docker-compose start

## stop		:	Stop containers.
.PHONY: stop
stop:
	@echo "${GREEN}\nStopping containers for $(PROJECT_NAME)...${NORMAL}"
	@docker-compose stop

##
## shell		:	Access `php` container via shell.
.PHONY: shell
shell:
	@docker exec -ti -e COLUMNS=$(shell tput cols) -e LINES=$(shell tput lines) $(shell docker ps --filter name='$(PROJECT_NAME)_php' --format "{{ .ID }}") sh

## composer	:	Executes `composer` command in a specified `COMPOSER_ROOT` directory. Example: make composer "update drupal/core --with-dependencies".
.PHONY: composer
composer:
	@docker exec $(shell docker ps --filter name='^/$(PROJECT_NAME)_php' --format "{{ .ID }}") composer --working-dir=$(COMPOSER_ROOT) $(filter-out $@,$(MAKECMDGOALS))

## drush		:	Executes `drush` command in a specified root site directory. Example: make drush "watchdog:show --type=cron".
.PHONY: drush
drush:
	@docker exec -i $(shell docker ps --filter name='^/$(PROJECT_NAME)_php' --format "{{ .ID }}") drush -r $(COMPOSER_ROOT)/$(SITE_ROOT) $(filter-out $@,$(MAKECMDGOALS))

## phpcs		:	Check codebase with phpcs sniffers to make sure it conforms https://www.drupal.org/docs/develop/standards.
.PHONY: phpcs
phpcs:
	@docker run --rm -v $(shell pwd)/$(SITE_ROOT)profiles:/work/profiles -v $(shell pwd)/$(SITE_ROOT)modules:/work/modules -v $(shell pwd)/$(SITE_ROOT)themes:/work/themes $(CODETESTER) phpcs --standard=Drupal,DrupalPractice --extensions=php,module,inc,install,test,profile,theme --ignore="*/contrib/*,*.features.*,*.pages*.inc" --colors .

## phpcbf		:	Fix codebase according to Drupal standards https://www.drupal.org/docs/develop/standards.
.PHONY: phpcbf
phpcbf:
	@docker run --rm -v $(shell pwd)/$(SITE_ROOT)profiles:/work/profiles -v $(shell pwd)/$(SITE_ROOT)modules:/work/modules -v $(shell pwd)/$(SITE_ROOT)themes:/work/themes $(CODETESTER) phpcbf --standard=Drupal,DrupalPractice --extensions=php,module,inc,install,test,profile,theme --ignore="*/contrib/*,*.features.*,*.pages*.inc" --colors .

## restoredb	:	Mounts last modified sql database file from root dir.
.PHONY: restoredb
restoredb:
	@echo "${GREEN}\nDeploy `ls *.sql -t | head -n1` database...${NORMAL}"
	@docker exec -i $(shell docker ps --filter name='^/$(PROJECT_NAME)_php' --format "{{ .ID }}") drush -r $(COMPOSER_ROOT)/$(SITE_ROOT) sql-cli < `ls *.sql -t | head -n1`

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
	@echo "${GREEN}\nRemoving containers for $(PROJECT_NAME)...${NORMAL}"
	@docker-compose down -v $(filter-out $@,$(MAKECMDGOALS))

#url		: Show site URL.
.PHONY: url
url:
	@echo "${GREEN}\nSite URL is $(PROJECT_BASE_URL):$(PORT)\n${NORMAL}"

#gitclone10	:	Gitclone Composer template for Drupal 10 project.
.PHONY: gitclone10
gitclone10:
	@echo "${GREEN}\nCloned Composer template for Drupal 10 project...${NORMAL}"
	@git clone -b 10.x https://github.com/wodby/drupal-vanilla.git
	@cp -af drupal-vanilla/composer.json drupal-vanilla/composer.lock .
	@wget https://raw.githubusercontent.com/drupal-composer/drupal-project/10.x/.gitignore -O drupal-vanilla/.gitignore
	@sed 'N;$$!P;$$!D;$$d' drupal-vanilla/.gitignore > .gitignore
	@echo "# Ignore other files\n*.tar\n*.tar.gz\n*.sql\n*.sql.gz" >> .gitignore
	@rm -rf drupal-vanilla

#gitclone9	:	Gitclone Composer template for Drupal 9 project.
.PHONY: gitclone9
gitclone9:
	@echo "${GREEN}\nCloned Composer template for Drupal 9 project...${NORMAL}"
	@git clone -b 9.x https://github.com/wodby/drupal-vanilla.git
	@cp -af drupal-vanilla/composer.json drupal-vanilla/composer.lock .
	@wget https://raw.githubusercontent.com/drupal-composer/drupal-project/9.x/.gitignore -O drupal-vanilla/.gitignore
	@sed 'N;$$!P;$$!D;$$d' drupal-vanilla/.gitignore > .gitignore
	@echo "# Ignore other files\n*.tar\n*.tar.gz\n*.sql\n*.sql.gz" >> .gitignore
	@rm -rf drupal-vanilla

#addsettings	:	Сreate settings.php.
.PHONY: addsettings
addsettings:
	@echo "${GREEN}\nСreate settings.php...${NORMAL}"
	@cp -f $(SITE_ROOT)sites/default/default.settings.php $(SETTINGS_PHP)
	@echo '$$settings["hash_salt"] = "randomnadich";' >> $(SETTINGS_PHP)
	@echo '$$settings["config_sync_directory"] = "$(CONFIG_SYNC_DIRECTORY)";' >> $(SETTINGS_PHP)
	@echo '$$databases["default"]["default"] = array (' >> $(SETTINGS_PHP)
	@echo "  'database' => '$(DB_NAME)'," >> $(SETTINGS_PHP)
	@echo "  'username' => '$(DB_USER)'," >> $(SETTINGS_PHP)
	@echo "  'password' => '$(DB_PASSWORD)'," >> $(SETTINGS_PHP)
	@echo "  'prefix' => ''," >> $(SETTINGS_PHP)
	@echo "  'host' => '$(DB_HOST)'," >> $(SETTINGS_PHP)
	@echo "  'port' => '3306'," >> $(SETTINGS_PHP)
	@echo "  'namespace' => 'Drupal\\\\\\\Core\\\\\\\Database\\\\\\\Driver\\\\\\\mysql'," >> $(SETTINGS_PHP)
	@echo "  'driver' => '$(DB_DRIVER)'," >> $(SETTINGS_PHP)
	@echo ");" >> $(SETTINGS_PHP)
	@mkdir -p $(CONFIG_SYNC_DIRECTORY)

#coin		:	Сomposer install.
.PHONY: coin
coin:
	@echo "${GREEN}\nСomposer install...${NORMAL}"
	@docker exec $(shell docker ps --filter name='^/$(PROJECT_NAME)_php' --format "{{ .ID }}") composer --working-dir=$(COMPOSER_ROOT) install

#updrush		:	Install/Update Drush
updrush:
	@echo "${GREEN}\nInstall Drush...${NORMAL}"
	@docker exec $(shell docker ps --filter name='^/$(PROJECT_NAME)_php' --format "{{ .ID }}") composer --working-dir=$(COMPOSER_ROOT) require drush/drush

#druinsi		:	Drush install site.
.PHONY: druinsi
druinsi:
	@echo "${GREEN}\nDrush install site...${NORMAL}"
	@docker exec -i $(shell docker ps --filter name='^/$(PROJECT_NAME)_php' --format "{{ .ID }}") drush -r $(COMPOSER_ROOT)/$(SITE_ROOT) si -y standard --account-name=$(DRUPALADMIN) --account-pass=$(DRUPALPASS)

%:
	@:
