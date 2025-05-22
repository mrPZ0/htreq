#!/bin/bash 
#
PACKAGE_NAME="htreq"
str_delimiter="======================================"
command_func="get_help"
# load ./htreq config
source ./htreq.conf
declare -A command_options=()
declare -a command_arguments=()

function get_help() {
    help_message=(
    " "
     " Use  htreq.sh  <command> <arguments> [ options ] "
     " "
     " COMMAND "
     "-ls <движок> отображает запросы доступные для движка "
     "-req <движок> <стенд> <тест> запускает тест "
     "-init <> создает структуру папок конфигов "
     "-new <движок> <тест> создает новый тест из шаблона "
     " "
     " OPTIONS "
     "-logs=[file] создает файл лога "
     "-debug=[verbose] вывод отладки  "
     " "
    )
    printf '%s\n' "${help_message[@]}"
exit 0
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
                command_func="get_help"
            ;;
            -ls|--list)
                command_func="list_request" 
            ;;
            -req|--request)
                command_func="req_run" 
            ;;
            -init|--init)
                command_func="init_folder" 
            ;;
            -new|--new)
                command_func="new_from_template" 
            ;;
            -logs|--logs)
                load_options "logs=logs_setup" 
            ;;
            -debug|--debug)
                load_options "debug=debug_setup" 
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

    # load env defaults
    source ${config_base_dir}/htreq.defaults
    # load stand env
    source ${config_base_dir}/${engine}/${stand}/env
    # load request params
    requests_dir="${config_base_dir}/${engine}/request"
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
    out_dir="${output_base_dir}/${engine}/${stand}/${test}/${req_date}"
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

function check_response() {
        response_status=$(grep "< HTTP/1.1" ${out_dir}/$response_flow_file)
    if [[ "$response_status" = "" ]]; then
        echo ERR
        exit 1
    fi
    if [[ ! "${response_status}" = "" ]]; then
        echo "${response_status}" | gawk ' { print $3} '
    fi

}

function output_result() {

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
engine=$1
path1="${config_base_dir}/${engine}/request"
_requests=$(ls $path1)


echo "|----------|---------------------| "
for _rq in ${_requests[*]}
do
#echo " ${_rq}  | " $(grep description $path1/${_rq}/param)
echo "| ${_rq}  | " $(. $path1/${_rq}/param && echo $test_description )
done

}

function init_folder() {
echo "create htreq environments"
mkdir -p {$config_base_dir,$output_base_dir,$secret_base_dir}
cp -f ${template_dir}/htreq.conf ./htreq.conf
cp -f ${template_dir}/config/htreq.defaults $config_base_dir/htreq.defaults
}
function new_from_template() {
echo "create new request folder"
engine=$1
test=$2
mkdir -p $config_base_dir/${engine}/request/${test}
cp -rf ${template_dir}/config/request/get/. $config_base_dir/${engine}/request/${test}
}

function req_run()
{
    if  [ $# -lt 3 ]; then
    get_help
    fi
engine=$1
stand=$2
test=$3
load_config
prepare_output
prepare_curl_params
#
(/bin/bash -c "${curl_binary} ${curl_params}  2>${out_dir}/$response_flow_file ")
check_response
output_result
}



parse_arguments $@

 ${command_func} ${command_arguments[*]}
