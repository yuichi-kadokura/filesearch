# �Ώۃf�B���N�g���z���̃C���f�b�N�X��elasticsearch�ɓo�^���܂�
# �{�X�N���v�g��Shift-JIS�ŕۑ����邱�ƁiGet-ChildItem��Shift-JIS�œ��삩��UTF-8���Ɗ֐��̈����������������邽�߁j

Param(
	[string] $paramElasticsearchUrl,
	[string] $paramImportFileDir,
	[string] $paramSchemaDeleteFlg = "0",
	[string] $paramSchemaCreateFlg = "1",
	[string] $paramMappingName = "file"
)

# �萔
$BULK_URL = "_bulk"

# �����`�F�b�N
function checkParam() {
	if ([string]::IsNullOrEmpty($paramElasticsearchUrl) -Or [string]::IsNullOrEmpty($paramImportFileDir)) {
		Write-Error @"

�g���� : importindex.ps1 Elasticsearch��URL �Ώۃf�B���N�g�� [�X�L�[�}�폜�t���O] [�X�L�[�}�����t���O] [�}�b�s���O��]
�i��jimportindex.ps1 http://localhost:9200/filesearch C:\Temp 0 1 file
������s���̓X�L�[�}�폜�t���O��0�ɂ��Ă��������B�i�폜�Ώۂ��Ȃ����߃G���[���������܂��j
"@
		Exit -1
	}
	if (!($paramElasticsearchUrl.StartsWith("http"))) {
		Write-Error "Elasticsearch��URL���s���ł�: $paramElasticsearchUrl"
		Exit -1
	}
	if (!(Test-Path $paramImportFileDir)) {
		Write-Error "�Ώۃf�B���N�g�������݂��܂���: $paramImportFileDir"
		Exit -1
	}
}

# URL�����X���b�V���t�擾
function getSuffixSlashUrl([string] $url) {
	if ($url.Substring($url.Length - 1) -ne "/") {
		return $url + "/"
	}
	return $url
}

# �X�L�[�}�폜
function deleteSchema() {
	if ($paramSchemaDeleteFlg -eq "1") {
		Write-Progress -Activity "Delete Elasticsearch Schema : $paramElasticsearchUrl"
		Invoke-RestMethod -Uri $paramElasticsearchUrl -Method DELETE -DisableKeepAlive | Out-Null
	}
}

# �X�L�[�}�쐬
function createSchema() {
	if ($paramSchemaCreateFlg -eq "1") {
		$schemaFile = $PSScriptRoot + "\..\..\..\schema\" + "schema.json"
		Write-Progress -Activity "Create Elasticsearch Schema : schema.json"
		Invoke-RestMethod -Uri $paramElasticsearchUrl -Method POST -DisableKeepAlive -InFile $schemaFile | Out-Null
	}
}

# �t�@�C�����̎擾
function getFileCount() {
	return (Get-ChildItem $paramImportFileDir | ? { ! $_.PSIsContainer } | Measure-Object).Count
}

# �v���O���X�\��
function outputProgress([string] $fullName, [int] $allFileCnt, [int] $fileCnt) {
	$progress = $fileCnt / $allFileCnt * 100
	Write-Progress -Activity "Import Elasticsearch" -PercentComplete $progress -CurrentOperation "File: $fullName" -Status "Count: $fileCnt/$allFileCnt"
}

# �o���N�C���T�[�g
function bulkInsert() {
	$bulkUrl = (getSuffixSlashUrl $paramElasticsearchUrl) + (getSuffixSlashUrl $paramMappingName) + $BULK_URL
	$allFileCount = getFileCount
	$currentFileCount = 0

	# �C���f�b�N�X�̓o�^
	# Get-ChildItem�̓f�B���N�g�����܂ނ̂Ńt�@�C���̂ݑΏ�
	Get-ChildItem $paramImportFileDir | Where-Object { ! $_.PSIsContainer } | %{
		$currentFileCount++
		outputProgress $_.Fullname $allFileCount $currentFileCount
		Write-Output "import $_"
		Invoke-RestMethod -Uri $bulkUrl -Method POST -TimeOutSec 30000 -DisableKeepAlive -InFile $_.Fullname | Out-Null
	}
}

#--------------------
# ���C������
#--------------------
checkParam
deleteSchema
createSchema
bulkInsert
