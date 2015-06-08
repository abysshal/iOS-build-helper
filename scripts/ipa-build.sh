#!/bin/bash

#version=0.1

#--------------------------------------------
# 功能：build xcode project & package app as .ipa file
# 使用说明：
#		编译project
#			ipa-build <project directory> [-c <project configuration>] [-o <ipa output directory>] [-t <target name>] [-n] [-p <platform identifier>]
#		编译workspace
#			ipa-build  <workspace directory> -w -s <schemeName> [-c <project configuration>] [-n]
#
# 参数说明：-c NAME				工程的configuration,默认为Release。
#			-o PATH				生成的ipa文件输出的文件夹（必须为已存在的文件路径）默认为工程根路径下的”build/ipa-build“文件夹中
#			-t NAME				需要编译的target的名称
#			-w					编译workspace
#			-s NAME				对应workspace下需要编译的scheme
#			-n					编译前是否先clean工程
#			-p					平台标识符
#			-l					log to file



if [ $# -lt 1 ];then
	echo "Error! Should enter the root directory of xcode project after the ipa-build command."
	exit 2
fi

if [ ! -d $1 ];then
	echo "Error! The first param must be a directory."
	exit 2
fi

#工程绝对路径
cd $1
project_path=$(pwd)

#编译的configuration，默认为Release
build_config=Release

param_pattern=":p:nc:o:t:ws:l"
OPTIND=2
while getopts $param_pattern optname
  do
    case "$optname" in
	  "n")
		should_clean=y
        ;;
	  "l")
		log_to_file=y
		;;
      "p")
		tmp_optind=$OPTIND
		tmp_optname=$optname
		tmp_optarg=$OPTARG

		OPTIND=$OPTIND-1
		if getopts $param_pattern optname ;then
			echo  "Error argument value for option $tmp_optname"
			exit 2
		fi
		OPTIND=$tmp_optind

		platform_id=$tmp_optarg

        ;;
      "c")
		tmp_optind=$OPTIND
		tmp_optname=$optname
		tmp_optarg=$OPTARG
		OPTIND=$OPTIND-1
		if getopts $param_pattern optname ;then
			echo  "Error argument value for option $tmp_optname"
			exit 2
		fi
		OPTIND=$tmp_optind

		build_config=$tmp_optarg

        ;;
      "o")
		tmp_optind=$OPTIND
		tmp_optname=$optname
		tmp_optarg=$OPTARG

		OPTIND=$OPTIND-1
		if getopts $param_pattern optname ;then
			echo  "Error argument value for option $tmp_optname"
			exit 2
		fi
		OPTIND=$tmp_optind


		cd $tmp_optarg
		output_path=$(pwd)
		cd ${project_path}

		if [ ! -d $output_path ];then
			echo "Error!The value of option o must be an exist directory."
			exit 2
		fi

        ;;
	  "w")
		workspace_name='*.xcworkspace'
		ls $project_path/$workspace_name &>/dev/null
		rtnValue=$?
		if [ $rtnValue = 0 ];then
			build_workspace=$(echo $(basename $project_path/$workspace_name))
		else
			echo  "Error!Current path is not a xcode workspace.Please check, or do not use -w option."
			exit 2
		fi

        ;;
	  "s")
		tmp_optind=$OPTIND
		tmp_optname=$optname
		tmp_optarg=$OPTARG

		OPTIND=$OPTIND-1
		if getopts $param_pattern optname ;then
			echo  "Error argument value for option $tmp_optname"
			exit 2
		fi
		OPTIND=$tmp_optind

		build_scheme=$tmp_optarg

        ;;
	  "t")
		tmp_optind=$OPTIND
		tmp_optname=$optname
		tmp_optarg=$OPTARG

		OPTIND=$OPTIND-1
		if getopts $param_pattern optname ;then
			echo  "Error argument value for option $tmp_optname"
			exit 2
		fi
		OPTIND=$tmp_optind

		build_target=$tmp_optarg

        ;;


      "?")
        echo "Error! Unknown option $OPTARG"
		exit 2
        ;;
      ":")
        echo "Error! No argument value for option $OPTARG"
		exit 2
        ;;
      *)
      # Should not occur
        echo "Error! Unknown error while processing options"
		exit 2
        ;;
    esac
  done


#build文件夹路径
build_path=${project_path}/build

if [ ! -d $LOGS_BUILD_DIR ]; then
	mkdir -p $LOGS_BUILD_DIR
fi


#生成的app文件目录
appdirname=Release-iphoneos
if [ $build_config = Debug ];then
	appdirname=Debug-iphoneos
