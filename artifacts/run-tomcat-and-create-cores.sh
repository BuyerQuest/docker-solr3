#!/bin/bash
set -umo pipefail

# Start tomcat
catalina.sh run &

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
curl -JL --retry 300 --retry-delay 1 "http://localhost:8080/solr/admin/cores" --silent
echo "SOLR is online, creating any missing cores"

# Get a list of non-default cores
cores=$(curl "localhost:8080/solr/admin/cores?wt=json" --silent | jq -r '.status | values[] | select( .name == "" | not ) | .name')

# Check through the cores already present in SOLR and add any missing ones
cd solr
find -H cores -mindepth 1 -maxdepth 1 -type d | while read coredir; do
  corename=$(basename $coredir)
  if [[ $cores == *"$corename"* ]]; then
    echo "$corename is already loaded"
  else
    # Give the user a chance to process the core before we load it
    for f in /core-init/*; do
      # shellcheck disable=SC1090
      case "$f" in
        *.sh) echo "$0: running $f"; . "$f" "$(realpath $coredir)" ;;
        *)    echo "$0: ignoring $f" ;;
      esac
    done
    # Load the core with cURL
    echo "Creating core $corename"
    curl --fail "http://localhost:8080/solr/admin/cores?action=CREATE&name=$corename&instanceDir=$coredir&wt=json" --silent | jq -r
  fi
done
cd ..

# Return control to catalina.sh
fg %1
