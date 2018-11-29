# ƒfƒBƒŒƒNƒgƒŠ‚ÌƒCƒ“ƒfƒbƒNƒX‚ğì¬‚µ‚Ü‚·i‹¤’Êˆ—j
# –{ƒXƒNƒŠƒvƒg‚ÍShift-JIS‚Å•Û‘¶‚·‚é‚±‚ÆiGet-ChildItem‚ªShift-JIS‚Å“®ì‚©‚ÂUTF-8‚¾‚ÆŠÖ”‚Ìˆø”‚ª•¶š‰»‚¯‚·‚é‚½‚ßj

Param(
	[string] $paramTargetPath,
	[string] $paramOutputPath
)

# ’è”
$MAX_LINES = 5000
$PREFIX = "index"

# ˆø”ƒ`ƒFƒbƒN
function checkParam() {
	if ([string]::IsNullOrEmpty($paramTargetPath) -Or [string]::IsNullOrEmpty($paramOutputPath)) {
		Write-Error "g‚¢•û : createindex-dir.ps1 ‘ÎÛƒfƒBƒŒƒNƒgƒŠ o—ÍƒfƒBƒŒƒNƒgƒŠ"
		Exit -1
	}
	if (!(Test-Path $paramTargetPath)) {
		Write-Error "‘ÎÛƒfƒBƒŒƒNƒgƒŠ‚ª‘¶İ‚µ‚Ü‚¹‚ñ: $paramTargetPath"
		Exit -1
	}
	if (!(Test-Path $paramOutputPath)) {
		Write-Error "o—ÍƒfƒBƒŒƒNƒgƒŠ‚ª‘¶İ‚µ‚Ü‚¹‚ñ: $paramOutputPath"
		Exit -1
	}
}


# ƒfƒBƒŒƒNƒgƒŠ–¼æ“¾
function getDirName([string] $path) {
	return $path.Substring(0, $path.LastIndexOf("\"))
}

# ƒtƒ@ƒCƒ‹Šg’£qæ“¾
function getFileExt([string] $file_name, $attributes) {
	if (($attributes -Band [IO.FileAttributes]::Directory) -Or (!$file_name.Contains("."))) {
		return ""
	}
	$start = $file_name.LastIndexOf(".") + 1
	return $file_name.Substring($start, $file_name.Length - $start)
}

# ƒtƒ@ƒCƒ‹‹æ•ªæ“¾
function getFileType($attributes) {
	if ($attributes -Band [IO.FileAttributes]::Directory) {
		return "0"
	}
	return "1"
}

# “ú•tƒtƒH[ƒ}ƒbƒg
function formatDate([DateTime] $datetime) {
#	return $datetime.ToString("yyyy-MM-ddTHH:mm:ss+09:00")
	return $datetime.ToString("yyyy-MM-dd HH:mm:ss")
}

# ƒtƒ@ƒCƒ‹ƒTƒCƒY
function getFileSize([string] $file_size) {
	if ($file_size -eq "") {
		return ""
	}
	return $file_size
}

# JSONo—Í
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

# ƒvƒƒOƒŒƒX•\¦
function outputProgress([string] $fullName, [string] $outputFile, $fileCnt, $lineCnt) {
	$progress = $lineCnt / $MAX_LINES * 100
	Write-Progress -Activity "Output file: $outputFile" -PercentComplete $progress -CurrentOperation "File: $fullName" -Status "Count: $lineCnt"
}

# ƒfƒBƒŒƒNƒgƒŠæ“¾
function getPath([string] $path) {
	if ($path.Substring($path.Length - 1) -ne "\") {
		return $path + "\"
	}
	return $path
}

# ƒCƒ“ƒfƒbƒNƒX¶¬
function createIndex() {
	$outputPath = getPath $paramOutputPath
	$outputFiles = $outputPath + $PREFIX + "*.json"
	$fileCnt = (Get-ChildItem $outputFiles).Count
	$lineCnt = 0
	# .ï¿½ï¿½~ï¿½Ånï¿½Ü‚ï¿½tï¿½@ï¿½Cï¿½ï¿½ï¿½Íï¿½ï¿½O
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
# ƒƒCƒ“ˆ—
#--------------------
checkParam
createIndex
