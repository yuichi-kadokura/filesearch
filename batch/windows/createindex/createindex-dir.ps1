# �f�B���N�g���̃C���f�b�N�X���쐬���܂��i���ʏ����j
# �{�X�N���v�g��Shift-JIS�ŕۑ����邱�ƁiGet-ChildItem��Shift-JIS�œ��삩��UTF-8���Ɗ֐��̈����������������邽�߁j

Param(
	[string] $paramTargetPath,
	[string] $paramOutputPath,
	[string] $paramReplaceOrg,
	[string] $paramReplaceDest
)

# �萔
$MAX_LINES = 5000
$PREFIX = "index"

# �����`�F�b�N
function checkParam() {
	if ([string]::IsNullOrEmpty($paramTargetPath) -Or [string]::IsNullOrEmpty($paramOutputPath)) {
		Write-Error "�g���� : createindex-dir.ps1 �Ώۃf�B���N�g�� �o�̓f�B���N�g�� [�u����������] [�u���敶����]"
		Exit -1
	}
	if (!(Test-Path $paramTargetPath)) {
		Write-Error "�Ώۃf�B���N�g�������݂��܂���: $paramTargetPath"
		Exit -1
	}
	if (!(Test-Path $paramOutputPath)) {
		Write-Error "�o�̓f�B���N�g�������݂��܂���: $paramOutputPath"
		Exit -1
	}
}

# �f�B���N�g�����擾
function getDirName([string] $path) {
	$dirName = $path.Substring(0, $path.LastIndexOf("\"))
	if ([string]::IsNullOrEmpty($paramReplaceOrg)) {
		return $dirName
	}
	return $dirName.Replace($paramReplaceOrg, $paramReplaceDest)
}

# �t�@�C���g���q�擾
function getFileExt([string] $file_name, $attributes) {
	if (($attributes -Band [IO.FileAttributes]::Directory) -Or (!$file_name.Contains("."))) {
		return ""
	}
	$start = $file_name.LastIndexOf(".") + 1
	return $file_name.Substring($start, $file_name.Length - $start)
}

# �t�@�C���敪�擾
function getFileType($attributes) {
	if ($attributes -Band [IO.FileAttributes]::Directory) {
		return "0"
	}
	return "1"
}

# ���t�t�H�[�}�b�g
function formatDate([DateTime] $datetime) {
#	return $datetime.ToString("yyyy-MM-ddTHH:mm:ss+09:00")
	return $datetime.ToString("yyyy-MM-dd HH:mm:ss")
}

# �t�@�C���T�C�Y�擾
function getFileSize([string] $file_size) {
	if ($file_size -eq "") {
		return ""
	}
	return $file_size
}

# JSON�o��
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

# �v���O���X�\��
function outputProgress([string] $fullName, [string] $outputFile, $fileCnt, $lineCnt) {
	$progress = $lineCnt / $MAX_LINES * 100
	Write-Progress -Activity "Output file: $outputFile" -PercentComplete $progress -CurrentOperation "File: $fullName" -Status "Count: $lineCnt"
}

# �f�B���N�g���擾
function getPath([string] $path) {
	if ($path.Substring($path.Length - 1) -ne "\") {
		return $path + "\"
	}
	return $path
}

# �C���f�b�N�X����
function createIndex() {
	$outputPath = getPath $paramOutputPath
	$outputFiles = $outputPath + $PREFIX + "*.json"
	$fileCnt = (Get-ChildItem $outputFiles).Count
	$lineCnt = 0
	# .��~�Ŏn�܂�t�@�C���͏��O
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
# ���C������
#--------------------
checkParam
createIndex
