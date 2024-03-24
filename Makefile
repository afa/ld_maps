all: lint test
lint: rubocop
test: rspec

build: Gemfile.lock
	bundle install
Gemfile.lock: Gemfile
	bundle install
rubocop: Gemfile.lock
	rubocop
	reek
rspec: Gemfile.lock
	rspec -r./boot
run:
	thor gen25
badfiles:
	find data/temp -size 0 |wc -l
files:
	find data/temp -type f |wc -l
migrate:
	sequel -m db/migrate postgres:///load_map
