#!/bin/bash

# Transform csv, ../resources/be/vlaanderen/omgeving/data/id/conceptscheme/observatieprocedure/observatieprocedure.csv
# to jsonld, /tmp/observatieprocedure.jsonld
Rscript ../R/csv_to_json.R
