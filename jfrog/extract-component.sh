#!/bin/bash

# Function to extract package name and version from component_id
# Usage: extract_component_info "npm://font-awesome:4.7.0"
# Returns: package_name|version
extract_component_info() {
    local component_id="$1"
    if [ -z "$component_id" ]; then
        echo "Error: component_id is required" >&2
        return 1
    fi
    
    # Remove protocol prefix (e.g., "npm://" or "gav://")
    local without_protocol="${component_id#*://}"
    
    # Extract package name (everything before the last colon)
    local package_name="${without_protocol%:*}"
    
    # Extract version (everything after the last colon)
    local version="${without_protocol##*:}"
    
    echo "$package_name|$version"
}

# Example usage
if [ "$#" -eq 0 ]; then
    echo "Usage: $0 <component_id>"
    echo "Example: $0 'npm://font-awesome:4.7.0'"
    exit 1
fi

component_id="$1"
result=$(extract_component_info "$component_id")

if [ $? -eq 0 ]; then
    package_name=$(echo "$result" | cut -d'|' -f1)
    version=$(echo "$result" | cut -d'|' -f2)
    
    echo "Component ID: $component_id"
    echo "Package Name: $package_name"
    echo "Version: $version"
else
    exit 1
fi

