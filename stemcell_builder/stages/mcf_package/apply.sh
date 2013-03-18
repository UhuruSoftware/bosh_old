#!/usr/bin/env bash
#
# Copyright (c) 2009-2012 VMware, Inc.

set -e

base_dir=$(readlink -nf $(dirname $0)/../..)
source ${base_dir}/lib/prelude_apply.bash

dest_dir=mcf/$build_time
archive_dir_name=micro
archive_dir=${dest_dir}/${archive_dir_name}
mkdir --parents ${archive_dir}

${image_vsphere_ovf_ovftool_path} \
    --extraConfig:displayname="Micro Cloud Foundry ${version}" \
    ${work}/vsphere/image.ovf \
    ${archive_dir}/micro

cp ${micro_src}/micro/README ${archive_dir}
cp ${micro_src}/micro/RELEASE_NOTES ${archive_dir}

echo "${version}" > ${archive_dir}/VERSION

cd ${dest_dir}
zip --recurse-paths micro-${version}.zip ${archive_dir_name}
