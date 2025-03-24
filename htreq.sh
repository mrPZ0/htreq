#!/bin/env bash 
#
PACKAGE_NAME="htreq"
str_delimiter="======================================"
command_func="get_help"

declare -A command_options=()
declare -a command_arguments=()

function get_help() {
    echo "use htreq.sh  <command> "
    echo " COMMAND "
    echo "-ls <движок> отображает запросы доступные для движка "
    echo "-test <движок> <стенд> <тест> запускает тест "
    echo "-init <> создает структуру папок конфигов "
    echo "-new <движок> <стенд> <тест> создает новый тест из шаблона "
    echo "-logs создает файл лога "
    echo "-debug [verbose] вывод отладки  "
}

function load_options() {
    if [[ "$1" != "" ]]; then
        local s=${1}
        local name=${s%%=*}
        local value=${s#*=}
        #echo " name = value"
        command_options["$name"]+="${value} "
    fi
}

function load_arguments() {
    if [[ "$1" != "" ]]; then
        command_arguments[${#command_arguments[*]}]=${1}
        
    fi
}

function parse_arguments() {
    #echo $@
    for i in "$@"; do
        #echo $i
        case $i in
            -h|--help)
                get_help
            ;;
            -ls|--list)
                command_func="list_request" 
            ;;
            -test|--test)
                command_func="test_run" 
            ;;
            -init|--init)
                command_func="init_run" 
            ;;
            -new|--new)
                command_func="new_run" 
            ;;
            -logs|--logs)
                command_func="logs_setup" 
            ;;
            -debug|--debug)
                command_func="debug_setup" 
            ;;

            --*=*)
                load_options ${i:2}
            ;;
            -*=*)
                load_options ${i:1}
            ;;
            *)
                load_arguments ${i}
            ;;
        esac
    done
}

function load_config() {
    # defaults
    source ./config/htreq.defaults
    # load ./htreq config
    source ./htreq.conf
    # load stand env
    source ./config/${engine}/${stand}/env
    # load request params
    requests_dir="./config/${engine}/request"
    source ${requests_dir}/${test}/param
    if [ -e "${requests_dir}/$test/${data_file}" ]; then
        #data=$(cat ${requests_dir}/$test/${data_file})
        full_data_file=$(realpath "${requests_dir}/$test/${data_file}")
    # echo $str_delimiter
    # echo $data
    # echo $str_delimiter
    fi
    test_description="${engine} ${stand} ${test}"
    if [ "$test_description" != "" ]; then
        echo "starting " $test_description
    else
        #echo $(basename -- "$test" )
        echo "starting $test"
    fi
}

function prepare_output() {
    req_date=$(date +%Y-%m-%d-%H-%M)
    out_dir="./data/${engine}/${stand}/${test}/${req_date}"
    # create output dir
    if [ ! -d ${out_dir} ]; then
        mkdir -p ${out_dir}
    fi

    if [ "${response_type}" != "" ]; then
        output_filename="${test}.${response_type}"
    else
        output_filename="${test}.txt"
    fi
}

function prepare_curl_params() {
    # request
    #curl --version
    curl_params="--request ${req_type} \
    -k \
    --cert ${cert} \
    --key ${key} \
    --url ${url}/${route} \
    --header '${request_header}' "

    #echo ${req_headers[*]}
    OLD_IFS="$IFS"
    IFS=","
    for req_header in ${req_headers[*]}; do
        if [[ "${req_header}" != "" ]]; then
            curl_params+="--header '${req_header}' "
        fi
    done
    IFS="$OLD_IFS"

    curl_params+=" -s \
    -v \
    --output ${out_dir}/${output_filename} "

    if [[ -e ${full_data_file} ]]; then
        #curl_params+=" --data ${data}"
        curl_params+=" --data-binary @$full_data_file "
    fi
    #
    echo $str_delimiter
    echo ${curl_binary} ${curl_params}
    echo $str_delimiter
}

function output_result() {
    response_status=$(grep "< HTTP/1.1" ${out_dir}/$response_flow_file)
    if [[ "$response_status" = "" ]]; then
        echo ERR
        exit 1
    fi
    if [[ ! "${response_status}" = "" ]]; then
        echo "${response_status}" | gawk ' { print $3} '
    fi

    # out  to console
    if [ "$response_type" = "json" ]; then
        cat ${out_dir}/${output_filename} | json_pp -t json
    elif [ "$response_type" = "txt" ]; then
        echo $str_delimiter
        cat ${out_dir}/${output_filename}
        echo $str_delimiter
    fi
    echo
    echo "output saved in ${out_dir}/${output_filename} "
}

function list_request(){
    path1="./config/${engine}/request"
_requests=$(ls $path1)


echo "|----------|---------------------| "
for _rq in ${_requests[*]}
do
#echo " ${_rq}  | " $(grep description $path1/${_rq}/param)
echo " ${_rq}  | " $(. $path1/${_rq}/param && echo $test_description )
done

}

function init_folder() {
echo ""    
}
function new_from_template() {
echo ""
}

function test_run()
{
engine=$1
stand=$2
test=$3
load_config
prepare_output
prepare_curl_params
#
(/bin/bash -c "${curl_binary} ${curl_params}  2>${out_dir}/$response_flow_file ")

output_result
}



parse_arguments $@

echo ${command_func} ${command_arguments[*]}
