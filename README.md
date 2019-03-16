# BuyerQuest SOLR3

This is a container for SOLR3 that runs on OpenJDK 8 and Tomcat 9.

# Usage

Mount a directory of SOLR cores, one per subdir, to `/cores` inside the container. The startup script will attempt to create a core from each of the folders in the `/cores` directory. If you need to perform any kind of processing on the core, the startup script will invoke any `.sh` files present in `/core-init`, with the `$1` variable being the path to the core.

If you want to provide extra configuration to Tomcat, add the required items to the EXTRA_CATALINA_OPTS environment variable.

# Volumes

|    Volume    |                                                                              Purpose                                                                              |
|:------------:|:-----------------------------------------------------------------------------------------------------------------------------------------------------------------:|
|   `/cores`   | Solr cores go here. One per folder inside of this one.                                                                                                            |
| `/core-init` | All .sh files inside of this folder will be executed before any core is `CREATE`d in SOLR. The script will be provided the path of the core as the `$1` argument. |

# Environment

| Variable              | Default |
|-----------------------|:-------:|
| `SOLR_XMS`            |  `128m` |
| `SOLR_XMX`            | `1024m` |
| `EXTRA_CATALINA_OPTS` |    ``   |

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
