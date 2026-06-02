
clear
rm -rf .jfrog -y
export JFROG_CLI_LOG_LEVEL="DEBUG" RT_REPO_VIRTUAL="curation-gradle-virtual" 
export RT_REPO_LOCAL="curation-gradle-local"
# remote repo: # proxy to https://psazuse.jfrog.io/artifactory/api/maven/psentx-curation-mvn-remote
# policy: psentx-curation-gradle-remote on https://psazuse.jfrog.io
export RT_REPO_REMOTE="curation-gradle-remote"  
export BUILD_NAME="curation" BUILD_ID="cmd.$(date '+%Y%m%d-%H%M')" 

jf c use psentx

jf gradlec --repo-deploy ${RT_REPO_VIRTUAL} --repo-resolve ${RT_REPO_VIRTUAL} 

# jf mvnc --global --repo-resolve-releases ${RT_REPO_VIRTUAL} --repo-resolve-snapshots ${RT_REPO_VIRTUAL} 

jf ca --format=table --threads=100

# jf mvn clean install --build-name=${BUILD_NAME} --build-number=${BUILD_ID} --project="${PROJECT_KEY}" --detailed-summary=true

# jf rt bp ${BUILD_NAME} ${BUILD_ID} --detailed-summary=true --collect-env=true --collect-git-info=trie
