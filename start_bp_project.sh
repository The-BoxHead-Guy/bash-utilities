#!/bin/bash

# --- Configuration ---
PROJECTS_BASE_DIR="$HOME/projects" # Or your actual base projects directory

API_PROJECT_DIR="$PROJECTS_BASE_DIR/api.dataemergencia.com"
API_PORT=8000 # Laravel default is 8000, let's use 8001 for the first one
API_LOG_FILE="/tmp/laravel_api_dev.log"

SCAEM_PROJECT_DIR="$PROJECTS_BASE_DIR/test.scaem.app"
SCAEM_ARTISAN_PORT=8001 # Use 8002 for the second Laravel app
SCAEM_ARTISAN_LOG_FILE="/tmp/laravel_scaem_dev.log"
SCAEM_VITE_LOG_FILE="/tmp/vite_scaem_dev.log" # Vite usually runs on 5173 by default

START_DEV_ALIAS="/home/jhon-p/scripts/dev_start.sh" # This is the alias for the start-dev command in your shell
START_DEV_LOG_FILE="/tmp/start_dev_custom.log" # Optional: if you want to log start-dev output

# Array to store PIDs of background processes
BG_PIDS=()
LOG_FILES_TO_MONITOR=() # Store log file paths for monitoring

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

    # Note: The custom start-dev script might manage its own stop.
    # If $START_DEV_ALIAS starts multiple processes or has its own stop mechanism,
    # it's usually best to rely on that. This cleanup only targets PIDs directly launched
    # and backgrounded by *this* script.
    echo "XAMPP (started by '$START_DEV_ALIAS') might need to be stopped manually or via its own mechanism."
    echo "Cleanup complete."
}

# Trap SIGINT (Ctrl+C) and EXIT signals to run the cleanup function
trap cleanup SIGINT EXIT

echo "--- Starting Development Environment ---"
echo "Logs for background processes will be in /tmp/"
echo "Press Ctrl+C in *this* terminal (where this script was launched) to stop all started servers and exit."
echo ""

# 1. & 2. Start Laravel API server for api.dataemergencia.com
echo "--- Starting API: api.dataemergencia.com ---"
if [ -d "$API_PROJECT_DIR" ]; then
    echo "Navigating to $API_PROJECT_DIR"
    cd "$API_PROJECT_DIR" || { echo "Failed to cd to $API_PROJECT_DIR"; exit 1; }

    echo "Starting 'php artisan serve --port=$API_PORT' in the background..."
    echo "Log: $API_LOG_FILE"

    php artisan serve --port="$API_PORT" > "$API_LOG_FILE" 2>&1 &
    BG_PIDS+=($!)
    LOG_FILES_TO_MONITOR+=("$API_LOG_FILE")
    echo "API server started with PID ${BG_PIDS[-1]} on http://localhost:$API_PORT"
    cd - > /dev/null
else
    echo "WARNING: Directory $API_PROJECT_DIR not found. Skipping API server."
fi
echo ""
sleep 1

# 3. & 4. & 5. Start Laravel and Vite for test.scaem.app
echo "--- Starting App: test.scaem.app ---"
if [ -d "$SCAEM_PROJECT_DIR" ]; then
    echo "Navigating to $SCAEM_PROJECT_DIR"
    cd "$SCAEM_PROJECT_DIR" || { echo "Failed to cd to $SCAEM_PROJECT_DIR"; exit 1; }

    echo "Starting 'php artisan serve --port=$SCAEM_ARTISAN_PORT' in the background..."
    echo "Log: $SCAEM_ARTISAN_LOG_FILE"
    php artisan serve --port="$SCAEM_ARTISAN_PORT" > "$SCAEM_ARTISAN_LOG_FILE" 2>&1 &
    BG_PIDS+=($!)
    LOG_FILES_TO_MONITOR+=("$SCAEM_ARTISAN_LOG_FILE")
    echo "SCAEM Artisan server started with PID ${BG_PIDS[-1]} on http://localhost:$SCAEM_ARTISAN_PORT"
    sleep 1

    echo "Starting 'pnpm dev' for Vite in the background..."
    echo "Log: $SCAEM_VITE_LOG_FILE"
    pnpm dev > "$SCAEM_VITE_LOG_FILE" 2>&1 &
    BG_PIDS+=($!)
    LOG_FILES_TO_MONITOR+=("$SCAEM_VITE_LOG_FILE")
    echo "SCAEM Vite dev server started with PID ${BG_PIDS[-1]}. Check log for Vite port."
    cd - > /dev/null
