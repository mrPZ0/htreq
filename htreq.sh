#!/bin/env bash
PACKAGE_NAME="htreq"
str_delimiter="====="
engine=$1
stand=$2
test=$3
# load default config
source ./config.env
# load stand env
source ./config/${engine}/${stand}/env
#load request param
requests_dir="./config/${engine}/request"
source ${requests_dir}/${test}/param
if [ -e ${requests_dir}/${test}/${data_file} ]; then
data=$(cat ${requests_dir}/${test}/${data_file})
full_data_file=$(realpath "${requests_dir}/${test}/${data_file}")
fi

if [ "${test_description}" = "" ]; then
test_description="${engine} ${stand} ${test}"
fi
echo "starting ${test_description}"

#create out dir
req_date=$(date +%Y-%m-%d-%H-%M)
out_dir="./data/${engine}/${stand}/${test}/${req_date}"
if [] ! -d ${out_dir} ]; then
mkdir -p ${out_dir}

fi


if [ "${response_type}" != "" ]; then
output_filename="${test}.${response_type}"
else
output_filename="${test}.txt"
fi

#request

curl_params="--request ${req_type} \
-k \
--cert ${cert} \
--key ${key} \
--url ${url}/${route} \
--header '${request_header}' \
-s \
-v \
--output ${outdir}/${output_filename}"

if [[ -e ${full_data_file} ]]; then
#curl_params+=" --data ${data}"
curl_params+=" --data-binary @full_data_file"
fi
# debug
echo ${curl_binary} ${curl_params}
#
${curl_binary} ${curl_params} 2>${out_dir}/${response_flow_file}
response_status=$(grep "< HTTP/1.1" ${out_dir}/${response_flow_file})
if [[ "${response_status}" = "" ]];  then
echo ERR
exit 1
fi
if [[ ! "${response_status}" = "" ]];  then
echo ${response_status}" | gawk '{print $3}'
fi


if [ "${response_type}" = "json" ]; then
cat ${out_dir}/${output_filename} | json_pp -t json
elif [ "${response_type}" = "txt" ]; then
cat ${out_dir}/${output_filename} 
fi

echo "Output saved to ${out_dir}/${output_filename}"