.PHONY: db/start db/stop db/migrate db/reset db/test funcs/dev funcs/deploy contracts/validate contracts/gen

db/start:
	npm run db:start

db/stop:
	npm run db:stop

db/migrate:
	npm run db:migrate

db/reset:
	npm run db:reset

db/test:
	npm run db:test

funcs/dev:
	npm run funcs:serve

funcs/deploy:
	npm run funcs:deploy

contracts/validate:
	npm --prefix ../contracts ci && npm --prefix ../contracts run validate

contracts/gen:
	npm --prefix ../contracts run gen:dart
