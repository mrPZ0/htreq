function check_response_ex() {
        response_status=$(grep "< HTTP/1.1" ${out_dir}/$response_flow_file)
    if [[ "$response_status" = "" ]]; then
        echo ERR
        exit 1
    fi
    if [[ ! "${response_status}" = "" ]]; then
        echo "${response_status}" | gawk ' { print $3} '
    fi

}
