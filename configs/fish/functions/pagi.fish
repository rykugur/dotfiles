function pagi --description "Filter process records by process-name regex"
    if test (count $argv) -ne 1
        echo "usage: pagi PROCESS_NAME_REGEX" >&2
        return 2
    end

    set -l pattern "$argv[1]"
    string match --quiet --regex -- "$pattern" '' >/dev/null 2>&1
    if test $status -eq 2
        echo "pagi requires a valid regular expression" >&2
        return 2
    end

    for line in (command ps -eo pid=,comm=,pcpu=,pmem=,args=)
        set -l fields (string match --regex --groups-only '^[[:space:]]*([^[:space:]]+)[[:space:]]+([^[:space:]]+)[[:space:]]+([^[:space:]]+)[[:space:]]+([^[:space:]]+)[[:space:]]+(.*)$' -- "$line")
        set -q fields[2]; or continue

        string match --quiet --regex -- "$pattern" "$fields[2]"; and echo "$line"
    end
end
