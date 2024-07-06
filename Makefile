all: lint test
lint: rubocop reek
test: rspec

build: Gemfile.lock
	bundle install
Gemfile.lock: Gemfile
	bundle install
rubocop: Gemfile.lock
	bundle exec rubocop
reek: Gemfile.lock
	bundle exec reek
rspec: Gemfile.lock
	bundle exec rspec -r./boot
run:
	bundle exec thor gen25
badfiles:
	find data/temp -size 0 |wc -l
files:
	find data/temp -type f |wc -l
migrate:
	bundle exec sequel -m db/migrate postgres:///load_map
