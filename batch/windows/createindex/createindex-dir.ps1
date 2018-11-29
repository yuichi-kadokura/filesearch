# ディレクトリのインデックスを作成します（共通処理）
# 本スクリプトはShift-JISで保存すること（Get-ChildItemがShift-JISで動作かつUTF-8だと関数の引数が文字化けするため）

Param(
	[string] $paramTargetPath,
	[string] $paramOutputPath,
	[string] $paramReplaceOrg,
	[string] $paramReplaceDest
)

# 定数
$MAX_LINES = 5000
$PREFIX = "index"

# 引数チェック
function checkParam() {
	if ([string]::IsNullOrEmpty($paramTargetPath) -Or [string]::IsNullOrEmpty($paramOutputPath)) {
		Write-Error "使い方 : createindex-dir.ps1 対象ディレクトリ 出力ディレクトリ [置換元文字列] [置換先文字列]"
		Exit -1
	}
	if (!(Test-Path $paramTargetPath)) {
		Write-Error "対象ディレクトリが存在しません: $paramTargetPath"
		Exit -1
	}
	if (!(Test-Path $paramOutputPath)) {
		Write-Error "出力ディレクトリが存在しません: $paramOutputPath"
		Exit -1
	}
}

# ディレクトリ名取得
function getDirName([string] $path) {
	$dirName = $path.Substring(0, $path.LastIndexOf("\"))
	if ([string]::IsNullOrEmpty($paramReplaceOrg)) {
		return $dirName
	}
	return $dirName.Replace($paramReplaceOrg, $paramReplaceDest)
}

# ファイル拡張子取得
function getFileExt([string] $file_name, $attributes) {
	if (($attributes -Band [IO.FileAttributes]::Directory) -Or (!$file_name.Contains("."))) {
		return ""
	}
	$start = $file_name.LastIndexOf(".") + 1
	return $file_name.Substring($start, $file_name.Length - $start)
}

# ファイル区分取得
function getFileType($attributes) {
	if ($attributes -Band [IO.FileAttributes]::Directory) {
		return "0"
	}
	return "1"
}

# 日付フォーマット
function formatDate([DateTime] $datetime) {
#	return $datetime.ToString("yyyy-MM-ddTHH:mm:ss+09:00")
	return $datetime.ToString("yyyy-MM-dd HH:mm:ss")
}

# ファイルサイズ取得
function getFileSize([string] $file_size) {
	if ($file_size -eq "") {
		return ""
	}
	return $file_size
}

# JSON出力
function outputJson($obj) {
	@{ "index" = @{}; } | ConvertTo-Json -compress
	@{
		"target_type" = "1"; # 0:svn 1:samba
		"file_type" = getFileType $obj.Attributes; # 0:dir 1:file
		"dir_name" = getDirName $obj.FullName;
		"file_name" = $obj.Name;
		"file_ext" = getFileExt $obj.Name $obj.Attributes;
		"last_modified" = formatDate $obj.LastWriteTime;
		"file_size" = getFileSize $obj.Length;
	} | ConvertTo-Json -compress
}

# プログレス表示
function outputProgress([string] $fullName, [string] $outputFile, $fileCnt, $lineCnt) {
	$progress = $lineCnt / $MAX_LINES * 100
	Write-Progress -Activity "Output file: $outputFile" -PercentComplete $progress -CurrentOperation "File: $fullName" -Status "Count: $lineCnt"
}

# ディレクトリ取得
function getPath([string] $path) {
	if ($path.Substring($path.Length - 1) -ne "\") {
		return $path + "\"
	}
	return $path
}

# インデックス生成
function createIndex() {
	$outputPath = getPath $paramOutputPath
	$outputFiles = $outputPath + $PREFIX + "*.json"
	$fileCnt = (Get-ChildItem $outputFiles).Count
	$lineCnt = 0
	# .と~で始まるファイルは除外
	Get-ChildItem $paramTargetPath -Recurse -Exclude @(".*", "~*") | %{
		$lineCnt++
		if ($lineCnt -gt $MAX_LINES) {
			Write-Output "create $outputFile"
			$lineCnt = 1
			$fileCnt++
		}
		$outputFile = $outputPath + $PREFIX + "{0:000000}.json" -F $fileCnt
		outputProgress $_.FullName $outputFile $fileCnt $lineCnt
		$json = outputJson $_
		Out-File -InputObject $json -Filepath $outputFile -Append -Encoding UTF8
	}
	Write-Output "create $outputFile"
}

#--------------------
# メイン処理
#--------------------
checkParam
createIndex
