# Tests

The idea of the tests is to have expected output in `expected` folder, run SQL scripts from `sql` folder and compare results with expected output. 

## Running tests

Before running tests you need to run db as a daemon:

```bash
> docker-compose up test
```

Then run the tests with:

```bash
> docker-compose exec test make test
```

To update reference output, run 

```bash
> docker-compose exec test make update
```
