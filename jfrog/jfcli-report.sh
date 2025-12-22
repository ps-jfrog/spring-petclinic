
clear

export JF_NAME="psazuse" JFROG_CLI_LOG_LEVEL="DEBUG" 
export JF_RT_URL="https://${JF_NAME}.jfrog.io" RT_REPO_VIRTUAL="springpetclinic-mvn-virtual" 


frogbot() {
    export GIT_REPO_PATH=$(git remote get-url origin)
    export GIT_REPO_NAME="${GIT_REPO_PATH#git@github.com:}"
    echo "GIT_REPO_NAME: $GIT_REPO_NAME"
    export REPO_FULL_URL="https://github.com/${GIT_REPO_NAME}"

    # Get the list of frogbot repositories
    export GIT_REPO_JSON="./frogbot-repo.json"
    jf xr curl "/api/v1/git/repositories" -H 'Content-Type: application/json' -o $GIT_REPO_JSON
    REPO_COUNT=$(cat "$GIT_REPO_JSON" | jq '.repositories | length')

    # Iterate through repositories
    export REPO_ID=""
    for i in $(seq 0 $((REPO_COUNT - 1))); do
        REPO_URL=$(jq -r ".repositories[$i].url" "$GIT_REPO_JSON")
        
        # Compare URL with REPO_FULL_URL
        if [ "$REPO_URL" == "$REPO_FULL_URL" ]; then
            export REPO_ID=$(jq -r ".repositories[$i].id" "$GIT_REPO_JSON")
            break
        fi
    done

    echo "Found repository ID: $REPO_ID for GIT_REPO_NAME: $GIT_REPO_NAME"

    # repo vunerabilitiies
    export GIT_REPO_VUNL_JSON="./frogbot-scanreport.json"
    jf xr curl "/api/v1/git/repositories/$REPO_ID/commits/$(git rev-parse HEAD)/scan-results?branch_name=$(git branch --show-current)" -H 'Content-Type: application/json' -o $GIT_REPO_VUNL_JSON
    # Get the count of SAST results
    sast_count=$(cat "$GIT_REPO_VUNL_JSON" | jq '.scan_results.sast | length')

    if [ "$sast_count" -eq 0 ]; then
        echo " - :no_good: :volcano: NO SAST results found" 
    else
        echo "Found $sast_count SAST results"
        echo " | ID | JFrog Severity | File name | start line | abbreviation | description |" 
        echo " | :--- | :--- | :--- | :--- | :--- | :--- |"

        # Iterate through SAST results and print jfrog_severity, id, and file
        cat "$GIT_REPO_VUNL_JSON" | jq -r '.scan_results.sast[] | "\(.jfrog_severity)|\(.id)|\(.file)|\(.start_line)|\(.abbreviation)|\(.description)|"' | while IFS='|' read -r severity id file start_line abbreviation description; do
            echo " | $id | $severity | $file | $start_line | $abbreviation | $description |" 
        done
    fi

    rm -rf $GIT_REPO_JSON
    rm -rf $GIT_REPO_VUNL_JSON
}

