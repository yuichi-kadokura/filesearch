rem 先に makeindex-sample.bat を実行して C:\Temp ディレクトリにjsonファイルを配置しておくこと
powershell -NoProfile -ExecutionPolicy Unrestricted .\importindex.ps1 http://localhost:9200/filesearch C:\Temp 0 1
pause
