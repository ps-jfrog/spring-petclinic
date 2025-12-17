
clear

export JF_NAME="psazuse" JFROG_CLI_LOG_LEVEL="DEBUG" 
export JF_RT_URL="https://${JF_NAME}.jfrog.io" RT_REPO_VIRTUAL="springpetclinic-mvn-virtual" 

export BUILD_NAME="spring-petclinic" BUILD_ID="cmd.$(date '+%Y-%m-%d-%H-%M')" 

echo "Current directory: $(pwd)" 
cd ..
echo "Current directory: $(pwd)" 

jf mvnc --global --repo-resolve-releases ${RT_REPO_VIRTUAL} --repo-resolve-snapshots ${RT_REPO_VIRTUAL} 

jf mvn install -DskipTests=true -Denforcer.skip=true --build-name ${BUILD_NAME} --build-number ${BUILD_ID}

jf scan . --format=table --extended-table=true --threads=100 

# jf mvn test -Denforcer.skip

# echo "Current directory: $(pwd)" 

#
# ./jfrog/convertXml2Json.sh ../target/surefire-reports/test-results.json

# cat ../target/surefire-reports/test-results.json
