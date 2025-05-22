#!/bin/bash

# --- Configuration ---
PROJECTS_BASE_DIR="$HOME/projects" # Or your actual base projects directory

API_PROJECT_DIR="$PROJECTS_BASE_DIR/api.dataemergencia.com"
API_PORT=8001 # Laravel default is 8000, let's use 8001 for the first one
API_LOG_FILE="/tmp/laravel_api_dev.log"

SCAEM_PROJECT_DIR="$PROJECTS_BASE_DIR/test.scaem.app"
SCAEM_ARTISAN_PORT=8002 # Use 8002 for the second Laravel app
SCAEM_ARTISAN_LOG_FILE="/tmp/laravel_scaem_dev.log"
SCAEM_VITE_LOG_FILE="/tmp/vite_scaem_dev.log" # Vite usually runs on 5173 by default

START_DEV_ALIAS="/home/jhon-p/scripts/dev_start.sh" # This is the alias for the start-dev command in your shell
# Array to store PIDs of background processes
BG_PIDS=()

# Function to clean up background processes on exit
cleanup() {
    echo ""
    echo "--- Stopping development servers ---"
    if [ ${#BG_PIDS[@]} -gt 0 ]; then
        echo "Attempting to kill PIDs: ${BG_PIDS[*]}"
        kill "${BG_PIDS[@]}" 2>/dev/null

        # Wait a moment for processes to terminate
        sleep 2

        # Check if they are still running (optional, more robust check)
        for pid_to_check in "${BG_PIDS[@]}"; do
            if ps -p "$pid_to_check" > /dev/null; then
                echo "PID $pid_to_check might still be running. Consider 'kill -9 $pid_to_check'."
            fi
        done
    else
        echo "No background PIDs to stop from this script."
    fi

    echo "XAMPP (started by 'start-dev') might need to be stopped manually or via its control panel if it doesn't have an auto-stop or a 'stop-dev' command."
    echo "Cleanup complete."
}

# Trap SIGINT (Ctrl+C) and EXIT signals to run the cleanup function
trap cleanup SIGINT EXIT

echo "--- Starting Development Environment ---"
echo "Logs for background processes will be in /tmp/"
echo "Press Ctrl+C to attempt to stop all started servers and exit."
echo ""

# 1. & 2. Start Laravel API server for api.dataemergencia.com
echo "--- Starting API: api.dataemergencia.com ---"
if [ -d "$API_PROJECT_DIR" ]; then
    echo "Navigating to $API_PROJECT_DIR"
    cd "$API_PROJECT_DIR" || { echo "Failed to cd to $API_PROJECT_DIR"; exit 1; }

    echo "Starting 'php artisan serve --port=$API_PORT' in the background..."
    echo "Log: $API_LOG_FILE"

    # Start the API server in the background
    php artisan serve --port="$API_PORT" > "$API_LOG_FILE" 2>&1 &

    BG_PIDS+=($!) # Save PID of the last backgrounded process
    echo "API server started with PID ${BG_PIDS[-1]} on http://localhost:$API_PORT"
    cd - > /dev/null # Go back to previous directory silently
else
    echo "WARNING: Directory $API_PROJECT_DIR not found. Skipping API server."
fi
echo ""
sleep 1 # Give it a moment

# 3. & 4. & 5. Start Laravel and Vite for test.scaem.app
echo "--- Starting App: test.scaem.app ---"
if [ -d "$SCAEM_PROJECT_DIR" ]; then
    echo "Navigating to $SCAEM_PROJECT_DIR"
    cd "$SCAEM_PROJECT_DIR" || { echo "Failed to cd to $SCAEM_PROJECT_DIR"; exit 1; }

    echo "Starting 'php artisan serve --port=$SCAEM_ARTISAN_PORT' in the background..."
    echo "Log: $SCAEM_ARTISAN_LOG_FILE"

    # Start the Artisan server in the background
    php artisan serve --port="$SCAEM_ARTISAN_PORT" > "$SCAEM_ARTISAN_LOG_FILE" 2>&1 &
    BG_PIDS+=($!)

    echo "SCAEM Artisan server started with PID ${BG_PIDS[-1]} on http://localhost:$SCAEM_ARTISAN_PORT"
    sleep 1

    echo "Starting 'pnpm dev' for Vite in the background..."
    echo "Log: $SCAEM_VITE_LOG_FILE"
    # If pnpm dev needs a specific port, you can add --port XXXX

    # Start the Vite server in the background
    pnpm dev > "$SCAEM_VITE_LOG_FILE" 2>&1 &
    BG_PIDS+=($!)

    echo "SCAEM Vite dev server started with PID ${BG_PIDS[-1]}. Check log for Vite port (usually http://localhost:5173)."
    cd - > /dev/null # Go back to previous directory silently
else
    echo "WARNING: Directory $SCAEM_PROJECT_DIR not found. Skipping SCAEM app."
fi
echo ""
sleep 1

# 6. Start XAMPP development environment (start-dev)
echo "--- Starting XAMPP (start-dev) ---"
if command -v $START_DEV_ALIAS &> /dev/null; then
    echo "Running '$START_DEV_ALIAS'..."
    # Running start-dev in the foreground. If it's blocking, this script will wait here.
    # If you want it in the background and rely on its own stop mechanism:
    # start-dev &
    # BG_PIDS+=($!) # Only if you want to try and kill it with the others, and if it's a single process
    $START_DEV_ALIAS
    echo "'start-dev' command executed."
else
    echo "WARNING: 'start-dev' command not found. Skipping XAMPP startup."
fi
echo ""

echo "--- All processes initiated ---"
echo "Laravel API (api.dataemergencia.com): http://localhost:$API_PORT (Log: $API_LOG_FILE)"
echo "Laravel SCAEM (test.scaem.app): http://localhost:$SCAEM_ARTISAN_PORT (Log: $SCAEM_ARTISAN_LOG_FILE)"
echo "Vite for SCAEM: Check $SCAEM_VITE_LOG_FILE for port (usually http://localhost:5173)"
echo "XAMPP: Should be running via 'start-dev'."
echo ""
echo "Script is now waiting. Press Ctrl+C to trigger cleanup and exit."
echo "If 'start-dev' is blocking, Ctrl+C might first go to it."

# Keep the script alive so Ctrl+C can be caught by the trap
# This is especially useful if 'start-dev' itself backgrounds and exits immediately.
# If 'start-dev' is blocking, this 'wait' will only be reached after 'start-dev' finishes.
# If all processes including 'start-dev' are backgrounded, 'wait' will keep the script
# alive until Ctrl+C is pressed, allowing the trap to run for all PIDs.
if [ ${#BG_PIDS[@]} -gt 0 ]; then
    wait "${BG_PIDS[0]}" # Wait for at least one of the background processes or Ctrl+C
else
    echo "No background server processes were started by this script to wait for."
    echo "If 'start-dev' was the only thing run and it exited, this script will now exit."
fi

# The trap will execute on exit, regardless of how 'wait' finishes.