fi
if [ $build_config = Distribute ];then
	appdirname=Distribute-iphoneos
fi
#编译后文件路径(仅当编译workspace时才会用到)
compiled_path=${build_path}/${appdirname}

#是否clean
if [ "$should_clean" = "y" ];then
	xcodebuild clean -configuration ${build_config}
fi

#组合编译命令
build_cmd='xcodebuild'

if [ "$build_workspace" != "" ];then
	#编译workspace
	if [ "$build_scheme" = "" ];then
		echo "Error! Must provide a scheme by -s option together when using -w option to compile a workspace."
		exit 2
	fi

	build_cmd=${build_cmd}' -workspace '${build_workspace}' -scheme '${build_scheme}' -configuration '${build_config}' CONFIGURATION_BUILD_DIR='${compiled_path}' ONLY_ACTIVE_ARCH=NO'

else
	#编译project
	build_cmd=${build_cmd}' -configuration '${build_config}

	if [ "$build_target" != "" ];then
		build_cmd=${build_cmd}' -target '${build_target}
	fi

fi

#编译工程
cd $project_path
if [ "$log_to_file" = "y" ];then
	$build_cmd >> ${LOGS_BUILD_DIR}/build.log 2>&1 || exit
else
	$build_cmd || exit
fi

echo "Build project done.."

#进入build路径
cd $build_path

#创建ipa-build文件夹
if [ -d ./ipa-build ];then
	rm -rf ipa-build
fi
mkdir ipa-build



#app文件名称
appname=$(basename ./${appdirname}/*.app)
#通过app文件名获得工程target名字
target_name=$(echo $appname | awk -F. '{print $1}')
#app文件中Info.plist文件路径
app_infoplist_path=${build_path}/${appdirname}/${appname}/Info.plist
#取版本号
bundleShortVersion=$(/usr/libexec/PlistBuddy -c "print CFBundleShortVersionString" ${app_infoplist_path})
#取build值
bundleVersion=$(/usr/libexec/PlistBuddy -c "print CFBundleVersion" ${app_infoplist_path})
#取displayName
displayName=$(/usr/libexec/PlistBuddy -c "print CFBundleDisplayName" ${app_infoplist_path})
bundleName=$(/usr/libexec/PlistBuddy -c "print CFBundleName" ${app_infoplist_path})
bundleIdentifier=$(/usr/libexec/PlistBuddy -c "print CFBundleIdentifier" ${app_infoplist_path})
#IPA名称
ipa_name="${bundleName}_${platform_id}_${bundleShortVersion}_${build_config}_${bundleVersion}_${displayName}_$(date +"%Y%m%d")"
echo $ipa_name.ipa

#xcrun打包
package_cmd='xcrun -sdk iphoneos PackageApplication -v ./'${appdirname}'/*.app -o '${IPA_BUILD_DIR}'/'${ipa_name}'.ipa'

if [ "$log_to_file" = "y" ];then
	$package_cmd >> ${LOGS_BUILD_DIR}/package.log 2>&1 || exit
else
	$package_cmd || exit
fi

echo "Package ipa done.."

if [ "$output_path" != "" ];then
	cp ${build_path}/ipa-build/${ipa_name}.ipa $output_path/${ipa_name}.ipa
	echo "Copy ipa file successfully to the path $output_path/${ipa_name}.ipa"
fi


##### Generate plist
PLIST_TEMPLATE=$PROJECT_HOME/scripts/template.plist

ipaFile=$IPA_BUILD_DIR/$ipa_name.ipa
plistFile=$IPA_BUILD_DIR/$ipa_name.plist
cp $PLIST_TEMPLATE $plistFile

$PLISTBUDDY -c "Set :items:0:metadata:title $ipa_name" $plistFile
$PLISTBUDDY -c "Set :items:0:metadata:bundle-version $bundleVersion" $plistFile
$PLISTBUDDY -c "Set :items:0:metadata:bundle-identifier $bundleIdentifier" $plistFile
$PLISTBUDDY -c "Save" $plistFile

echo "Generate plist done.."

##### Generate html

html_name=${bundleVersion}_${displayName}_${bundleName}_${build_config}.html
htmlFile=$IPA_BUILD_DIR/$html_name
HTML_TEMPLATE=$PROJECT_HOME/scripts/template.html
cp $HTML_TEMPLATE $htmlFile

sed -i "" "s#__TITLE__#${ipa_name}#g" $htmlFile

echo "Generate html done.."
