#!/bin/bash

set -ve
# ------------------------------------------------------------------------------------------
# Builds the sample project from the command line.
#
# You must provide the path to the root Android SDK directory by doing one of the following:
# 1) Provide the path as a comman line argument. For example:  build.sh <MyAndroidSdkPath>
# 2) Set the path to an environment variable named "ANDROID_SDK".
# ------------------------------------------------------------------------------------------

PATH="$PATH:/usr/local/bin"

#
# Checks exit value for error
# 
checkError() {
    if [ $? -ne 0 ]
    then
        echo "Exiting due to errors (above)"
        exit -1
    fi
}

script=`basename $0`
path=`dirname $0`

# 
# Canonicalize relative paths to absolute paths
# 
pushd $path > /dev/null
dir=`pwd`
path=$dir
popd > /dev/null

# Fetch the Android SDK path from the first command line argument.
# If not provided from the command line, then attempt to fetch it from environment variable ANDROID_SDK.
SDK_PATH=
if [ ! -z "$1" ]
then
	SDK_PATH=$1
else
	SDK_PATH=$ANDROID_SDK
fi

if [ -z "$CORONA_ENTERPRISE_DIR" ]
then
	CORONA_ENTERPRISE_DIR=/Applications/CoronaEnterprise
fi

if [ ! -z "$2" ]
then
	CORONA_PATH=$2
else
	CORONA_PATH=$CORONA_ENTERPRISE_DIR
fi

RELATIVE_PATH_TOOL=$CORONA_PATH/Corona/mac/bin/relativePath.sh

CORONA_PATH=`"$RELATIVE_PATH_TOOL" "$path" "$CORONA_PATH"`
echo CORONA_PATH: $CORONA_PATH

if [ -f ../version.ver ]; then
    version=$(cat ../version.ver)
else
    version="1.0"
fi
echo "Version:" $version
d1=$(date +%s)
#25.05.2015 16:00 MSK
build=$(expr $d1 / 60 - 23875980)
echo "Build:" $build

sed -E -i .bak "s/android:versionName=\"[0-9]+\.[0-9]+\"/android:versionName=\"$version.$build\"/g" AndroidManifest.xml

# Do not continue if we do not have the path to the Android SDK.
if [ -z "$SDK_PATH" ]
then

	echo ""
	echo "USAGE:  $script"
	echo "USAGE:  $script android_sdk_path"
	echo "\tandroid_sdk_path: Path to the root Android SDK directory."
	echo "\tcorona_enterprise_path: Path to the CoronaEnterprise directory."
	exit -1
fi


# Before we can do a build, we must update all Android project directories to use the given Android SDK.
# We do this by running the "android" command line tool. This will add a "local.properties" file to all
# project directories that is required by the Ant build system to compile these projects for Android.
"$SDK_PATH/tools/android" update project -p . -t android-19
checkError

"$SDK_PATH/tools/android" update lib-project -p "$CORONA_PATH/Corona/android/lib/Corona"
checkError

# Uncomment if using facebook
# "$SDK_PATH/tools/android" update lib-project -p "$CORONA_PATH/Corona/android/lib/facebook/facebook"
# checkError


echo "Using Corona Enterprise Dir: $CORONA_PATH"

# Build the Test project via the Ant build system.
ant clean release -D"CoronaEnterpriseDir"="$CORONA_PATH"
checkError

[ -f ./VungleCoronaTest.apk ] && rm ./VungleCoronaTest.apk
cp ./bin/VungleCoronaTest-release.apk ./VungleCoronaTest.apk
puck -api_token=d6cb4cec883a44a5a39a0ed21a845ff3 -app_id=3887b118a4ab23e2b88b7a0be99087a3 -submit=auto -download=true -notify=false -open=nothing VungleCoronaTest.apk