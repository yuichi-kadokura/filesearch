#!/bin/bash

# 定数
BULK_URL="_bulk"
SCRIPT_ROOT=`cd \`dirname $0\`; pwd`

# 引数
paramElasticsearchUrl=""
paramImportFileDir=""
paramSchemaDeleteFlg="0"
paramSchemaCreateFlg="1"
paramMappingName="file"

# 使い方
function usageExit() {
  cat <<EOF
Usage:
    importindex.sh -e elasticsearchUrl -i importFileDir [-d schemaDeleteFlag] [-c schmaCreateFlag] [-m mappingName]
Options:
    -e  Elasticsearch url.
    -i  Import file directory.
    -d  Schema delete flag.
    -c  Schema create flag.
    -m  Mapping name.
Example:
    importindex.sh -e http://localhost:9200/filesearch -i /var/tmp -d 0 -c 1 -m file
    Set the schema delete flag to 0 at the first execution. (An error occurs because there is no deletion target)
EOF
exit -1
}

# 引数チェック
function checkParam() {
  if [ -z "${paramElasticsearchUrl}" -o -z "${paramImportFileDir}" ]; then
    usageExit
  fi

  if [ ${paramElasticsearchUrl: 0: 4} != "http" ]; then
    echo "Elasticsearch URL is invalid. ${paramElasticsearchUrl}"
  fi

  if [ ! -d $paramImportFileDir ]; then
    echo "Import file directory not found. ${paramImportFileDir}"
    exit 1
  fi

}

# URL末尾スラッシュ付取得
function getSuffixSlashUrl() {
  if [ "${1: -1}" = "/" ] ; then
    echo $1
  else
    echo "$1/"
  fi
}

# スキーマ削除
function deleteSchema() {
  if [ $paramSchemaDeleteFlg = "1" ]; then
    echo "Delete Elasticsearch Schema : ${paramElasticsearchUrl}"
    curl -X DELETE -o /dev/null -s ${paramElasticsearchUrl}
  fi
}

# スキーマ作成
function createSchema() {
  if [ $paramSchemaCreateFlg = "1" ]; then
    settingFile="${SCRIPT_ROOT}/../../../schema/setting_kuromoji.json"
    mappingFile="${SCRIPT_ROOT}/../../../schema/mapping_filesearch.json"
    settingUrl="${paramElasticsearchUrl}?pretty"
    mappingUrl="${paramElasticsearchUrl}/_mapping/type?pretty"
    echo "Create Elasticsearch Index : setting_kuromoji.json"
    curl -H "Content-Type: application/json" -X PUT -o /dev/null -s ${settingUrl} --data-binary @${settingFile}
    echo "Create Elasticsearch Document : mapping_filesearch.json"
    curl -H "Content-Type: application/json" -X PUT -o /dev/null -s ${mappingUrl} --data-binary @${mappingFile}
  fi
}

# バルクインサート
function bulkInsert() {
  bulkUrl="`getSuffixSlashUrl ${paramElasticsearchUrl}``getSuffixSlashUrl ${paramMappingName}`${BULK_URL}"

  # インデックスの登録
  # ファイルのみ対象（サブディレクトリは含まない）
  for FILE in `find ${paramImportFileDir} -maxdepth 1 -type f`; do
    echo "import ${FILE}"
    curl -H "Content-Type: application/json" -X POST -o /dev/null -s ${bulkUrl} --data-binary @${FILE}
  done
}

#--------------------
# メイン処理
#--------------------
# 引数解析
while getopts e:i:d:c:m: OPT
do
  case $OPT in
    e) paramElasticsearchUrl=$OPTARG;;
    i) paramImportFileDir=$OPTARG;;
    d) paramSchemaDeleteFlg=$OPTARG;;
    c) paramSchemaNoCreateFlg=$OPTARG;;
    m) paramMappingName=$OPTARG;;
    \?) usageExit;;
  esac
done
# 引数チェック
checkParam
# スキーマ削除
deleteSchema
# スキーマ作成
createSchema
# バルクインサート
bulkInsert
