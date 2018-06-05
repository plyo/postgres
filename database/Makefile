test/expected/users.out.sql: test/sql/users.sql
	psql --username postgres --dbname ${DB_NAME} \
		-f $< \
		--echo-errors --echo-queries --echo-all \
		>$@ 2>&1

test/actual/users.out.sql: test/sql/users.sql
	mkdir -p test/actual
	psql --username postgres --dbname ${DB_NAME} \
		-f $< \
		--echo-errors --echo-queries --echo-all \
		>$@ 2>&1

.PHONY: update clean test clean_tests

reference: clean test/expected/users.out.sql

test: clean_tests test/actual/users.out.sql
	if ! colordiff test/expected/users.out.sql test/actual/users.out.sql;\
		then echo ERROR: "Fix your tests or update references with make update";\
	exit 1; fi

clean:
	rm -f test/expected/*.out.sql

clean_tests:
	rm -rf test/actual
