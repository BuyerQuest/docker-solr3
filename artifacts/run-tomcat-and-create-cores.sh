#!/bin/bash
set -umo pipefail

# Trap the SIGTERM so we can exit cleanly
trap 'echo Stopping SOLR; catalina.sh stop; exit $?' SIGTERM

# Start Tomcat
catalina.sh start

# Show catalina log output, but suppress output of healthcheck execution
tail -f logs/catalina.out | grep -P -v --line-buffered "$STDOUT_FILTER" &

# Wait for SOLR to start by querying the admin API
for try in $(seq 1 300); do
  sleep 1
  # If we can connect to the API, break the loop
  curl -s "http://localhost:8080/solr/" > /dev/null && break
  # And quit if we can't talk to SOLR after 5 minutes
  if [[ "$try" -gt 300 ]]; then
    echo "SOLR failed to start"; exit 1
  fi
done

# Hard fail on errors
set -e

# Then try to read some information from a SOLR admin API until we succeed
curl -JL --retry 300 --retry-delay 1 "http://localhost:8080/solr/admin/cores" --silent > /dev/null
echo "SOLR is online, creating any missing cores"

# Check through the cores already present in SOLR and add any missing ones
find -H /cores -mindepth 1 -maxdepth 1 -type d | while read coredir; do
  # If the core is NOT loaded, coreSearch will be a blank string
  coreSearch=$(curl "localhost:8080/solr/admin/cores?wt=json" --silent | jq -r ".status | values[] | select ( .instanceDir == \"$coredir/\" )")
  if [[ -z "$coreSearch" ]]; then
    # Run any user-supplied core init scripts
    for f in /core-init/*; do
      # shellcheck disable=SC1090
      case "$f" in
        *.sh) echo "$0: running $f"; . "$f" "$(realpath $coredir)" ;;
        *)    echo "$0: ignoring $f" ;;
      esac
    done

    # Load the core with cURL
    corename=$(basename $coredir)
    echo "Creating core $corename"
    curl --fail "http://localhost:8080/solr/admin/cores?action=CREATE&name=$corename&instanceDir=$coredir&wt=json" --silent | jq -r .
  fi
done

# Hang around until we get the SIGTERM
tail -f /dev/null & wait
