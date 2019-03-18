# BuyerQuest SOLR3

This is a container for SOLR3 that runs on OpenJDK 8 and Tomcat 9.

# Usage

Mount a directory of SOLR cores, one per subdir, to `/cores` inside the container. The startup script will attempt to create a core from each of the folders in the `/cores` directory.

## Optional scripts

- /container-init/

On the very first startup of the container, every `.sh` file present in this directory will run. This gives you the opportunity to perform any first-run things that need to happen inside of the container before Tomcat starts up.

- /core-init/

For any cores that aren't already loaded, the startup script will invoke any `.sh` files present in `/core-init`, with the `$1` variable being the path to the core directory. Currently, cores are not persisted to the SOLR config so they're remounted every time the container starts, so it is suggested that you make any scripts in this folder idempotent.

## Volumes

|    Volume    |                                                                              Purpose                                                                              |
|:------------:|:-----------------------------------------------------------------------------------------------------------------------------------------------------------------:|
|   `/cores`   | Solr cores go here. One per folder inside of this one.                                                                                                            |

## Environment

| Variable              | Default |
|-----------------------|:-------:|
| `SOLR_XMS`            |  `128m` |
| `SOLR_XMX`            | `1024m` |
| `EXTRA_CATALINA_OPTS` |    ``   |

If you want to provide extra configuration to Tomcat, add the required items to the EXTRA_CATALINA_OPTS environment variable.

# Example

```bash
docker run -d \
  --name solr3 \
  -p 8080:8080 \
  -v $PWD/cores:/cores \
  -v $PWD/core-init:/core-init:ro \
  -v $PWD/container-init:/container-init:ro \
  buyerquest/solr3:latest
```

# Notes

### SOLR Plugins

The following SOLR plugins are installed:

- commons-lang3
- mongo-java-driver
- [solr-mongo-importer](https://github.com/BuyerQuest/SolrMongoImporter)
- mysql-connector

### Extra Software

- xmlstarlet
- jq
- liblz4-tool

XMLStarlet and jq are useful for querying SOLR with shell scripts and modifying core schema. We use lz4 for compressing SOLR core exports so it is also included in the container.