else
    echo "WARNING: Directory $SCAEM_PROJECT_DIR not found. Skipping SCAEM app."
fi
echo ""
sleep 1

# 6. Start XAMPP development environment (via custom script)
echo "--- Starting XAMPP (via $START_DEV_ALIAS) ---"
if [ -x "$START_DEV_ALIAS" ]; then # Check if the script is executable
    echo "Running '$START_DEV_ALIAS'..."
    # If you want to monitor the log of START_DEV_ALIAS AND it's a single process
    # you can run it in the background and capture its PID.
    # Example:
    # "$START_DEV_ALIAS" > "$START_DEV_LOG_FILE" 2>&1 &
    # BG_PIDS+=($!)
    # LOG_FILES_TO_MONITOR+=("$START_DEV_LOG_FILE")
    # echo "'$START_DEV_ALIAS' started in background with PID ${BG_PIDS[-1]}. Log: $START_DEV_LOG_FILE"

    # Current behavior: Run it in the foreground as per your original script
    # If it's blocking, this script will wait here until it's done or backgrounded by itself.
    "$START_DEV_ALIAS"
    echo "'$START_DEV_ALIAS' command executed."
    # If START_DEV_ALIAS backgrounds itself and you know its log file, you can manually add it here:
    # if [ -f "/path/to/start_dev_actual.log" ]; then
    #   LOG_FILES_TO_MONITOR+=("/path/to/start_dev_actual.log")
    # fi
elif [ -f "$START_DEV_ALIAS" ]; then
    echo "WARNING: '$START_DEV_ALIAS' found but is not executable. Skipping. (Hint: chmod +x $START_DEV_ALIAS)"
else
    echo "WARNING: Script '$START_DEV_ALIAS' not found. Skipping XAMPP startup."
fi
echo ""

echo "--- All primary processes initiated ---"
echo "Laravel API (api.dataemergencia.com): http://localhost:$API_PORT"
echo "Laravel SCAEM (test.scaem.app): http://localhost:$SCAEM_ARTISAN_PORT"
echo "Vite for SCAEM: Check $SCAEM_VITE_LOG_FILE for port (usually http://localhost:5173)"
echo "XAMPP: Should be running via '$START_DEV_ALIAS'."
echo ""

# --- Real-time Log Monitoring ---
if [ ${#LOG_FILES_TO_MONITOR[@]} -gt 0 ]; then
    echo "--- Preparing real-time log monitoring ---"
    sleep 1 # Brief moment for log files to be created/appended

    # Check for multitail
    if command -v multitail &> /dev/null; then
        echo "Found 'multitail'. Launching it to monitor logs."
        echo "Press 'q' in the multitail window to close it. This script will then wait for Ctrl+C for full cleanup."
        multitail_args=()
        for log_file in "${LOG_FILES_TO_MONITOR[@]}"; do
            # Ensure file exists before adding, or multitail might complain immediately
            # Touch the file to create it if it doesn't exist, so multitail can watch it
            touch "$log_file"
            multitail_args+=("-n" "100" "$log_file") # -n 100 shows last 100 lines
        done
        multitail "${multitail_args[@]}"
        echo "Multitail closed. Script is now waiting for Ctrl+C to stop servers."
    else
        echo "Command 'multitail' not found. To view logs in real-time, open new terminal tabs/windows and run:"
        for log_file in "${LOG_FILES_TO_MONITOR[@]}"; do
            echo "  tail -f \"$log_file\""
        done
        echo ""
        echo "Script is now waiting. Press Ctrl+C in this terminal to stop servers and exit."
    fi
else
    echo "No specific log files configured for real-time monitoring by this script."
    echo "Script is now waiting. Press Ctrl+C in this terminal to stop servers and exit."
fi
echo ""

# Keep the script alive so Ctrl+C can be caught by the trap for all background processes.
if [ ${#BG_PIDS[@]} -gt 0 ]; then
    echo "Monitoring background PIDs: ${BG_PIDS[*]}"
    echo "Press Ctrl+C in *this* terminal to trigger cleanup and exit."
    wait -n "${BG_PIDS[@]}" # Wait for any of the background processes or a signal
else
    echo "No background server processes were started by this script to wait for."
    # If START_DEV_ALIAS was the only thing run and it's blocking and then exits, script exits.
    # If it was backgrounded by itself, this script might exit quickly if no other BG_PIDS.
    echo "If '$START_DEV_ALIAS' is still running in the background (managed by itself), this script will now exit."
    echo "You may need to stop '$START_DEV_ALIAS' processes manually if it doesn't self-terminate on parent script exit."
fi

# The trap will execute on exit.
