#!/bin/bash
str_delimiter="======================================"
engine=$1
stand=$2
test=$3

# defaults 
PACKAGE_NAME="htreq"
curl_binary="curl"
data_file="data.json"
request_header="Content-Type: application/json"
response_flow_file="response.txt"
req_headers=()
# load ./htreq config
source ./config/htreq.conf
# load stand env
source ./config/${engine}/${stand}/env
# load request params
requests_dir="./config/${engine}/request"
source ${requests_dir}/${test}/param
if [  -e  "${requests_dir}/$test/${data_file}" ]; then
data=$(cat ${requests_dir}/$test/${data_file})
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

req_date=$(date +%Y-%m-%d-%H-%M)
out_dir="./data/${engine}/${stand}/${test}/${req_date}"
# create output dir
if [ ! -d  ${out_dir} ]; then
    mkdir -p  ${out_dir}
fi

if [ "${response_type}" != "" ]; then
output_filename="${test}.${response_type}"
else
output_filename="${test}.txt"
fi
# request
#curl --version
curl_params="--request ${req_type} \
-k \
--cert ${cert} \
--key ${key} \
--url ${url}/${route} \
--header '${request_header}' "
 
echo ${req_headers[*]}
OLD_IFS="$IFS"
IFS="," 
for req_header in ${req_headers[*]}
 do
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
# 
( /bin/bash -c "${curl_binary} ${curl_params}  2>${out_dir}/$response_flow_file " )

response_status=$(grep "< HTTP/1.1" ${out_dir}/$response_flow_file)
if [[ "$response_status" = "" ]]; then
echo ERR
exit 1
fi
if [[ ! "${response_status}" = "" ]];  then
echo ${response_status}" | gawk '{print $3}'
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
