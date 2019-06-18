#!/bin/sh

# 上传dysm.zip到bugly

APP_VERSION="1.0.0"
SCHEME_NAME="****"
dSYM_NAME="$SCHEME_NAME.app.dSYM"
dSYM_ORIGIN_PATH="/Users/liugangyi/.jenkins/jobs/TalentIPad_AppStore/archives/$SCHEME_NAME.xcarchive/dSYMs/$dSYM_NAME"
UPLOAD_dSYM_PATH="/Users/liugangyi/Desktop/appStoreDSYM"
dSYM_ZIP="$UPLOAD_dSYM_PATH/$dSYM_NAME.zip"

APP_BUNDLE_IDENTIFIER="com.xxxx.xxxx"
APP_CHANNEL="AppStore"
BUYLY_APPID="*****"
BUYLY_APPKEY="*****"



if [[ ! -d $UPLOAD_dSYM_PATH ]]; then
        mkdir -p $UPLOAD_dSYM_PATH
else 
        rm -rf ${UPLOAD_dSYM_PATH}/*
fi

# 复制 dSYM 文件
cp -a $dSYM_ORIGIN_PATH ${UPLOAD_dSYM_PATH}

# 打包成zip
zip -r "$dSYM_ZIP" ${UPLOAD_dSYM_PATH}/$dSYM_NAME

# 是否有zip文件
ls ${UPLOAD_dSYM_PATH} | grep ${dSYM_ZIP}
if [$? != 0]; then
        echo " ************************* "
	echo " ******* 打包zip失败 ****** "
        echo " ************************* "
        exit 1
fi

# 上传符号表文件
curl -k "https://api.bugly.qq.com/openapi/file/upload/symbol?app_key=$BUYLY_APPKEY&app_id=$BUYLY_APPID" \
        --form "api_version=1" \
        --form "app_id=$BUYLY_APPID" \
        --form "app_key=$BUYLY_APPKEY"\
        --form "symbolType=2"  \
        --form "bundleId=$APP_BUNDLE_IDENTIFIER" \
        --form "productVersion=$APP_VERSION" \
        --form "channel=$APP_CHANNEL" \
        --form "fileName=${dSYM_ZIP}" \
        --form "file=@${dSYM_ZIP}" \
        --verbose