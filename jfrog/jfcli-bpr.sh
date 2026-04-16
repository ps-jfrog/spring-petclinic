
clear

export JF_NAME="psazuse" JFROG_CLI_LOG_LEVEL="DEBUG" 
export JF_RT_URL="https://${JF_NAME}.jfrog.io" RT_REPO_VIRTUAL="bpr-spring-petclinic-docker-virtual" 

export PROJECT_KEY="ps-build-promote"
export BUILD_NAME="spring-petclinic" BUILD_ID="cmd.$(date '+%Y-%m-%d-%H-%M')" 

jf mvnc --global --repo-resolve-releases ${RT_REPO_VIRTUAL} --repo-resolve-snapshots ${RT_REPO_VIRTUAL} 

jf mvn clean install -DskipTests=true --build-name ${BUILD_NAME} --build-number ${BUILD_ID} --detailed-summary=true --project $PROJECT_KEY

sleep 2
echo "\n*** Build publish: name: ${BUILD_NAME} ID: ${BUILD_ID} \n"
jf rt bce ${BUILD_NAME} ${BUILD_ID} 
jf rt bp ${BUILD_NAME} ${BUILD_ID} --detailed-summary=true 

sleep 2
echo "\n*** Build Promote: SNAPSHOT to DEV\n"
# jf rt bpr spring-petclinic cmd.2026-03-19-10-52  --dry-run --source-repo=springpetclinic-mvn-dev-local --comment="Promoting build SNAPSHOT to DEV" --status
jf rt bpr ${BUILD_NAME} ${BUILD_ID} ${RT_REPO_DEV_LOCAL} --status="Promoting build SNAPSHOT to DEV" 

sleep 2
jf -v