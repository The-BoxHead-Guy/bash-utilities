#!/bin/bash

# Script name: dev_start.sh
# Description: Initializes development environment in WSL

# Function to handle errors
handle_error() {
    echo "Error: $1"
    exit 1
}

# Function to check if XAMPP is already running
check_xampp_status() {
    if pgrep -x "mysqld" >/dev/null || pgrep -x "httpd" >/dev/null; then
        echo "XAMPP is already running"
        return 0
    fi
    return 1
}

# Main script execution
echo "Initializing development environment..."

# Change to development directory
if ! cd /opt/lampp/htdocs; then
    handle_error "Could not change to development directory"
fi
echo "Successfully changed to development directory"

# Start XAMPP if not already running
if ! check_xampp_status; then
    echo "Starting XAMPP..."
    if ! sudo /opt/lampp/lampp start; then
        handle_error "Failed to start XAMPP"
    fi
else
    echo "XAMPP is already running - skipping start"
fi

echo "Development environment successfully initialized!"