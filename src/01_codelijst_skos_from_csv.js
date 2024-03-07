'use strict';
import fs from "fs";
import jsonld from 'jsonld';

import N3 from 'n3';
import rdfDataset from '@rdfjs/dataset';
//import {RoxiReasoner} from "roxi-js";
import jp from 'jsonpath';
import  { json2csv }  from 'json-2-csv';
import {convertCsvToXlsx} from '@aternus/csv-to-xlsx';
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

// async function csv_to_jsonld(shapes_skos, ttl_file, jsonld_file, nt_file, csv_file) {
//     console.log("1: csv to jsonld ");
//     await csv({
//         ignoreEmpty:true,
//         flatKeys:true
//     })
//         .fromFile(config.source.path + config.source.codelijst_csv)
//         .then((jsonObj)=>{
//             var new_json = new Array();
//             for(var i = 0; i < jsonObj.length; i++){
//                 const object = {};
//                 Object.keys(jsonObj[i]).forEach(function(key) {
//                     object[key] = separateString(jsonObj[i][key]);
//                 })
//                 new_json.push(object)
//             }
//             let jsonld = {"@graph": new_json, "@context": context_prefixes};
//             console.log("1: Csv to Jsonld");
//             (async () => {
//                 const nt = await n3_reasoning(jsonld, skos_rules)
//                 output(shapes_skos, nt, ttl_file, jsonld_file, nt_file, csv_file)
//             })()
//         })
// }



generate_skos(ttl_file, jsonld_file, nt_file, csv_file);

