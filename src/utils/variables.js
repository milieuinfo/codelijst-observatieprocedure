'use strict';
import yaml from 'js-yaml';
import fs, {readFileSync} from "fs";
import rdf from "@zazuko/env-node";
import {metadataOptions, shapes_dcat, dcat_rules, frame_catalog} from "@milieuinfo/maven-metadata-generator-npm/src/utils/variables.js";

const config = yaml.load(fs.readFileSync('./source/config.yml', 'utf8'));

const virtuoso = config.deploy.virtuoso ;

const prefixes = Object.assign( {}, config.skos.prefixes, config.prefixes, { '@base' : config.skos.prefixes.concept })

const context = JSON.parse(fs.readFileSync(config.source.path + config.source.context));

const context_prefixes = Object.assign({},context , prefixes)


const frame_skos_prefixes = {
    "@context": context_prefixes,
    "@type": ["rdfs:Resource", "skos:ConceptScheme", "skos:Collection", "skos:Concept"],
    "seeAlso": {
        "@embed": "@never",
        "@omitDefault": true
    },
    "theme": {
        "@embed": "@never",
        "@omitDefault": true
    },
    "member": {
        "@type": "skos:Concept",
        "@embed": "@never",
        "@omitDefault": true
    },
    "inScheme": {
        "@type": "skos:ConceptScheme",
        "@embed": "@never",
        "@omitDefault": true
    },
    "topConceptOf": {
        "@type": "skos:ConceptScheme",
        "@embed": "@never",
        "@omitDefault": true
    },
    "broader": {
        "@type": "skos:Concept",
        "@embed": "@never",
        "@omitDefault": true
    },
    "narrower": {
        "@type": "skos:Concept",
        "@embed": "@never",
        "@omitDefault": true
    },
    "hasTopConcept": {
        "@type": "skos:Concept",
        "@embed": "@never",
        "@omitDefault": true
    },
    "references":{
        "@embed": "@never",
            "@omitDefault": true
    },
    "isReferencedBy":{
        "@embed": "@never",
            "@omitDefault": true
    },
    "relation":{
        "@embed": "@never",
            "@omitDefault": true
    }
}

const frame_skos_no_prefixes = {
    "@context": context,
    "@type": ["http://www.w3.org/2004/02/skos/core#ConceptScheme", "http://www.w3.org/2004/02/skos/core#Collection", "http://www.w3.org/2004/02/skos/core#Concept"],
    "seeAlso": {
        "@embed": "@never",
        "@omitDefault": true
    },
    "theme": {
        "@embed": "@never",
        "@omitDefault": true
    },
    "member": {
        "@type": "http://www.w3.org/2004/02/skos/core#Concept",
        "@embed": "@never",
        "@omitDefault": true
    },
    "inScheme": {
        "@type": "http://www.w3.org/2004/02/skos/core#ConceptScheme",
        "@embed": "@never",
        "@omitDefault": true
    },
    "topConceptOf": {
        "@type": "http://www.w3.org/2004/02/skos/core#ConceptScheme",
        "@embed": "@never",
        "@omitDefault": true
    },
    "broader": {
        "@type": "http://www.w3.org/2004/02/skos/core#Concept",
        "@embed": "@never",
        "@omitDefault": true
    },
    "narrower": {
        "@type": "http://www.w3.org/2004/02/skos/core#Concept",
        "@embed": "@never",
        "@omitDefault": true
    },
    "hasTopConcept": {
        "@type": "http://www.w3.org/2004/02/skos/core#Concept",
        "@embed": "@never",
        "@omitDefault": true
    },
    "references":{
        "@embed": "@never",
        "@omitDefault": true
    },
    "isReferencedBy":{
        "@embed": "@never",
        "@omitDefault": true
    },
    "relation":{
        "@embed": "@never",
        "@omitDefault": true
    }
}

