#!/bin/bash

# Code coverage generation script

# Set the coverage directory, default to 'coverage' if not set
COVERAGE_DIR="${COVERAGE_DIR:-coverage}"
PKG_LIST=$(go list ./... | grep -v /vendor/)

# Create a temporary directory for coverage files
TEMP_COVERAGE_DIR=$(mktemp -d)

# Function to clean up temporary directory on exit
cleanup() {
    rm -rf "$TEMP_COVERAGE_DIR"
}
trap cleanup EXIT

# Create a coverage file for each package
for package in ${PKG_LIST}; do
    go test -covermode=count -coverprofile "${TEMP_COVERAGE_DIR}/${package##*/}.cov" "$package"
    if [[ $? -ne 0 ]]; then
        echo "Error: Coverage test failed for package $package"
        exit 1
    fi
done

# Merge the coverage profile files
echo 'mode: count' > "${COVERAGE_DIR}/coverage.cov"
tail -q -n +2 "${TEMP_COVERAGE_DIR}"/*.cov >> "${COVERAGE_DIR}/coverage.cov"

# Display the global code coverage
go tool cover -func="${COVERAGE_DIR}/coverage.cov"

# Generate HTML report if requested
if [[ "$1" == "html" ]]; then
    go tool cover -html="${COVERAGE_DIR}/coverage.cov" -o coverage.html
    echo "HTML report generated at coverage.html"
fi

# Cleanup is handled by the trap and cleanup function
