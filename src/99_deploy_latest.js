import { deploy_latest } from '@milieuinfo/maven-metadata-generator-npm';
import { set_env } from './utils/setenv.js';

const omgeving = 'pr'
set_env(omgeving)
deploy_latest(omgeving)
