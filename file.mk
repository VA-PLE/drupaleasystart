include .env

USER=user
SERVER=ip
DIR=sitedir
SSHPARAM=
RSYNCPARAM=

##
## db		:	Download database.
.PHONY: db
db:
	@echo "\nCreate a database dump"
	@ssh $(USER)@$(SERVER) $(SSHPARAM) "cd /home/$(USER)/www/$(DIR) && drush sql-dump" > `date +%d-%m-%Y`.sql
	@echo "Dump created successfully: `date +%d-%m-%Y`.sql"

## file		:	Download files.
.PHONY: file
file:
	@echo "\nDownload files"
	@rsync -avvP $(RSYNCPARAM) $(USER)@$(SERVER):/home/$(USER)/www/$(DIR)/$(SETTINGS_ROOT)/files $(SETTINGS_ROOT)

%:
	@:
