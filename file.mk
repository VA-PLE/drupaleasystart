include .env

USER=user
SERVER=ip
DIR=sitedir

##
## db		:	Download database.
.PHONY: db
db:
	@ssh $(USER)@$(SERVER) "cd /home/$(USER)/web/$(DIR)/public_html && drush sql-dump" > `date +%m-%d-%Y`.sql

## file		:	Download file.
.PHONY: file
file:
	@rsync -avvP $(USER)@$(SERVER):/home/$(USER)/web/$(DIR)/public_html/$(SETTINGS_ROOT)/files $(SETTINGS_ROOT)

%:
	@:
