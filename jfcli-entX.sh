
clear
jf c use psentx 

export JF_NAME="psentx" JFROG_CLI_LOG_LEVEL="DEBUG" 
export PROJECT_KEY="${PROJECT_KEY:-ps-build}"
export JF_RT_URL="https://${JF_NAME}.jfrog.io" RT_REPO_VIRTUAL="spring-petclinic-mvn-virtual" RT_REPO_LOCAL_DEFAULT="spring-petclinic-mvn-init-local"
export RT_REPO_LOCAL_DEV="spring-petclinic-mvn-dev-local" RT_REPO_LOCAL_QA="spring-petclinic-mvn-qa-local" RT_REPO_LOCAL_PROD="spring-petclinic-mvn-prod-local"
# remote: apache-mvn-remote

export BUILD_NAME="spring-petclinic" BUILD_ID="cmd.$(date '+%Y-%m-%d-%H-%M')" 

echo " ** Maven package **"
jf mvnc --global --repo-resolve-releases ${RT_REPO_VIRTUAL} --repo-resolve-snapshots ${RT_REPO_VIRTUAL} --repo-deploy-releases ${RT_REPO_VIRTUAL} --repo-deploy-snapshots ${RT_REPO_VIRTUAL}
jf mvn clean install -DskipTests=true --build-name=${BUILD_NAME} --build-number=${BUILD_ID} --project="${PROJECT_KEY}" --detailed-summary=true

#These properties were captured Artifacts >> repo path 'spring-petclinic.---.jar' >> Properties

jf rt sp "my-build=default;org=ps;team=us-west;" --build=${BUILD_NAME}/${BUILD_ID} --project="${PROJECT_KEY}"

jf rt bce ${BUILD_NAME} ${BUILD_ID} --project="${PROJECT_KEY}"
jf rt bag ${BUILD_NAME} ${BUILD_ID} --project="${PROJECT_KEY}"
jf rt bp ${BUILD_NAME} ${BUILD_ID} --project="${PROJECT_KEY}" --detailed-summary=true

# jf bs ${BUILD_NAME} ${BUILD_ID} --fail=false --rescan=true --format=table --extended-table=true --vuln=true --project="${PROJECT_KEY}" 


# sleep 2
# echo "\n*** Build Promote: SNAPSHOT to DEV\n"

export STATUS_COMMENT="Promoting build SNAPSHOT to DEV"
jf bce ${BUILD_NAME} ${BUILD_ID} --project="${PROJECT_KEY}" 
jf rt sp "dev-promote=user-1" --build=${BUILD_NAME}/${BUILD_ID} --project="${PROJECT_KEY}"
jf rt bpr ${BUILD_NAME} ${BUILD_ID} ${RT_REPO_LOCAL_DEV} --status="${STATUS_COMMENT}" --project="${PROJECT_KEY}" 
# sleep 2


jf rt sp "qa-promote={\"user\":\"user-2\"};team=cust-west;" --build=${BUILD_NAME}/${BUILD_ID} --project="${PROJECT_KEY}"
jf rt bpr ${BUILD_NAME} ${BUILD_ID} ${RT_REPO_LOCAL_QA} --status="${STATUS_COMMENT}" --project="${PROJECT_KEY}" 

jf -v
