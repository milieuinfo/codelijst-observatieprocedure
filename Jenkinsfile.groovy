@Library('Cumulus@1.3-stable') _
pipeline {
    agent {
        kubernetes {
            inheritFrom 'jenkins-jenkins-agent'
            yaml podBuilder.from([maven.podSpec(25, 'ubuntu'), dind, sonar, trivy])
        }
    }
    environment {
        SONAR_PROJECT_KEY = 'be.vlaanderen.omgeving.data.id.graph:codelijst-observatieprocedure'
    }
    stages {
        stage("Setup") {
            steps {
                script {
                    if (env.BRANCH_IS_PRIMARY) {
                        properties([versions.releaseParameters()])
                        def currentVersion = maven.version()
                        if (versions.isRelease()) {
                            def version = versions.bump(currentVersion)
                            git.validateTag(version)
                            maven.validateVersion(version)
                            env.VERSION = version
                        }
                    } else {
                        properties([parameters([
                                booleanParam(name: 'DEPLOY', defaultValue: false, description: 'If true, runs mvn deploy instead of mvn verify.')
                        ])])
                    }
                }
            }
        }
        stage("Controle gegenereerde SKOS") {
            // De SKOS-bestanden in src/main/resources worden lokaal gegenereerd en gecommit,
            // zodat ze in de tag op hun pad staan. Genereer ze hier opnieuw uit src/source
            // en faal als ze afwijken van wat gecommit is (vóór release:prepare een tag maakt).
            when {
                expression { git.notSkipCi() }
            }
            steps {
                script {
                    maven.goal([goal: 'generate-resources'])
                    sh '''
                        git -c safe.directory="$WORKSPACE" status --porcelain -- src/main/resources > skos-diff.txt
                        if [ -s skos-diff.txt ]; then
                            echo "De gegenereerde SKOS-bestanden wijken af van de gecommitte versie:"
                            cat skos-diff.txt
                            git -c safe.directory="$WORKSPACE" --no-pager diff --stat -- src/main/resources
                            echo "Draai lokaal 'pnpm run create_skos' en commit het resultaat."
                            rm -f skos-diff.txt
                            exit 1
                        fi
                        rm -f skos-diff.txt
                    '''
                }
            }
        }
        stage("Non-primary branch") {
            when {
                allOf {
                    not { expression { env.BRANCH_IS_PRIMARY } }
                    expression { git.notSkipCi() }
                }
            }
            parallel {
                stage("Trivy scan") {
                    steps {
                        script {
                            trivy.scanFilesystem([targetPath: 'pom.xml'])
                        }
                    }
                }
                stage("Maven verify") {
                    when {
                        expression { !(params.DEPLOY ?: false) }
                    }
                    steps {
                        script {
                            maven.goal([goal: 'verify'])
                        }
                    }
                }
                stage("Maven deploy") {
                    when {
                        expression { params.DEPLOY ?: false }
                    }
                    steps {
                        script {
                            maven.goal([goal: 'deploy'])
                        }
                    }
                }
            }
        }
        stage("Primary branch") {
            when {
                allOf {
                    expression { env.BRANCH_IS_PRIMARY }
                    expression { git.notSkipCi() }
                }
            }
            stages {
                stage("Maven prepare") {
                    when {
                        expression { versions.isRelease() }
                    }
                    steps {
                        script {
                            maven.goal([goal     : 'release:clean release:prepare',
                                        version  : env.VERSION,
                                        skipTests: true
                            ])
                        }
                    }
                }
                stage("Maven deploy") {
                    steps {
                        script {
                            maven.goal([goal: 'deploy'])
                        }
                    }
                }
                stage("Sonar scan") {
                    steps {
                        script {
                            sonar.scanMaven([
                                    projectKey        : env.SONAR_PROJECT_KEY,
                                    tolerateBadQuality: true
                            ])
                        }
                    }
                }
                stage("Maven release") {
                    when {
                        expression { versions.isRelease() }
                    }
                    steps {
                        script {
                            maven.goal([goal     : 'release:perform',
                                        version  : env.VERSION,
                                        skipTests: true
                            ])
                        }
                    }
                }
            }
        }
    }
    post {
        always {
            script {
                pipelineSummary([sonarProjectKey: env.BRANCH_IS_PRIMARY ? env.SONAR_PROJECT_KEY : null])
            }
        }
    }
}
