all: lint test
lint: rubocop
test: rspec

build:
	bundle install
rubocop: build
	rubocop
rspec: build
	rspec
run:
	thor gen25
badfiles:
	find data/temp -size 0 |wc -l
migrate:
	sequel -m db/migrate postgres:///load_map
