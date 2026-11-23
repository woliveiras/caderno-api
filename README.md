# Caderno

Caderno is a Python and PostgreSQL visit counter for the exercises in *Isolating Coding Agents*. Use it to follow one request from an HTTP client through the API to the volume that keeps the database row.

## Start the API

Use a disposable environment with Docker Engine, the Compose and Buildx plugins, `sh`, and `curl`. Run the commands from the root of this checkout. Verify that your Docker client points to the Engine assigned to the exercise and that port 8000 is free there.

```sh
docker compose config --quiet
docker compose up -d --build --wait --wait-timeout 90
docker compose ps --all
```

Compose publishes the unauthenticated API on `127.0.0.1:8000` and keeps PostgreSQL on the project network. The database role `caderno_app` uses a public fixture password for this disposable project. The `caderno-api_pgdata` volume holds the rows.

Read the count once the API responds. On a fresh volume it returns `{"visits": 0}`.

```sh
curl --disable --noproxy '*' --fail --silent --show-error --max-time 5 \
    http://127.0.0.1:8000/visits
```

If the listener is still starting, retry the read. If it does not come up, inspect `docker compose logs api db`. To use a different port, set `CADERNO_PORT` in the shell before starting Compose, then use the same port in the checks.

## Check a visit

Run the baseline once on the fresh database.

```sh
sh ./check-visits.sh 8000 baseline
```

`GET /visits` returns the current count, as does `GET /`. `POST /visits` writes a row and returns HTTP 201 with its `id`. The baseline checks that the count moves from zero to one. It also expects HTTP 404 from `GET /status`. Adding that route is a later exercise in the book.

## Keep or remove the state

Stop and restart the same project with its existing volume.

```sh
docker compose stop
docker compose up -d --no-build --wait --wait-timeout 90
```

Once the API responds, run `sh ./check-visits.sh 8000 count 1` to read the retained visit. Stop here if you want to keep that database for another exercise. To end the run and delete its rows, remove the Compose project and its disposable volume.

```sh
docker compose down --volumes
```
