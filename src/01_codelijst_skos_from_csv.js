'use strict';
import {  generate_skos } from 'maven-metadata-generator-npm';
import {
    frame_skos_prefixes,
    frame_skos_no_prefixes,
    config
} from './utils/variables.js';

const ttl_file = config.skos.path + config.skos.name + '/' + config.skos.name + config.skos.turtle

const nt_file = config.skos.path + config.skos.name + '/' + config.skos.name + config.skos.nt

const jsonld_file = [config.skos.path + config.skos.name + '/' + config.skos.name + config.skos.jsonld, frame_skos_prefixes]

const csv_file = [config.skos.path + config.skos.name + '/' + config.skos.name + config.skos.csv, frame_skos_no_prefixes]

generate_skos(ttl_file, jsonld_file, nt_file, csv_file);

