#!/bin/bash
pushd ../../..
git pull
popd
Rscript ../R/dcat-from-csv.R
