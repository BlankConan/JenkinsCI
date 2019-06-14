#!/bin/sh
set -e

####################
#Project Setting  
####################
#project name
PROJECT_NAME=yourprojectname
#workspace name
PROJECT_WORKSPACE_NAME=yourworkspacename
#scheme name
PROJECT_SCHEME_NAME=yourschemename
#profile name
PROFILE_NAME="yourprofilename"
#project Path
PROJECT_PATH=$(pwd)
#build time
BUILD_TIME=$(date +%Y%m%d%H%M)
#project temp path
PROJECT_TEMP_PATH=${PROJECT_PATH}_TEMP
#archive path
ARCHIVE_PATH=${PROJECT_PATH}/build/release/${PROJECT_NAME}_r${BUILD_TIME}
#export path
EXPORT_PATH=${ARCHIVE_PATH}.ipa
#sdk version
SDK_VERSION=iphoneos

######################
#api url
######################
API_SERVER_URL='"http:\/\/api.xxxx.com"'

######################
#third-party key
######################

#thirdpartykey
THIRD_PARTY_KEY='"keyvalue"'

######################
#pgyer key
######################
#pgyer ukey
PGY_UKEY=yourpgyukey
#pgyer api key
PGY_API_KEY=yourpgyapikey

######################
#build
######################
#pod install
pod install --verbose --no-repo-update

#copy project to temp path
echo "copy project files to temp path."
cp -r -f ${PROJECT_PATH} ${PROJECT_TEMP_PATH}
cd ${PROJECT_TEMP_PATH}

#modify code
echo "config api server url."
sed -i "" "/^\/\//!s/.* APIServerUrl.*/NSString * const APIServerUrl= @${API_SERVER_URL};/" yourcodefilepath
echo "config third-party keys."

#rongcloud api key
sed -i "" "/^\/\//!s/.*THIRD_PARTY_KEY.*/#define THIRD_PARTY_KEY @${THIRD_PARTY_KEY}/g" yourcodefilepath

#clean project
echo "clean project."

#xcodebuild -workspace ${PROJECT_WORKSPACE_NAME}.xcworkspace -scheme ${PROJECT_SCHEME_NAME} clean
xctool -workspace ${PROJECT_WORKSPACE_NAME}.xcworkspace -scheme ${PROJECT_SCHEME_NAME} clean

#archive project
echo "archive project."
#xcodebuild -workspace ${PROJECT_WORKSPACE_NAME}.xcworkspace -scheme ${PROJECT_SCHEME_NAME} build archive -archivePath ${ARCHIVE_PATH}
xctool -workspace ${PROJECT_WORKSPACE_NAME}.xcworkspace -scheme ${PROJECT_SCHEME_NAME} build archive -archivePath ${ARCHIVE_PATH}

#delete project temp path
echo "delete project temp path."
cd ${PROJECT_PATH}
rm -r -f ${PROJECT_TEMP_PATH}

#export archive file to ipa
echo "export ipa file to export path."
xcodebuild -exportArchive -archivePath ${ARCHIVE_PATH}.xcarchive -exportPath ${EXPORT_PATH} -exportFormat ipa -exportProvisioningProfile ${PROFILE_NAME}

#upload to pgyer
echo "upload to pgyer."
curl -F "file=@${EXPORT_PATH}" -F "uKey=${PGY_UKEY}" -F "_api_key=${PGY_API_KEY}" http://www.pgyer.com/apiv1/app/upload
echo "upload finish."
