#!/bin/bash

set -e

usage() {
	echo "
Usage: $(basename "$0") [-h] [-m dir] [-b nbr] [-d dist] [-a arch] [-c commit_id]
 -- Generate debian package from fog_sw module.
Params:
    -h  Show help text.
    -m  Module directory to generate deb package from (MANDATORY).
    -b  Build number. This will be tha last digit of version string (x.x.N).
    -d  Distribution string in debian changelog.
    -a  Target architecture the module is built for. e.g. amd64, arm64.
    -r  ROS2 node packaging.
    -c  Commit id of the git repository HEAD
    -s  Subdirectory to be packaging
    -g  Git version string
"
	exit 0
}

check_arg() {
	if [ "$(echo $1 | cut -c1)" = "-" ]; then
		return 1
	else
		return 0
	fi
}

error_arg() {
	echo "$0: option requires an argument -- $1"
	usage
}

mod_dir=""
build_nbr=0
distr=""
arch=""
version=""
ros=0
git_commit_hash=""
git_version_string=""
packaging_subdir=""

while getopts "hm:b:d:a:rc:g:s:" opt
do
	case $opt in
		h)
			usage
			;;
		m)
			check_arg $OPTARG && mod_dir=$OPTARG || error_arg $opt
			;;
		b)
			check_arg $OPTARG && build_nbr=$OPTARG || error_arg $opt
			;;
		d)
			check_arg $OPTARG && distr=$OPTARG || error_arg $opt
			;;
		a)
			check_arg $OPTARG && arch=$OPTARG || error_arg $opt
			;;
		r)
			ros=1
			;;
		c)
			check_arg $OPTARG && git_commit_hash=$OPTARG || error_arg $opt
			;;
		g)
			check_arg $OPTARG && git_version_string=$OPTARG || error_arg $opt
			;;
		s)
			check_arg $OPTARG && packaging_subdir=$OPTARG || error_arg $opt
			;;
		\?)
			usage
			;;
	esac
done

if [ "$mod_dir" = "" ]; then
	echo "$0: Module directory is mandatory option!"
	usage
else
	## Remove trailing '/' mark in module dir, if exists
	mod_dir=$(echo $mod_dir | sed 's/\/$//')
fi

if [ $ros = 1 ]; then
	:
else
	[ "$distr" = "" ] && distr="focal"
	[ "$arch" = "" ] && arch="amd64"
	version="1.0.0"
fi

## Debug prints
echo 
echo "mod_dir: $mod_dir"
echo "build_nbr: $build_nbr"
echo "distr: $distr"
echo "arch: $arch"
echo "ros: $ros"
echo "git_commit_hash: $git_commit_hash"
echo "git_version_string: $git_version_string"
echo "packaging_subdir: $packaging_subdir"

script_dir=$(realpath $(dirname "$0"))


echo "INFO: Use default packaging."
### Create version string
v=$(grep ./debian/changelog -e 'wpa (' | awk '{print $2}' | sed 's/.*(\(.*\))/\1/' | cut -d':' -f2 |head -1)
echo "version=${v}"
# grep ./debian/changelog -e 'wpa (' | awk '{print $2}' | sed 's/.*(\(.*\))/\1/' | cut -d':' -f2 |head -1	

version="${v}-${build_nbr}${git_version_string}"
sed -i "s/VERSION/${version}/" ./debian/control
cat ./debian/control
echo "version: ${version}"

### create changelog
pkg_name=$(grep -oP '(?<=Package: ).*' ./debian/control)
for package in ${pkg_name[@]}; do
  echo "package name: $package"
  # mkdir -p ./debian/${package}
cat << EOF > ./debian/changelog
wpa (${version}) unstable; urgency=high

  * commit: ${git_commit_hash}

 -- $(grep -oP '(?<=Maintainer: ).*' ./debian/control)  $(date +'%a, %d %b %Y %H:%M:%S %z')

EOF
	echo "changelog for package: ${package}:"
	cat ./debian/changelog
	# gzip ./debian/changelog

	### create debian package
	debfilename=${package}_${version}_${arch}.deb
	echo "${debfilename}"
done


	# fakeroot dpkg-deb --build ${build_dir} $mod_dir/../${debfilename}

pwd
ls -la
pushd /build
dpkg-buildpackage -rfakeroot -b
popd