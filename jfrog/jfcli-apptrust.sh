
clear

export JF_NAME="psazuse" JFROG_CLI_LOG_LEVEL="DEBUG" 
export JF_RT_URL="https://${JF_NAME}.jfrog.io" RT_REPO_VIRTUAL="krishna-apptrust-java-virtual"  PROJECT_KEY="krishna-apptrust"

export BUILD_NAME="spring-petclinic" BUILD_ID="cmd-at.$(date '+%Y-%m-%d-%H-%M')" 

echo "Current directory: $(pwd)" 
cd ..
echo "Current directory: $(pwd)" 

jf mvnc --global --repo-resolve-releases ${RT_REPO_VIRTUAL} --repo-resolve-snapshots ${RT_REPO_VIRTUAL} 
 
jf mvn install -Denforcer.skip=true --build-name ${BUILD_NAME} --build-number ${BUILD_ID} --project ${PROJECT_KEY}

jf rt bad ${BUILD_NAME} ${BUILD_ID} --project ${PROJECT_KEY}
jf rt bag ${BUILD_NAME} ${BUILD_ID} --project ${PROJECT_KEY}
jf rt bce ${BUILD_NAME} ${BUILD_ID} --project ${PROJECT_KEY}
jf rt bp ${BUILD_NAME} ${BUILD_ID} --project ${PROJECT_KEY}

# echo "Current directory: $(pwd)" 

# # ./jfrog/convertXml2Json.sh ./target/surefire-reports/test-results.json
# ./jfrog/convertXml2Json.sh ../target/surefire-reports/test-results.json

# cat ../target/surefire-reports/test-results.json

