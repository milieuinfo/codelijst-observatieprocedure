'use strict';
import { generate_skos } from '@milieuinfo/maven-metadata-generator-npm';
import {
    skosOptions,
    skosSource
} from './utils/variables.js';


generate_skos(skosOptions, skosSource);

