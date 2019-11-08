include .env

THEMES_ROOT=frontend
FRONT_ROOT_DIR=frontend/dist

##
## infofront	:	About the frontproject and site URL.
.PHONY: infofront
infofront: urlfront
	@echo "Frontend container wodby/node:$(NODE_TAG)"

## front		:	Up frontend container and run your command. Example: make front yarn build, or: make front "npm install && npm run build".
.PHONY: front
front:
	docker run --rm --entrypoint bash -i -v $(shell pwd)/:/var/www/html -w /var/www/html/$(THEMES_ROOT) wodby/node:$(NODE_TAG) -c "$(filter-out $@,$(MAKECMDGOALS))"

## upsitefront	:	Up frontend site.
.PHONY: upsitefront
upsitefront: builddc up urlfront

#urlfront	:	URL frontend site.
.PHONY: urlfront
urlfront:
	@echo "\nFrontsite URL is front.$(PROJECT_BASE_URL):$(PORT)\n"

#builddc	:	build docker-compose.override.yml.
.PHONY: builddc
builddc:
	@echo 'version: "3"' > docker-compose.override.yml
	@echo '\nservices:' >> docker-compose.override.yml
	@echo '  nginx_front:' >> docker-compose.override.yml
	@echo '    image: wodby/nginx:${NGINX_TAG}' >> docker-compose.override.yml
	@echo '    container_name: "${PROJECT_NAME}_nginx_front"' >> docker-compose.override.yml
	@echo '    environment:' >> docker-compose.override.yml
	@echo '      NGINX_STATIC_OPEN_FILE_CACHE: "off"' >> docker-compose.override.yml
	@echo '      NGINX_ERROR_LOG_LEVEL: debug' >> docker-compose.override.yml
	@echo '      NGINX_BACKEND_HOST: php' >> docker-compose.override.yml
	@echo '      NGINX_SERVER_ROOT: ${COMPOSER_ROOT}/${FRONT_ROOT_DIR}' >> docker-compose.override.yml
	@echo '      NGINX_FASTCGI_INDEX: index.html' >> docker-compose.override.yml
	@echo '    volumes:' >> docker-compose.override.yml
	@echo '      - ./:/var/www/html' >> docker-compose.override.yml
	@echo '    labels:' >> docker-compose.override.yml
	@echo '      - "traefik.enable=true"' >> docker-compose.override.yml
	@echo '      - "traefik.http.routers.${PROJECT_NAME}_nginx_front.rule=Host(`front.${PROJECT_BASE_URL}`)"' >> docker-compose.override.yml

%:
	@:
