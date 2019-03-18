#!/bin/bash

# Check some things to ensure that we're only doing this on the first run of the container
shouldPerformInitContainer=''

# if we've got any /container-init/* files to parse later, we should InitContainer
for f in /container-init/*; do
  case "$f" in
    *.sh|*.js) # this should match the set of files we check for below
      shouldPerformInitContainer="$f"
      break
      ;;
  esac
done

# check for a few known paths (to determine whether we've already initialized and should thus skip our InitContainer scripts)
if [ -n "$shouldPerformInitContainer" ]; then
  for path in \
    "/usr/local/tomcat/solr/data/index" \
    "/usr/local/tomcat/webapps/solr" \
    "/usr/local/tomcat/work/Catalina" \
  ; do
    if [ -e "$path" ]; then
      shouldPerformInitContainer=
      break
    fi
  done
fi

# Run any user-supplied container init scripts
if [ -n "$shouldPerformInitContainer" ]; then
  for f in /container-init/*; do
    # shellcheck disable=SC1090
    case "$f" in
      *.sh) echo "$0: running $f"; . "$f" ;;
      *)    echo "$0: ignoring $f" ;;
    esac
    echo
  done
fi