const turtlePath = config.skos.path + config.skos.name + '/' + config.skos.name + config.skos.turtle

const ntriplesPath = config.skos.path + config.skos.name + '/' + config.skos.name + config.skos.nt

const jsonldOptions = {"file": config.skos.path + config.skos.name + '/' + config.skos.name + config.skos.jsonld, "frame": frame_skos_prefixes}

const csvOptions = {"file": config.skos.path + config.skos.name + '/' + config.skos.name + config.skos.csv, "frame": frame_skos_no_prefixes}

const jsonOptions = {"file": config.skos.path + config.skos.name + '/' + config.skos.name + config.skos.json, "frame": frame_skos_no_prefixes}

const parquetOptions = {"file": config.skos.path + config.skos.name + '/' + config.skos.name + config.skos.parquet, "frame": frame_skos_no_prefixes}

const skos_prefixes = Object.assign( {}, config.skos.prefixes, config.prefixes, { '@base' : config.skos.prefixes.concept })

const skos_context = JSON.parse(readFileSync(config.source.path + config.source.context));

const dcat_dataset_jsonld = '../temp/' + config.dcat.path_dataset + metadataOptions.artifactId + '/' + config.dcat.dataset_jsonld

const dcat_dataset_turtle = '../temp/' + config.dcat.path_dataset + metadataOptions.artifactId + '/' + config.dcat.dataset_turtle

const dcat_catalog_jsonld = '../temp/' + config.dcat.path_catalog + metadataOptions.artifactId + '/' + config.dcat.catalog_jsonld

const dcat_catalog_turtle = '../temp/' + config.dcat.path_catalog + metadataOptions.artifactId + '/' + config.dcat.catalog_turtle

const datasetOptions = {
    "turtlePath": dcat_dataset_turtle,
    "jsonldOptions": {"file": dcat_dataset_jsonld, "frame": frame_catalog}
}

const dcat_dataset_odcs = '../temp/' + config.dcat.path_dataset + metadataOptions.artifactId + '/' + (config.dcat.dataset_odcs ?? 'dataset.odcs.yaml')

const odcsOptions = {
    "file": dcat_dataset_odcs
}

const catalogOptions = {
    "turtlePath": dcat_catalog_turtle,
    "jsonldOptions": {"file": dcat_catalog_jsonld, "frame": frame_catalog}
}

const skosOptions = {
    "turtlePath": turtlePath,
    "jsonOptions": jsonOptions,
    "jsonldOptions": jsonldOptions,
    "ntriplesPath": ntriplesPath,
    "csvOptions": csvOptions,
    "parquetOptions": parquetOptions,
    //"xsdOptions": xsdOptions
}

const skosSource = {
    "sourcePaths": config.source.codelijst_csv.map(csv => config.source.path + csv),
    "contextPrefixes": Object.assign({},skos_context , skos_prefixes),
    "rules": config.skos.rules,
    "shapesDataset": await rdf.dataset().import(rdf.fromFile(config.ap.path + config.ap.name + '-' + config.ap.type + '/' + config.ap.name + '-' + config.ap.type + config.ap.turtle)),
    "prefixes": Object.assign( {}, config.skos.prefixes, config.prefixes)
}

// ODCS data contract voor de parquet-distributie: kolommen uit het parquet-bestand,
// predicaten uit de JSON-LD-context, omschrijvingen uit de SHACL-shapes van het AP
const odcsSource = {
    "config": config,
    "parquetFile": parquetOptions.file,
    "context": skos_context,
    "shapesDataset": skosSource.shapesDataset,
    "prefixes": skos_prefixes
}

const metadataSource = {
    "shapesDataset": shapes_dcat,
    "rules": dcat_rules,
    "prefixes": config.prefixes
}

export {
    virtuoso,
    skosOptions,
    skosSource,
    metadataSource,
    metadataOptions,
    datasetOptions,
    catalogOptions,
    odcsSource,
    odcsOptions
};
