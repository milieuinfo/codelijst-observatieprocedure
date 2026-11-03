import { create_metadata, create_odcs } from '@milieuinfo/maven-metadata-generator-npm';
import {
    metadataSource,
    metadataOptions,
    datasetOptions,
    catalogOptions,
    odcsSource,
    odcsOptions
} from './utils/variables.js';

// create_metadata maakt ../temp/ leeg, dus het ODCS-contract pas daarna schrijven
await create_metadata(
    metadataSource,
    metadataOptions,
    datasetOptions,
    catalogOptions);

await create_odcs(
    odcsSource,
    metadataOptions,
    odcsOptions);
