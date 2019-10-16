include .env

THEMES_ROOT=frontend
THEMES_NAME=name

##
## frontend	:	Up frontend container and run your command. Example: make yarn build.
.PHONY: frontend
frontend:
	docker run --rm --entrypoint bash -i -v $(shell pwd)/:/var/www/html -w /var/www/html/frontend wodby/node:$(NODE_TAG) -c "yarn install && $(filter-out $@,$(MAKECMDGOALS)) && rm -rf /var/www/html/frontend/node_modules"

%:
	@:
