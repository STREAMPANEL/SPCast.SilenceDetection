#!/bin/bash

# Function to run the script when silence is detected
run_script() {
    echo "Silence was detected. Running script..."
    # ./script.sh
    # In this case, Zabbix will take care of the rest for us <3
    touch /usr/share/zabbix/sp/secure/.restart_all_streamserver
    # Create another file to notify the user
    touch /usr/share/zabbix/sp/secure/.silence_detected
}

log_dir="/home/spcast/SPCast/silence/logs"
silence_log="$log_dir/silence_detection_$(date +%Y%m%d%H%M%S).log"
max_log_age=172800 # 48 hours in seconds

# Perform log rotation
rotate_logs() {
    # Find log files older than max_log_age and delete them
    find "$log_dir" -name "*.log" -type f -mmin +$((max_log_age / 60)) -delete
}

# Run FFmpeg for 15 seconds and analyze silence
silence_cmd="ffmpeg -nostdin -i http://localhost:8110/stream -af silencedetect=n=-50dB:d=15 -f mp3 -y /dev/null"
$silence_cmd >"$silence_log" 2>&1 &

# Sleep for 15 seconds
sleep 15

# Check if silence is detected
if grep -q "silence_start" "$silence_log"; then
    echo "Silence detected!"
    run_script
else
    echo "No silence detected."
fi

# Terminate the FFmpeg process
pkill -f "$silence_cmd"

# Perform log rotation
rotate_logs
