# 対象ディレクトリ配下のインデックスをelasticsearchに登録します
# 本スクリプトはShift-JISで保存すること（Get-ChildItemがShift-JISで動作かつUTF-8だと関数の引数が文字化けするため）

Param(
	[string] $paramElasticsearchUrl,
	[string] $paramImportFileDir,
	[string] $paramSchemaDeleteFlg = "0",
	[string] $paramSchemaCreateFlg = "1",
	[string] $paramMappingName = "file"
)

# 定数
$BULK_URL = "_bulk"

# 引数チェック
function checkParam() {
	if ([string]::IsNullOrEmpty($paramElasticsearchUrl) -Or [string]::IsNullOrEmpty($paramImportFileDir)) {
		Write-Error @"

使い方 : importindex.ps1 ElasticsearchのURL 対象ディレクトリ [スキーマ削除フラグ] [スキーマ生成フラグ] [マッピング名]
（例）importindex.ps1 http://localhost:9200/filesearch C:\Temp 0 1 file
初回実行時はスキーマ削除フラグを0にしてください。（削除対象がないためエラーが発生します）
"@
		Exit -1
	}
	if (!($paramElasticsearchUrl.StartsWith("http"))) {
		Write-Error "ElasticsearchのURLが不正です: $paramElasticsearchUrl"
		Exit -1
	}
	if (!(Test-Path $paramImportFileDir)) {
		Write-Error "対象ディレクトリが存在しません: $paramImportFileDir"
		Exit -1
	}
}

# URL末尾スラッシュ付取得
function getSuffixSlashUrl([string] $url) {
	if ($url.Substring($url.Length - 1) -ne "/") {
		return $url + "/"
	}
	return $url
}

# スキーマ削除
function deleteSchema() {
	if ($paramSchemaDeleteFlg -eq "1") {
		Write-Progress -Activity "Delete Elasticsearch Schema : $paramElasticsearchUrl"
		Invoke-RestMethod -Uri $paramElasticsearchUrl -Method DELETE -DisableKeepAlive | Out-Null
	}
}

# スキーマ作成
function createSchema() {
	if ($paramSchemaCreateFlg -eq "1") {
		$settingFile = $PSScriptRoot + "\..\..\..\schema\setting_kuromoji.json"
		$mappingFile = $PSScriptRoot + "\..\..\..\schema\mapping_filesearch.json"
		$settingUrl = $paramElasticsearchUrl + "?pretty"
		$mappingUrl = $paramElasticsearchUrl + "/_mapping/type?pretty"
		Write-Progress -Activity "Create Elasticsearch Index : setting_kuromoji.json"
		Invoke-RestMethod -Headers @{"Content-Type" = "application/json"} -Uri $settingUrl -Method PUT -DisableKeepAlive -InFile $settingFile | Out-Null
		Write-Progress -Activity "Create Elasticsearch Document : mapping_filesearch.json"
		Invoke-RestMethod -Headers @{"Content-Type" = "application/json"} -Uri $mappingUrl -Method PUT -DisableKeepAlive -InFile $mappingFile | Out-Null
	}
}

# ファイル数の取得
function getFileCount() {
	return (Get-ChildItem $paramImportFileDir | ? { ! $_.PSIsContainer } | Measure-Object).Count
}

# プログレス表示
function outputProgress([string] $fullName, [int] $allFileCnt, [int] $fileCnt) {
	$progress = $fileCnt / $allFileCnt * 100
	Write-Progress -Activity "Import Elasticsearch" -PercentComplete $progress -CurrentOperation "File: $fullName" -Status "Count: $fileCnt/$allFileCnt"
}

# バルクインサート
function bulkInsert() {
	$bulkUrl = (getSuffixSlashUrl $paramElasticsearchUrl) + (getSuffixSlashUrl $paramMappingName) + $BULK_URL
	$allFileCount = getFileCount
	$currentFileCount = 0

	# インデックスの登録
	# Get-ChildItemはディレクトリも含むのでファイルのみ対象
	Get-ChildItem $paramImportFileDir | Where-Object { ! $_.PSIsContainer } | %{
		$currentFileCount++
		outputProgress $_.Fullname $allFileCount $currentFileCount
		Write-Output "import $_"
		Invoke-RestMethod -Headers @{"Content-Type" = "application/json"} -Uri $bulkUrl -Method POST -TimeOutSec 30000 -DisableKeepAlive -InFile $_.Fullname | Out-Null
	}
}

#--------------------
# メイン処理
#--------------------
checkParam
deleteSchema
createSchema
bulkInsert
