
clear

export JF_NAME="psazuse" JFROG_CLI_LOG_LEVEL="DEBUG" 
export JF_RT_URL="https://${JF_NAME}.jfrog.io" RT_REPO_VIRTUAL="springpetclinic-gradle-virtual" 
export RT_REPO_SNAPSHOT_LOCAL="springpetclinic-gradle-snapshot-fed-local" RT_REPO_DEV_LOCAL="springpetclinic-gradle-dev-fed-local"

export BUILD_NAME="spring-petclinic" BUILD_ID="cmd.$(date '+%Y%m%d-%H%M')" 

echo "Current directory: $(pwd)" 
cd ..
echo "Current directory: $(pwd)" 

jf gradlec --repo-deploy ${RT_REPO_VIRTUAL} --repo-resolve ${RT_REPO_VIRTUAL} 

jf gradle artifactoryPublish -x test --build-name=${BUILD_NAME} --build-number=${BUILD_ID}

jf rt bag ${BUILD_NAME} ${BUILD_ID} 
jf rt bce ${BUILD_NAME} ${BUILD_ID} 
jf rt bp ${BUILD_NAME} ${BUILD_ID}

echo "Build name: ${BUILD_NAME} Build number: ${BUILD_ID}"
sleep 10
echo "Promoting build to ${RT_REPO_DEV_LOCAL}"
jf rt bpr ${BUILD_NAME} ${BUILD_ID} ${RT_REPO_DEV_LOCAL} --source-repo ${RT_REPO_SNAPSHOT_LOCAL} --comment="Promoting build to dev"
