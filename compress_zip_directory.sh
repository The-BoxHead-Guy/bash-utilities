#!/bin/bash

# Script name: compress_zip_directory.sh
# Description: Compresses a directory into a ZIP file with optimized feedback
# Version: 1.0.9

ZIP_DEBUG="-v"
PROGRESS_CHAR="#"
REMAINING_CHAR="-"

show_progress_bar() {
    local message="$1"
    local width=30
    local i=0
    
    while [ $i -lt $width ]; do
        printf "\r[%s%s] %s" \
            "$(printf "%${i}s" | tr ' ' "$PROGRESS_CHAR")" \
            "$(printf "%$((width-i))s" | tr ' ' "$REMAINING_CHAR")" \
            "$message"
        i=$((i+2))  # Increased step size for faster progress
        sleep 0.05  # Reduced sleep time
    done
    printf "\n"
}

show_message() {
    echo "📦 $1"
    sleep 0.2  # Reduced from 0.5
}

show_success_message() {
    echo "✅ $1"
}

handle_error() {
    echo "❌ $1"
    exit 1
}

compress_directory() {
    local source_dir="$1"
    local custom_name="$2"
    
    source_dir=$(realpath "$source_dir")
    
    local zip_name
    if [ -n "$custom_name" ]; then
        zip_name="${custom_name%.zip}.zip"
    else
        zip_name="$(basename "$source_dir")_$(date +%Y%m%d_%H%M%S).zip"
    fi
    
    local zip_file="$(pwd)/$zip_name"
    
    # Consolidated initial messages
    show_message "Compressing '$(basename "$source_dir")' to '$zip_name'"
    
    # Create temporary directory and start processing
    local temp_dir=$(mktemp -d)
    show_progress_bar "Preparing files"
    rsync -a --exclude='.git' "$source_dir/" "$temp_dir/" > /dev/null 2>&1
    
    if [ $? -ne 0 ]; then
        rm -rf "$temp_dir"
        handle_error "Copy failed. Please try again."
    fi
    
    show_progress_bar "Creating archive"
    (cd "$temp_dir" && zip $ZIP_DEBUG -r "$zip_file" .) > /dev/null 2>&1
    
    local zip_status=$?
    rm -rf "$temp_dir"
    
    if [ $zip_status -eq 0 ] && [ -f "$zip_file" ]; then
        local ratio=$(( ($(du -sb "$source_dir" | cut -f1) - $(du -sb "$zip_file" | cut -f1)) * 100 / $(du -sb "$source_dir" | cut -f1) ))
        show_success_message "Compression Completed!" 
        show_message "File size: $(du -h "$zip_file" | cut -f1) (${ratio}% saved)"
    else
        handle_error "Compression failed. Please try again."
    fi
}

if [ $# -eq 0 ] || [ $# -gt 2 ]; then
    show_message "Usage: script <directory> [name]"
    exit 1
fi

compress_directory "$1" "$2"