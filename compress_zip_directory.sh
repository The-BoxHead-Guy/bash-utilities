#!/bin/bash

# Script name: compress_zip_directory.sh
# Description: Compresses a directory into a ZIP file with timestamp or custom name
# Version: 1.0.1

# Function to display a friendly message about what's happening
show_message() {
  echo "📦 $1"
}

show_sucess_message() {
  echo "✅ $1"
}

# Function to handle errors with clear feedback
handle_error() {
  echo "❌ Oops! Something went wrong: $1"
  exit 1
}

# Function to display usage instructions with examples
show_usage() {
  show_message "Let me show you how to use this script:"
  show_message "Basic usage: $0 <directory_path>"
  show_message "With custom name: $0 <directory_path> <custom_name>"
  show_message ""
  show_message "Examples:"
  show_message "  $0 /path/to/directory        # Creates: directory_20240404_143022.zip"
  show_message "  $0 /path/to/directory backup # Creates: backup.zip"
  exit 1
}

# Function to verify required tools are available
check_requirements() {
  if ! command -v zip &> /dev/null; then
    handle_error "The zip command is not installed. Please install it first with: sudo apt install zip"
  fi
}

# Function to generate a timestamp for automatic naming
get_timestamp() {
    date "+%Y%m%d_%H%M%S"
}

# Function to create the appropriate filename based on user input
generate_filename() {
    local source_dir="$1"
    local custom_name="$2"
    
    # Clean up the directory path by removing trailing slashes
    source_dir=${source_dir%/}
    
    # If a custom name is provided, use it (with cleanup)
    if [ -n "$custom_name" ]; then
        # Remove .zip extension if the user included it
        custom_name=${custom_name%.zip}
        echo "${custom_name}.zip"
    else
        # Create an automatic name using the directory name and timestamp
        local dir_name=$(basename "$source_dir")
        local timestamp=$(get_timestamp)
        echo "${dir_name}_${timestamp}.zip"
    fi
}

# Main compression function with support for custom naming
compress_directory() {
    local source_dir="$1"
    local custom_name="$2"
    
    # Verify the source directory exists
    if [ ! -d "$source_dir" ]; then
        handle_error "Directory '$source_dir' not found!"
    fi
    
    # Generate the appropriate filename (custom or automatic)
    local zip_file=$(generate_filename "$source_dir" "$custom_name")
    
    # Begin compression process with user feedback
    show_message "Starting to pack up directory: $source_dir"
    if [ -n "$custom_name" ]; then
        show_message "Using custom name: $zip_file"
    fi
    show_message "This might take a moment..."

    sleep 1

    # Perform the compression
    if zip -r "$zip_file" "$source_dir" > /dev/null 2>&1; then
        show_message "Compressing..."
        sleep 1

        show_sucess_message "Successfully created: $zip_file"
        show_message "ZIP file size: $(du -h "$zip_file" | cut -f1)"
    else
        handle_error "Failed to create ZIP file"
    fi
}

# Verify zip command is available
check_requirements

# Validate the number of arguments provided
if [ $# -eq 0 ] || [ $# -gt 2 ]; then
    show_usage
fi

# Start compression with all provided arguments
compress_directory "$1" "$2"