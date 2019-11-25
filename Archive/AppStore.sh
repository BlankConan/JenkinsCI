#!/bin/sh -x

cd ${WORKSPACE}

echo "********编译环境********${BUILD_ENV}"

pod install

# 工程名字
schemeName="TalentIPad"

# workspace name 
workspaceName="${schemeName}.xcworkspace"

# 构建的环境
configuration="AppStore"

# archivepath
archivepath="../archives"

# xcarchivepath
xcarchivepath="${archivepath}/${schemeName}.xcarchive"

# ipa path
ipapath="${archivepath}/${schemeName}.ipa"

# dSYM 包名
dSYM_NAME="${schemeName}.app.dSYM"

# dSYM 原始路径
dSYM_ORIGIN_PATH="$xcarchivepath/dSYMs/$dSYM_NAME"

# dSYM 上传文件的路径
UPLOAD_dSYM_PATH="$archivepath/dSYMs"

# 打包成zip的路径
dSYM_ZIP="$UPLOAD_dSYM_PATH/$dSYM_NAME.zip"

# 导出ipa需要的plist路径
exportOptionsPath="${schemeName}/Resource/ExportConfig/AppstoreExportOptions.plist"


# 项目的Info.plist配置文件
PROJECT_INFO_PLIST_PATH="${schemeName}/Resource/Info.plist"

# 包名
bundle_identifier="com.nipaiyi.socialApp"

# 描述文件名称
provisioning_profile="Nipaiyi iPad Distribution"


# 签名实体(
code_sign_identity="iPhone Distribution: xxxxxxxxxxx. (teamid)"

# apple id
appleId="*****@**.**"

# apple id 对应的专用密码(two fact 认证的账号需要)
applePassword=""

# bugyly app_id
BUYLY_APPID="1ed769bb88"
# bugly app_key
BUYLY_APPKEY="c9322473-d588-4cdf-b4ac-170a36427607"


# 删除上一次构建
ls .. | grep archives
if [ $? == 0 ]; then
	rm -rf ../archives/*
    echo "删除构建文件"
fi


# 修改 buildNumber 
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion ${BUILD_NUMBER}" ${PROJECT_INFO_PLIST_PATH}

# 设置版本号
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString ${BUILD_VERSION}" ${PROJECT_INFO_PLIST_PATH}


# 打包Archive
/usr/bin/xcodebuild archive -workspace $workspaceName \
					   		-scheme $schemeName \
					   		-archivePath ${xcarchivepath} \
					   		-allowProvisioningUpdates \
					   		-configuration ${configuration} \
					   		CODE_SIGN_IDENTITY="$code_sign_identity" \
					   		PRODUCT_BUNDLE_IDENTIFIER="$bundle_identifier" \
					   		PROVISIONING_PROFILE_SPECIFIER="$provisioning_profile" \
					   		-quiet
                            
ls $archivepath | grep "$schemeName.xcarchive"

if [ $? != 0  ]; then
	echo "****** ************** *******"
	echo "****** Archive Failed *******"
    echo "****** ************** *******"
	exit 2 
fi


# 打包
/usr/bin/xcodebuild -exportArchive \
					-archivePath $xcarchivepath \
					-exportPath $archivepath \
					-exportOptionsPlist $exportOptionsPath
                        

ls $archivepath | grep "$schemeName.ipa"

if [ $? != 0  ]; then
	echo "****** ************** *******"
	echo "****** Export Failed *******"
    echo "****** ************** *******"
	exit 2 
fi
	
xcrun altool --validate-app -f $ipapath -t "ios" -u $appleId -p $applePassword | grep 'Error'

if [ $? == 0 ]; then
	echo " ************************* "
	echo " ******* ipa验证失败 ****** "
    echo " ************************* "
    exit 1
fi

altool --upload-app -f $ipapath -t "ios" -u $appleId -p $applePassword


# bugly 描述文件上传
if [[ ! -d $UPLOAD_dSYM_PATH ]]; then
    mkdir -p $UPLOAD_dSYM_PATH
else 
	rm -rf ${UPLOAD_dSYM_PATH}/*
fi

# 复制 dSYM 文件
cp -a $dSYM_ORIGIN_PATH ${UPLOAD_dSYM_PATH}

# 打包成zip
cd ${UPLOAD_dSYM_PATH}
zip -r $dSYM_NAME.zip $dSYM_NAME

cd ${WORKSPACE}

# 是否有zip文件
ls ${UPLOAD_dSYM_PATH} | grep ${dSYM_NAME}.zip

if [$? != 0]; then
    echo " ************************* "
	echo " ******* dSYM打包失败 ****** "
    echo " ************************* "
    exit 2
else
	DSYM_OUT_PATH=~/Desktop/dSYMS/iPad/${BUILD_VERSION}/${BUILD_NUMBER}/
	mkdir -p ${DSYM_OUT_PATH}
    cp ${dSYM_ZIP} ${DSYM_OUT_PATH}
fi

# 退出
exit $?

# 上传符号表文件
curl -k "https://api.bugly.qq.com/openapi/file/upload/symbol?app_key=$BUYLY_APPKEY&app_id=$BUYLY_APPID" \
        --form "api_version=1" \
        --form "app_id=$BUYLY_APPID" \
        --form "app_key=$BUYLY_APPKEY"\
        --form "symbolType=2"  \
        --form "bundleId=$bundle_identifier" \
        --form "productVersion=$BUILD_VERSION" \
        --form "channel=$APP_CHANNEL" \
        --form "fileName=${dSYM_ZIP}" \
        --form "file=@${dSYM_ZIP}" \
        --verbose