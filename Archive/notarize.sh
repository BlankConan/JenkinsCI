#!/bin/sh -x

# MacOS 10.15 对pkg和dmg镜像文件授权

dmgPath=$1

appleAcount="xxxxxxx"
appleSecrity="xxxxxxx"

xcrun altool --notarize-app --primary-bundle-id "摘要" -u "$appleAcount" -p "$appleSecrity" -f ${dmgPath} &> tmp

uuid=`cat tmp | grep -Eo '\w{8}-(\w{4}-){3}\w{12}$'`

while true; do
  #statements
  echo "checking for notarization"

  xcrun altool --notarization-info "$uuid" -u "$appleAcount" -p "$appleSecrity" &> tmp

  r=`cat tmp`
  t=`echo "$r" | grep "success"`
  if [[ "$t" != "" ]]; then
     #statements
     echo "notarization done!"
     xcrun stapler staple -v ${dmgPath}
     echo "stapler done!"
     break
  fi

  echo "not finish yet, sleep 2m then check again..."
  sleep 120

done

