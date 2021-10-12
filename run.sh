#!/usr/bin/env bash

set -eo pipefail

DC="${DC:-exec}"

# If we're running in CI we need to disable TTY allocation for docker-compose
# commands that enable it by default, such as exec and run.
TTY=""
if [[ ! -t 1 ]]; then
    TTY="-T"
fi

# -----------------------------------------------------------------------------
# Helper functions start with _ and aren't listed in this script's help menu.
# -----------------------------------------------------------------------------

function _dc {
    export DOCKER_BUILDKIT=1
    docker-compose ${TTY} "${@}"
}

function _dc_quiet {
    docker-compose --log-level ERROR ${TTY} "${@}"
}

function _build_run_down {
    docker-compose build
    docker-compose run ${TTY} "${@}"
    docker-compose down
}

function _use_env {
    sort -u environment/.env | grep -v '^$\|^\s*\#' > './environment/.env.tempfile'
    export $(cat environment/.env.tempfile | xargs)
}

# -----------------------------------------------------------------------------
# * General purpose local functions.


# -----------------------------------------------------------------------------
# * docker-compose functions.

function up {  # Run the stack without extra.
    _dc down --remove-orphans && _dc build --parallel && _dc up -d "${@}"
}

function up:e {  # Run the stack.
    _dc --profile extra down --remove-orphans && _dc --profile extra build --parallel && _dc --profile extra up -d "${@}"
}

function down {  # Stop stack.
    _dc down "${@}"
}

function back {  # Run any command you want in the running backend container.
    _dc exec backend "${@}"
}

function back:bash {  # Start a bash session in the backend container.
    back bash "${@}"
}

# -----------------------------------------------------------------------------
# * Database (postgres mostly).

function psql {  # Connect to running database container and enter psql command.
    _dc exec db psql -U postgres -d app
}

function sql {
    cat "$1" | _dc exec -T db psql -U postgres -d app # | tee psql_output.tempfile
}

function sql:line {
    sed "$2q;d" "$1" | _dc exec -T db psql -U postgres -d app # | tee psql_output.tempfile
}

function sql:csv {
    cat "./sql/$1.sql" | _dc exec -T db psql -U postgres -d app --csv | tee ./data/output/psql_output.csv
}

function db:dump {  # Make database dump.
    _dc_quiet exec db pg_dump -U postgres app > dump.sql
}

function db:dump:r {  # Restore database from dump.
    echo "Restoring database backup..."
    _dc_quiet exec db bash -c "dropdb -U postgres app && createdb -U postgres -T template0 app"
    _dc_quiet exec -T db psql -U postgres --quiet --set ON_ERROR_STOP=on app < dump.sql
    echo "Database restored successfully."
}

# -----------------------------------------------------------------------------
# * Non-local functions



# -----------------------------------------------------------------------------
# * Housekeeping

function clean:tempfiles {
    rm -f tempfile && find . -name "*.tempfile" -type f | xargs rm -f
}

# -----------------------------------------------------------------------------

function help {
    printf "%s <task> [args]\n\nTasks:\n" "${0}"

    compgen -A function | grep -v "^_" | cat -n
}

TIMEFORMAT=$'\nTask completed in %3lR'
time "${@:-help}"
