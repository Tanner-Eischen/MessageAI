.PHONY: db/start db/migrate db/test funcs/dev contracts/validate contracts/gen

db/start:
	npx supabase start

db/migrate:
	npx supabase db reset

db/test:
	pg_prove supabase/db/test/*.sql

funcs/dev:
	npx supabase functions serve --env-file backend/.env

contracts/validate:
	npm --prefix ../contracts ci && npm --prefix ../contracts run validate

contracts/gen:
	npm --prefix ../contracts run gen:dart
