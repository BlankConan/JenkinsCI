#!/bin/sh 

cd ${WORKSPACE}

echo "---------------------------------${WORKSPACE}"
echo "-----------BUILD_ENV-------------${BUILD_ENV}"
echo "-----------BUILD_BRANCH----------${BUILD_BRANCH}"

git checkout .

pod install

if [ $? != 0 ]; then
	echo "****** ****************** *******"
	echo "****** Pod Install Failed *******"
    echo "****** ****************** *******"
	exit $?
fi

# 工程名字
schemeName="TalentIPad"

# workspace name 
workspaceName="${schemeName}.xcworkspace"

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

# dSYM新路径
dSYM_PATH="$archivepath/$dSYM_NAME"

# 导出ipa需要的plist路径
exportOptionsPath="TalentIPad/Resource/ExportConfig/AdhocExportOptions.plist"


# 项目的Info.plist配置文件
PROJECT_INFO_PLIST_PATH="TalentIPad/Resource/InfoDebug.plist"


# 包名
bundle_identifier="BundleID"

# 描述文件 uuid
provisioning_profile="包名对应的描述文件"

# 签名实体
code_sign_identity="iPhone Distribution: xxxxxx. (TeamID)"


# 对应环境配置
if [ $BUILD_ENV == "Adhoc" ];then
	# 请求baseurl
	APP_BASE_URL='xxxx'
	# 测评课件的baseurl
	EVALUATION_BASE_URL='xxxx'
	# app显示的名字
	APP_DISPLAY_NAME='xx'
	# appstore环境 1_appstore
	APP_IS_AppSotre='xxx'
	# Beta环境是Debug下的
	APP_IS_BETA='xxx'
	# 配置文件路径
	xcconfigPath=`find ./ -iname Debug.xcconfig`
	# 配置文件名称
	xcconfigName='Debug'
	 
elif [ $BUILD_ENV == "AdhocOnline" ];then
	# 请求baseurl
	APP_BASE_URL='xxx'
	# 测评课件的baseurl
	EVALUATION_BASE_URL='xxxxxx'
	# app显示的名字
	APP_DISPLAY_NAME='xxxx'
	# appstore环境 1_appstore
	APP_IS_AppSotre='xxxxx'
	# Beta环境是Debug下的
	APP_IS_BETA='APP_IS_BETA=0'
	# 配置文件路径
	xcconfigPath=`find ./ -iname AdhocOnline.xcconfig`
	# 配置文件名称
	xcconfigName='AdhocOnline' 
	
else # 周四 beta环境（服务器线上，直播环境为beta）
	# 请求baseurl
	APP_BASE_URL='xxxxxx'
	# 测评课件的baseurl
	EVALUATION_BASE_URL='xxxxx'
	# app显示的名字
	APP_DISPLAY_NAME='xxxx'
	# appstore环境 1_appstore
	APP_IS_AppSotre='xxxxx'
	# Beta环境是Debug下的
	APP_IS_BETA='xxxx'
	# 配置文件路径
	xcconfigPath=`find ./ -iname Debug.xcconfig`
	# 配置文件名称
	xcconfigName='Debug' 
fi

# 进行config替换
sed -i '' "s/APP_BASE_URL.*/$APP_BASE_URL/" $xcconfigPath
sed -i '' "s/EVALUATION_BASE_URL.*/$EVALUATION_BASE_URL/" $xcconfigPath
sed -i '' "s/APP_DISPLAY_NAME.*/$APP_DISPLAY_NAME/" $xcconfigPath
sed -i '' "s/APP_IS_AppSotre.*/$APP_IS_AppSotre/" $xcconfigPath
sed -i '' "s/APP_IS_BETA.*/$APP_IS_BETA/" $xcconfigPath



# 修改 buildNumber 
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion ${BUILD_NUMBER}" ${PROJECT_INFO_PLIST_PATH}

/usr/bin/xcodebuild archive -workspace $workspaceName \
					   		-scheme $schemeName \
					   		-archivePath ${xcarchivepath} \
					   		-allowProvisioningUpdates \
					   		-configuration ${xcconfigName} \
					   		CODE_SIGN_IDENTITY="$code_sign_identity" \
					   		PRODUCT_BUNDLE_IDENTIFIER="$bundle_identifier" \
					   		PROVISIONING_PROFILE_SPECIFIER="$provisioning_profile" \
					   		-quiet
                            
ls $xcarchivepath

if [ $? != 0  ]; then
	echo "****** ************** *******"
	echo "****** Archive Failed *******"
    echo "****** ************** *******"
	exit 2 
fi

 
/usr/bin/xcodebuild -exportArchive \
					-archivePath $xcarchivepath \
					-exportPath $archivepath \
					-exportOptionsPlist $exportOptionsPath
                        

ls $ipapath

if [ $? != 0  ]; then
	echo "****** ************** *******"
	echo "****** Export Failed *******"
    echo "****** ************** *******"
	exit 2 
fi

# 更新信息为最新提交
LastModif=`git log -1 --pretty=%B`
MSG="${UPDATE_DES}--${BUILD_BRANCH}-----${BUILD_ENV}---${LastModif}"
curl -F "file=@${ipapath}" \
     -F "_api_key=xxxxxxxx" \
     -F "InstallBuildType=1" \
     -p "123456" \
     https://www.pgyer.com/apiv2/app/upload
     

# 删除上一次构建
ls .. | grep archives
if [ $? == 0 ]; then
	rm -rf ../archives/*
    echo "删除构建文件"
fi


# 复制 dSYM 文件
#cp -a $dSYM_ORIGIN_PATH ${archivepath}

# 打包zip
#zip -r "${dSYM_PATH}.zip" ${dSYM_PATH}

# 删除 dSYM 文件
#ls ${dSYM_PATH} | grep ${dSYM_NAME}
#if [$? = 0]; then
#	rm -rf ${dSYM_PATH}
#fi