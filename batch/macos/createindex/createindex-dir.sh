#!/bin/bash

# 定数
MAX_LINES=5000
PREFIX="index"

# 引数
paramTargetPath=""
paramOutputPath=""

# 使い方
function usageExit() {
  echo "Usage: createindex-dir.sh -t targetDirectory -o outputDirectory"
  exit 1
}

# 引数チェック
function checkParam() {
  if [ -z "${paramTargetPath}" -o -z "${paramOutputPath}" ]; then
    usageExit
  fi

  if [ ! -d $paramTargetPath ]; then
    echo "Target directory not found. ${paramTargetPath}"
    exit 1
  fi

  if [ ! -d $paramOutputPath ]; then
    echo "Output directory not found. ${paramOutputPath}"
    exit 1
  fi
}

# ファイル拡張子取得
function getFileExt() {
  if [ -d "$1" ] ; then
    return
  fi
  if [[ ! "$1" =~ "." ]] ; then
    return
  fi
  file_name=`basename "$1"`
  echo "${file_name##*.}"
}

# ファイル区分取得
function getFileType() {
  if [ -d "$1" ] ; then
    echo "0"
  else
    echo "1"
  fi
}

# ファイルサイズ
function getFileSize() {
  if [ -d "$1" ] ; then
    echo ""
  else
    stat -f "%z" "$1"
  fi
}

# ディレクトリ取得
function getPath() {
  if [ "${paramOutputPath: -1}" = "/" ] ; then
    echo $paramOutputPath
  else
    echo "${paramOutputPath}/"
  fi
}

# JSON作成
function outputJson() {
    file_type=`getFileType "$1"`
    file_size=`getFileSize "$1"`
    last_modified=`date -r "$1" "+%Y-%m-%d %H:%M:%S"`
    dir_name=`dirname "$1"`
    file_name=`basename "$1"`
    file_ext=`getFileExt "$1"`
    echo '{"index":{}}'
    echo '{"file_name":"'${file_name}'","target_type":"1","file_size":"'${file_size}'","dir_name":"'${dir_name}'","file_type":"'${file_type}'","last_modified":"'${last_modified}'","file_ext":"'${file_ext}'"}'
}

# インデックス作成
function createIndex() {
  outputPath=`getPath`
  outputFiles="${outputPath}${PREFIX}*.json"
  fileCnt=`ls -1 ${outputFiles} 2>/dev/null | wc -l`
  outputFile=`printf "${outputPath}${PREFIX}%06d.json" $fileCnt`
  lineCnt=0
  # .と~で始まるファイルは除外
  while read FILE
  do
    lineCnt=`expr $lineCnt + 1`
    if [ $lineCnt -gt $MAX_LINES ] ; then
      echo "create ${outputFile}"
      lineCnt=1
      fileCnt=`expr $fileCnt + 1`
      outputFile=`printf "${outputPath}${PREFIX}%06d.json" $fileCnt`
    fi
    json=`outputJson "${FILE}"`
    echo "${json}" >> $outputFile
  done < <(find $paramTargetPath -not -name ".*" -not -name "~*")
  echo "create ${outputFile}"
}

#--------------------
# メイン処理
#--------------------
# 引数解析
while getopts t:o: OPT
do
  case $OPT in
    t) paramTargetPath=$OPTARG;;
    o) paramOutputPath=$OPTARG;;
    \?) usageExit;;
  esac
done
# 引数チェック
checkParam
# インデックス作成
createIndex
