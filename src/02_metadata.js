import { create_metadata } from '@milieuinfo/maven-metadata-generator-npm';
import {
    metadataSource,
    metadataOptions,
    datasetOptions,
    catalogOptions
} from './utils/variables.js';

create_metadata(
    metadataSource,
    metadataOptions,
    datasetOptions,
    catalogOptions)