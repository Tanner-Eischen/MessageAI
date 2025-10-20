.PHONY: db/start db/migrate db/test funcs/dev contracts/validate contracts/gen

db/start:
	supabase start

db/migrate:
	supabase db reset --use-migra

db/test:
	pg_prove supabase/db/test/*.sql

funcs/dev:
	supabase functions serve --env-file supabase/.env

contracts/validate:
	npm --prefix ../contracts ci && npm --prefix ../contracts run validate

contracts/gen:
	npm --prefix ../contracts run gen:dart
