
clear

export JF_NAME="psazuse" JFROG_CLI_LOG_LEVEL="DEBUG" 
export JF_RT_URL="https://${JF_NAME}.jfrog.io" RT_REPO_VIRTUAL="springpetclinic-mvn-virtual" 


export GIT_REPO_URL="/xray/api/v1/git/repositories" GIT_REPO_JSON="./GitRepo.json"
jf xr curl /xray/api/v1/git/repositories -H 'Content-Type: application/json' 
# # ps-jfrog/spring-petclinic.git
# export GIT_REPO_ID=$(cat $GIT_REPO_JSON | jq -r '.repositories[] | select(.url == "ps-jfrog/spring-petclinic.git") | .url')
# echo "GIT_REPO_ID: $GIT_REPO_ID"



# export GIT_REPO_COMMIT_HASH=$(git rev-parse HEAD)
# echo "GIT_REPO_COMMIT_HASH: $GIT_REPO_COMMIT_HASH"

# export GIT_REPO_COMMIT_HASH_SCAN_RESULTS_JSON="./GitRepoCommitHashScanResults-${{env.BUILD_ID}}.json"
# jf xr "/xray/api/v1/git/repositories/$GIT_REPO_ID/commits/$GIT_REPO_COMMIT_HASH/scan-results?branch_name=main" -H 'Content-Type: application/json' -o $GIT_REPO_COMMIT_HASH_SCAN_RESULTS_JSON
# cat $GIT_REPO_COMMIT_HASH_SCAN_RESULTS_JSON


