log=$('cat /var/ossec/logs/ossec.log' | grep -P "ERR|WARN|CRIT")
if [[ -z "$log" ]]; then
    echo "No errors in ossec.log"
else
    echo "Errors in ossec.log:"
    echo "${log}"
    exit 1
fi