xray_mvn_app() {
    export BUILD_NAME="spring-petclinic" BUILD_ID="psj-dkr-52" # "psj-mvn-52"

    export BUILD_SCAN_RESP_JSON="gitrepo-scan-${BUILD_ID}.json"

    jf xr curl "/api/v1/summary/build?build_name=${BUILD_NAME}&&build_number=${BUILD_ID}" -H 'Content-Type: application/json' -o $BUILD_SCAN_RESP_JSON
    # cat $BUILD_SCAN_RESP_JSON

    echo "# :frog: Xray Scan Summary for build :pushpin:" 
    echo " -  ${BUILD_NAME}/${BUILD_ID} " 
    echo " " 
    echo "## :bug: :worm: :beetle: ISSUES :ghost:" 
   
    echo " "
    echo "## :bug: :worm: :beetle: LICENSES :ghost:" 
    echo " - Total licenses usage for the build: $(cat $BUILD_SCAN_RESP_JSON | jq -r '.licenses | length')" 
    echo " - Licenses: "
    cat $BUILD_SCAN_RESP_JSON | jq -r '.licenses[].name' | sort -u | while read -r license; do
        echo "  - $license"
    done
    
    echo " "
    echo "## :bug: :worm: :beetle: OPERATIONAL RISKS :ghost:" 
    echo " - Total operational risks for the build: $(cat $BUILD_SCAN_RESP_JSON | jq -r '.operational_risks | length')" 
    echo " | component | current version | risk | latest version | released | " 
    echo " | :--- | :--- | :--- | :--- | :--- | "

    # Function to extract package name and version from component_id
    extract_component_info() {
        local component_id="$1"
        # Remove protocol prefix (e.g., "npm://" or "gav://")
        local without_protocol="${component_id#*://}"
        # Extract package name (everything before the last colon)
        local package_name="${without_protocol%:*}"
        # Extract version (everything after the last colon)
        local version="${without_protocol##*:}"
        echo "$package_name|$version"
    }

    cat $BUILD_SCAN_RESP_JSON | jq -r '.operational_risks[] | "\(.component_id)|\(.current_version)|\(.risk)|\(.latest_version)|\(.released)|"' | while IFS='|' read -r component_id current_version risk latest_version released; do
        # Extract package name and version from component_id
        component_info=$(extract_component_info "$component_id")
        component_name=$(echo "$component_info" | cut -d'|' -f1)
        component_version=$(echo "$component_info" | cut -d'|' -f2)

        echo " | $component_name | $component_version | $risk | $latest_version | $released |"
    done

    echo " "
    rm -rf $BUILD_SCAN_RESP_JSON
}


xray_mvn_rbv2_violations() {
    export BUILD_NAME="spring-petclinic" BUILD_ID="psj-mvn-53" # "psj-mvn-52"
    export BUILD_SCAN_RESP_JSON="rbv2-violations-${BUILD_ID}.json" JFROG_CLI_LOG_LEVEL="DEBUG" 

    export REQ_JSON="{ \"filters\": { \"resources\": { \"release_bundles_v2\": [ { \"name\": \"${BUILD_NAME}\", \"version\": \"${BUILD_ID}\" } ] } } }"

    export RBV2_VOILATIONS_RESP_JSON="rbv2-violations-${BUILD_ID}.json"

    jf xr curl -X POST "/api/v1/violations" -H 'Content-Type: application/json' -d "$REQ_JSON" -o $RBV2_VOILATIONS_RESP_JSON
    # cat $RBV2_VOILATIONS_RESP_JSON

    echo "# :frog: Xray RBv2 Policy Violations :pushpin:" 
    echo " " 
    echo " " 
    echo " - RBv2: ${BUILD_NAME}/${BUILD_ID} " 
    echo " - Total violations for RBv2: $(cat $RBV2_VOILATIONS_RESP_JSON | jq -r '.total_violations')"  
    echo " " 
    echo " " 

    echo " | issue_id | type | severity | watch_name | component_physical_paths | " 
    echo " | :--- | :--- | :--- | :--- | :--- | " 

    cat $RBV2_VOILATIONS_RESP_JSON | jq -r '.violations[] | "\(.issue_id)|\(.violation_details_url)|\(.type)|\(.severity)|\(.watch_name)|\(.component_physical_paths | join("; "))|"' | while IFS='|' read -r issue_id violation_details_url type severity watch_name component_physical_paths; do
        echo " | [$issue_id]($violation_details_url) | $type | $severity | $watch_name | $component_physical_paths | "
    done
    echo " " 
    echo " "

    rm -rf $RBV2_VOILATIONS_RESP_JSON
}

# frogbot
# echo "--------------------------------"
#xray_mvn_app

xray_mvn_rbv2_violations
