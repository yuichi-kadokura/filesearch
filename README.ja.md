# filesearch

インデックスを元にファイルを検索するツール。ファイルサーバーなどに配置されたファイルでも高速に検索することができる。

*短縮URL: [https://git.io/vdAzm](https://git.io/vdAzm)*

*Read this in other languages: [English](README.md), [日本語](README.ja.md).*

## デモ

[https://d1xs18o98gt62y.cloudfront.net/](https://d1xs18o98gt62y.cloudfront.net/)
クライアントのサンプル。実際に検索することができる。（停止中）

### サンプルをローカルで動作させる（Windows）

[![サンプルの動かし方](http://img.youtube.com/vi/qOge6BYKGbA/0.jpg)](http://www.youtube.com/watch?v=qOge6BYKGbA)

1. C:\Temp ディレクトリを作成
2. batch\windows\createindex\createindex-sample.bat を実行
3. Elasticseach を起動
4. batch\windows\importindex\importindex-sample.bat を実行
5. front\index.html を開く
6. "Windows"を検索

### サンプルをローカルで動作させる（macos)

1. /var/tmp/filesearch ディレクトリを作成
2. batch/macos/createindex/createindex-sample.sh を実行
3. Elasticseach を起動
4. batch/macos/importindex/importindex-sample.sh を実行
5. front/index.html を開く
6. "html"を検索

## 詳細

サーバー（Elasticsearch）、バッチ（インデックス作成、インポート）、クライアント（HTML, Javascript, CSS）の構成となっている。
バッチで作成したインデックスを Elasticsearch にインポートしておき、ブラウザから直接 Elasticsearch のAPIを呼び出すことで検索結果を取得している。
クライアントの Javascript を改造していろいろな検索ができるようすることが可能。

### 前提条件

本アプリケーションに必要なソフトウエアは以下の通り。

##### 検索サーバー

* Elasticsearchを動作させるサーバー（Linux, MacOSX, Windows etc.）
* Elasticsearch（バージョン0.9以上）
* JVM（Elasticsearchに必要。バージョンはElasticsearchに依存）

| Elasticsearch | JVM |
|-|-|
|0.9.x|6 以上|
|1.x|7 以上|
|2.x|7 以上|
|5.x|8 以上|

* Elasticsearch Kuromoji プラグイン（日本語ファイル名に対応させるため）

検索サーバーは AWS Elasticsearch Service でも良い。

##### インデックス作成・インポート処理

* Windows 7 SP1 以降
* Power Shell 3.0 以降

##### クライアント

* 各種ブラウザ（IE, Chrome, Firefox, Safari など）

#### 必要なソフトウェアのインストール方法

* JVM
[https://java.com/ja/download/](https://java.com/ja/download/) からダウンロードしてインストールする。
環境変数 JAVA_HOME を設定すること。

* Elasticsearch
[https://www.elastic.co/jp/downloads/elasticsearch](https://www.elastic.co/jp/downloads/elasticsearch) からダウンロードして任意のディレクトリに解凍する。

## 展開

### クライアントのデプロイ方法

front\index.html の以下の部分を環境に合わせて修正する。
```html
	<script type="text/javascript">
		var elasticsearchUrl = "http://localhost:9200/filesearch/file/_search";
	</script>
```
front ディレクトリ配下をWebサーバーに配置する。

Javascript とElasticseaarch のドメインが異なることが原因でElasticseaarch へのリクエストができない場合、Elasticsearch の config/elasticsearch.yml に以下の設定を追記する。

```
http.cors.allow-origin: "*"
http.cors.enabled: true
```

### バッチの実行方法

ps1 ファイルを実行可能にするため以下を実行する。
（デフォルトで ps1 ファイルが実行不可となっている）

```
コマンドプロンプトを管理者で実行する。
以下のコマンドを実行する。
> powershell
> Set-ExecutionPolicy RemoteSigned
確認
> Get-ExecutionPolicy
「RemoteSigned」であること。
「Restricted」はNG。
```

#### インデックス作成バッチ

検索対象としたいディレクトリのインデックスファイルを作成する。
5000 レコード単位でファイルが出力される。
実行前に出力ディレクトリを作成しておくこと。

```ps1
> powershell
> cd batch\windows\createindex
> .\createindex.ps1 対象ディレクトリ 出力ディレクトリ
```

#### インポートバッチ

インデックス作成バッチで作成したファイルを Elasticsearch にインポートする。
対象ディレクトリ配下のファイル全てが対象となる。（サブディレクトリは除く）
初回実行時などスキーマが無いときはスキーマ削除フラグを 0、スキーマ生成フラグを 1 とすること。
スキーマが無い時にスキーマ削除フラグを 0 にしたり、スキーマがあるときにスキーマ削除フラグ 0 かつ スキーマ生成フラグ 1 にするとエラーが発生する。

```ps1
> powershell
> cd batch\windows\createindex
> .\importindex.ps1 ElasticsearchのURL 対象ディレクトリ [スキーマ削除フラグ] [スキーマ生成フラグ] [マッピング名]
```

Elasticsearch の bulk API でインポートしている。（Elasticsearch の仕様上、ファイルの直接インポートはできない）

## セキュリティ

Elasticsearch の API をクライアントかすようにするため、クライアントからは特定の API しか呼べないようにする等の対策が必要。（内部用であれば問題ないが、外部公開する際は特に注意）

## 拡張案

* [クライアント] ソート、表示件数指定
* [クライアント] ネットワークディレクトリのmacOSフォーマット（例：M:\ -> smb://111.222.333.444/）
* [クライアント] React.js, Backbone.js 等のフレームワーク利用
* [クライアント] npm でのパッケージ管理
* [クライアント] iOS, Android アプリ作成
* [クライアント] PC, スマートフォンの CSS 切り替え
* [クライアント] ファイル名、ディレクトリ名クリックで対象を開く
* [バッチ] ファイル内容をインデックス化し、全文検索を可能とする
* [バッチ] Subversion のインデックス作成機能
* [バッチ] インデックス作成の対象外指定
* [バッチ] 差分更新を可能にする

## 寄稿

プルリクエストを提出するプロセスの詳細については準備中です。

## 組み込み

* [jQuery](https://jquery.com/) - Javascript ライブラリ
* [simplePagination.js](http://flaviusmatis.github.io/simplePagination.js/) - jQueryプラグイン（ページネーション用）

## 著者

* 角倉 優一

## ライセンス

このプロジェクトはMITライセンスの下でライセンスされています - 詳細については、[LICENSE.md](LICENSE.md)ファイルを参照してください。
