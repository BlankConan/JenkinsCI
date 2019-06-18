#!/bin/sh
# 使用说明
# 1. 额外创建一个文件夹，专门用来打包
# 2. 将脚本和打包配置文件放在此文件夹
# 3. 脚本和工程目录放在同一级，

# 目录结构
#---用来打包的文件件-------------
#         |-----打包脚本
#         |-----导出配置的plist文件
#         |-----工程文件夹


read -p "请输入打包的类型 1.App Store 2.Adhoc 3.exit > " archiveType

if [[ $archiveType -eq 3 ]]; then
	exit 0
fi

if [[ $archiveType -gt 3 || $archiveType -lt 1 ]]; then
	echo "输入错误"
	exit 0
fi

# 工程路径(必须是绝对路径)
PROJECt_PATH=""
# 要打包的分支名
BRANCH_NAME="dev_0.4.5_assume"
# 工程名字
SCHEME_NAME="PegasusIPad"
# workspace name 
WORKSPACENAME="${SCHEME_NAME}.xcworkspace"
# 包类型 Release Debug
CONFIGURATION="Release"
# 导出包 需要的plist路径
EXPORTOPTIONSPLIST="$PROJECt_PATH/AdhocExportOptions.plist"
if [[ $archiveType -eq 1 ]]; then
	EXPORTOPTIONSPLIST="$/PROJECt_PATH/AppstoreExportOptions.plist"
fi
# 编译号
BUILD_ID="10"

# =============== 项目上传蒲公英相关 =============== #
PGY_UKey="******"
PGY_APIKey="******"
# =============== 项目上传蒲公英相关 =============== #

# =============== 签名相关内容 ===============
# 包名
bundle_identifier="******"
# 描述文件 uuid
provisioning_profile="******"
# 签名实体
code_sign_identity="*******"
# apple id
appleId="*********"
# apple id 对应的专用密码 如果two-factor用app专用密码
applePassword="*******"

# 打包时间
ARCHIVE_TIME=`(date "+%Y_%m_%d_%H_%M_%S")`

# 归档路径
ARCHIVE_PATH="$PROJECt_PATH/ArchivePakages/$ARCHIVE_TIME"
if [[ ! -d $ARCHIVE_PATH ]]; then
	mkdir -p $ARCHIVE_PATH
fi
# 打包文件
ARCHIVE_FILE_PATH="$ARCHIVE_PATH/$SCHEME_NAME.xcarchive"
# IPA文件
IPA_FILE_PATH="$ARCHIVE_PATH/$SCHEME_NAME.ipa"


# 进入工程目录
cd $PROJECt_PATH/$SCHEME_NAME
git checkout .

# 项目 Info.plist文件的路径
PROJECT_INFO_PLIST_PATH="$PROJECt_PATH/PegasusIPad/PegasusIPad/NewClasses/Main/Info.plist"
# 修改 buildNumber 
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion ${BUILD_NUMBER}" ${PROJECT_INFO_PLIST_PATH}
# 设置版本号
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString ${BUILD_VERSION}" ${PROJECT_INFO_PLIST_PATH}

# 当前分支名
CURRENT_BRANCH_NAME=`git symbolic-ref --short -q HEAD`

if [[ $BRANCH_NAME != $CURRENT_BRANCH_NAME ]]; then
	 git checkout $BRANCH_NAME
fi
git pull
pod install


if [[ $? != 0 ]]; then
	echo " ************** 项目安装失败 ************** "
	exit 1
fi


# =============== 打包和导出 ===============

archivieApp() {
	
	echo " ************** 清理工程 **************"

	/usr/bin/xcodebuild clean -workspace $WORKSPACENAME \
					 		  -scheme $SCHEME_NAME \
					 		  -configuration $CONFIGURATION

	echo " ************** 清理完成 ************** "


	echo " ************** 打包工程 ************** "

	/usr/bin/xcodebuild archive -workspace $WORKSPACENAME \
					   			-scheme $SCHEME_NAME \
					   			-archivePath ${ARCHIVE_FILE_PATH} \
					   			-allowProvisioningUpdates \
					   			-configuration $CONFIGURATION \
					   			CODE_SIGN_IDENTITY="$code_sign_identity" \
					   			PRODUCT_BUNDLE_IDENTIFIER="$bundle_identifier" \
					   			PROVISIONING_PROFILE_SPECIFIER="$provisioning_profile" \
					   			-quiet

	ls $ARCHIVE_PATH | grep "$schemeName.xcarchive"

	if [ $? != 0  ]; then
		echo "****** ************** *******"
		echo "****** Archive Failed *******"
	    echo "****** ************** *******"
		exit 2 
	fi

	echo "****** ************** *******"
	echo "****** Archive Success *******"
	echo "****** ************** *******"

	/usr/bin/xcodebuild -exportArchive \
						-archivePath $ARCHIVE_FILE_PATH \
						-exportPath $ARCHIVE_PATH \
						-exportOptionsPlist $EXPORTOPTIONSPLIST

	ls $ARCHIVE_PATH | grep "$schemeName.ipa"

	if [ $? != 0  ]; then
		echo "****** ************** *******"
		echo "****** Export Failed *******"
	    echo "****** ************** *******"
		exit 2 
	fi
}


# =============== 上传 =============
# 上传蒲公英
uploadToPGY() {
	echo "=========上传 IPA 到蒲公英========="

	MSG=`git log -1 --pretty=%B`

	curl -F "file=@$IPA_FILE_PATH" \
	 	 -F "uKey=$PGY_UKey" \
     	 -F "_api_key=$PGY_APIKey" \
     	 -F "updateDescription=${MSG}" \
     	 https://qiniu-storage.pgyer.com/apiv1/app/upload
}


# 上传App Store
uploadToAppStore() {

	altool='/Applications/Xcode.app/Contents/Applications/Application\ Loader.app/Contents/Frameworks/ITunesSoftwareService.framework/Versions/A/Support/altool'
	
	altool --validate-app -f $IPA_FILE_PATH -t ios -u $appleId -p $applePassword

	altool --upload-app -f $IPA_FILE_PATH -t ios -u $appleId -p $applePassword
}


# 主逻辑

archivieApp

if [[ $archiveType == 1 ]]; then
	uploadToAppStore
elif [[ $archiveType == 2 ]]; then
	uploadToPGY
fi

exit 0

