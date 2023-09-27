#!/bin/bash

# Transform csv, ../resources/be/vlaanderen/omgeving/data/id/conceptscheme/observatieprocedure/observatieprocedure.csv
# to jsonld, /tmp/observatieprocedure.jsonld
Rscript ../R/csv_to_json.R
shacl v --shapes ../resources/be/vlaanderen/omgeving/data/id/ontology/observatieprocedure-ap-constraints/observatieprocedure-ap-constraints.ttl --data ../resources/be/vlaanderen/omgeving/data/id/conceptscheme/observatieprocedure/observatieprocedure.ttl

