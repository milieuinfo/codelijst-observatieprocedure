#!/bin/bash
pushd ../../..
git pull
popd
Rscript ../R/dcat-from-csv-2.0.0.R
