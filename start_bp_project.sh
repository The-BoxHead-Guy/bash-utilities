#!/bin/bash

# =============================================================================
# Development Environment Startup Script
# Starts multiple Laravel apps, Vite, and XAMPP
# =============================================================================

# --- Configuration ---
readonly PROJECTS_BASE="$HOME/projects"
readonly API_DIR="$PROJECTS_BASE/api.dataemergencia.com"
readonly SCAEM_DIR="$PROJECTS_BASE/test.scaem.app"
readonly START_DEV_SCRIPT="/home/jhon-p/scripts/dev_start.sh"

# Port assignments
readonly API_PORT=8000
readonly SCAEM_PORT=8001

# Log files
readonly LOG_DIR="/tmp"
readonly API_LOG="$LOG_DIR/laravel_api_dev.log"
readonly SCAEM_LOG="$LOG_DIR/laravel_scaem_dev.log"
readonly VITE_LOG="$LOG_DIR/vite_scaem_dev.log"

# Global arrays
declare -a BACKGROUND_PIDS=()
declare -a LOG_FILES=()

# =============================================================================
# Core Functions
# =============================================================================

# Clean shutdown of all processes
cleanup() {
    echo -e "\n🛑 Shutting down development servers..."

    if [[ ${#BACKGROUND_PIDS[@]} -gt 0 ]]; then
        echo "Stopping PIDs: ${BACKGROUND_PIDS[*]}"
        kill "${BACKGROUND_PIDS[@]}" 2>/dev/null
        sleep 2

        # Check for stubborn processes
        for pid in "${BACKGROUND_PIDS[@]}"; do
            if kill -0 "$pid" 2>/dev/null; then
                echo "⚠️  PID $pid still running. Use: kill -9 $pid"
            fi
        done
    fi

    echo "✅ Cleanup complete"
    echo "💡 XAMPP may need manual shutdown"
}

# Start a background service and track it
start_service() {
    local name="$1"
    local command="$2"
    local log_file="$3"
    local directory="${4:-$(pwd)}"

    echo -e "\n🚀 Starting $name..."

    if [[ ! -d "$directory" ]]; then
        echo "❌ Directory not found: $directory"
        return 1
    fi

    cd "$directory" || return 1

    # Start service in background
    eval "$command" > "$log_file" 2>&1 &
    local pid=$!

    BACKGROUND_PIDS+=("$pid")
    LOG_FILES+=("$log_file")

    echo "✅ $name started (PID: $pid)"
    echo "📝 Log: $log_file"

    cd - > /dev/null || true
    sleep 1
}

# Monitor logs in real-time
monitor_logs() {
    if [[ ${#LOG_FILES[@]} -eq 0 ]]; then
        echo "📋 No logs to monitor"
        return
    fi

    # Create log files if they don't exist
    for log in "${LOG_FILES[@]}"; do
        touch "$log"
    done

    if command -v multitail &> /dev/null; then
        echo "🔍 Starting multitail log monitor..."
        echo "💡 Press 'q' to exit log viewer"

        sleep 2

        local args=()
        for log in "${LOG_FILES[@]}"; do
            args+=("-n" "50" "$log")
        done

        multitail "${args[@]}"
    else
        echo "🔍 Monitor logs manually with:"
        for log in "${LOG_FILES[@]}"; do
            echo "   tail -f $log"
        done
    fi
}

# Display service status
show_status() {
    echo -e "\n📊 Development Environment Status"
    echo "=================================="
    echo "🌐 API Server: http://localhost:$API_PORT"
    echo "🌐 SCAEM App: http://localhost:$SCAEM_PORT"
    echo "🌐 Vite Dev: Check $VITE_LOG for port (usually :5173)"
    echo "🗄️  XAMPP: Started via custom script"
    echo -e "\n💡 Press Ctrl+C to stop all services"
}

# =============================================================================
# Main Execution
# =============================================================================

main() {
    echo "🎬 Starting Development Environment"
    echo "==================================="

    # Set up cleanup trap
    trap cleanup SIGINT EXIT

    # Start Laravel API
    start_service \
        "Laravel API" \
        "php artisan serve --port=$API_PORT" \
        "$API_LOG" \
        "$API_DIR"

    # Start SCAEM Laravel app
    start_service \
        "SCAEM Laravel" \
        "php artisan serve --port=$SCAEM_PORT" \
        "$SCAEM_LOG" \
        "$SCAEM_DIR"

    # Start SCAEM Vite
    start_service \
        "SCAEM Vite" \
        "pnpm dev" \
        "$VITE_LOG" \
        "$SCAEM_DIR"

    # Start XAMPP
    echo -e "\n🚀 Starting XAMPP..."
    if [[ -x "$START_DEV_SCRIPT" ]]; then
        "$START_DEV_SCRIPT"
        echo "✅ XAMPP script executed"
    else
        echo "❌ XAMPP script not found or not executable: $START_DEV_SCRIPT"
    fi

    show_status
    monitor_logs

    # Keep script alive
    if [[ ${#BACKGROUND_PIDS[@]} -gt 0 ]]; then
        echo -e "\n⏳ Waiting for services..."
        wait -n "${BACKGROUND_PIDS[@]}"
    fi
}

# Run the script
main "$@"
