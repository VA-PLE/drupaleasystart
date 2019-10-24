include .env

THEMES_ROOT=frontend
FRONT_ROOT_DIR=frontend/dist

##
## infofront	:	About the frontproject and site URL.
.PHONY: infofront
infofront: urlfront
	@echo "Frontend container wodby/node:$(NODE_TAG)"

## front		:	Up frontend container and run your command. Example: make front yarn build, or: make front "npm install && npm run build"
.PHONY: front
front:
	docker run --rm --entrypoint bash -i -v $(shell pwd)/:/var/www/html -w /var/www/html/$(THEMES_ROOT) wodby/node:$(NODE_TAG) -c "$(filter-out $@,$(MAKECMDGOALS)) && rm -rf /var/www/html/$(THEMES_ROOT)/node_modules"

## upsitefront	:	Up frontend site
.PHONY: upsitefront
upsitefront: up builddc upfront urlfront

# urlfront	:	Up frontend site
.PHONY: urlfront
urlfront:
	@echo "\nFrontsite URL is front$(PROJECT_BASE_URL):$(PORT)\n"

# builddc	:	build front.docker-compose.yml
.PHONY: builddc
builddc:
	@rm -rf front.docker-compose.yml
	@touch front.docker-compose.yml
	@echo 'version: "3"' >> front.docker-compose.yml
	@echo '\nservices:' >> front.docker-compose.yml
	@echo '  nginx_front:' >> front.docker-compose.yml
	@echo '    image: wodby/nginx:${NGINX_TAG}' >> front.docker-compose.yml
	@echo '    container_name: "${PROJECT_NAME}_nginx_front"' >> front.docker-compose.yml
	@echo '    environment:' >> front.docker-compose.yml
	@echo '      NGINX_STATIC_OPEN_FILE_CACHE: "off"' >> front.docker-compose.yml
	@echo '      NGINX_ERROR_LOG_LEVEL: debug' >> front.docker-compose.yml
	@echo '      NGINX_BACKEND_HOST: php' >> front.docker-compose.yml
	@echo '      NGINX_SERVER_ROOT: ${COMPOSER_ROOT}/${FRONT_ROOT_DIR}' >> front.docker-compose.yml
	@echo '      NGINX_FASTCGI_INDEX: index.html' >> front.docker-compose.yml
	@echo '    volumes:' >> front.docker-compose.yml
	@echo '      - ./:/var/www/html' >> front.docker-compose.yml
	@echo '    labels:' >> front.docker-compose.yml
	@echo '      - "traefik.enable=true"' >> front.docker-compose.yml
	@echo '      - "traefik.http.routers.${PROJECT_NAME}_nginx_front.rule=Host(`front${PROJECT_BASE_URL}`)"' >> front.docker-compose.yml

# upfront	:	Up frontend container
.PHONY: upfront
upfront:
	@docker-compose -f front.docker-compose.yml up -d

%:
	@:
