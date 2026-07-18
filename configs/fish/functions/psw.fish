function psw --description "Filter process records by field, operator, and value"
    test (count $argv) -eq 3; or begin
        echo "usage: psw FIELD OPERATOR VALUE" >&2
        return 2
    end

    set -l field (string lower -- "$argv[1]")
    set -l operator "$argv[2]"
    set -l expected "$argv[3]"
    set -l column

    switch $field
        case pid
            set column 1
        case name comm
            set column 2
        case cpu pcpu
            set column 3
        case mem pmem
            set column 4
        case command args
            set column 5
        case '*'
            echo "psw does not support field: $field" >&2
            return 2
    end

    switch $operator
        case = == '!=' '>' '>=' '<' '<=' '=~'
        case '*'
            echo "psw does not support operator: $operator" >&2
            return 2
    end

    if contains -- "$operator" '>' '>=' '<' '<='
        string match --quiet --regex '^-?[0-9]+([.][0-9]+)?$' -- "$expected"; or begin
            echo "psw requires a numeric value for $operator" >&2
            return 2
        end
    end

    for line in (command ps -eo pid=,comm=,pcpu=,pmem=,args=)
        set -l fields (string split --no-empty --max 4 ' ' (string trim -- "$line"))
        set -q fields[$column]; or continue
        set -l value "$fields[$column]"
        set -l matches 1

        switch $operator
            case = ==
                test "$value" = "$expected"; or set matches 0
            case '!='
                test "$value" != "$expected"; or set matches 0
            case '=~'
                string match --quiet --regex -- "$expected" "$value"; or set matches 0
            case '>' '>=' '<' '<='
                string match --quiet --regex '^-?[0-9]+([.][0-9]+)?$' -- "$value"; or set matches 0
                if test $matches -eq 1
                    command awk -v value="$value" -v expected="$expected" "BEGIN { exit !(value $operator expected) }"; or set matches 0
                end
        end

        if test $matches -eq 1
            echo "$line"
        end
    end
end
