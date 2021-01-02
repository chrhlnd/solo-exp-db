param (
	[Parameter(Mandatory=$true)][string]$database,
	[Parameter(Mandatory=$true)][string]$pattern
)


$safePatternFName = ([char[]]$pattern | where { [IO.Path]::GetinvalidFileNameChars() -notcontains $_ }) -join ''

$OutputEncoding = [System.Console]::OutputEncoding = [System.Console]::InputEncoding = [System.Text.Encoding]::UTF8
$PSDefaultParameterValues['*:Encoding'] = 'utf8'

set-variable -Name dumpfile -Value "$($database).$safePatternFName.script.all.sql"

set-variable -Name util_home -Value ".\Tools"

set-variable -Name ST_REP -Value (Join-Path $util_home "streplace_win32_amd64.exe")

("") | Out-File -FilePath $dumpfile -Append

set-variable -Name dumpfile (resolve-path $dumpfile)
set-variable -Name ST_REP -Value (resolve-path $ST_REP)

if (test-path $dumpfile) {
	clear-content $dumpfile
}

"-- Mass db script " | Out-File -FilePath $dumpfile -Append

("Dumping to " + $dumpfile)

$pattern_tab = $($pattern + ".tab")
$pattern_part = $($pattern + ".part")
$pattern_sql = $($pattern + ".sql")
$pattern_views = $($pattern + ".views")

# ------------------ Config trunc
("Appending config TRUNC")
("-- Appending config TRUNC") | Out-File -FilePath $dumpfile -Append
"SET FOREIGN_KEY_CHECKS=0; " | Out-File -FilePath $dumpfile -Append
get-childitem .\Config -Filter $($pattern_tab) | foreach-object {
	& $ST_REP gram $util_home\mysql_data_trunc.gram $_.FullName | Out-File -FilePath $dumpfile -Append
}
"SET FOREIGN_KEY_CHECKS=1; " | Out-File -FilePath $dumpfile -Append
# ------------------ Config trunc

("Appending TABLES")
("-- Appending TABLES") | Out-File -FilePath $dumpfile -Append
# ------------------ Table scripting
get-childitem .\Struct -Filter $($pattern_tab) | foreach-object {
	& $ST_REP pfx "2:-- " gram $util_home\mysql.gram .\Struct\$_ | Out-File -FilePath $dumpfile -Append
}
get-childitem .\ -Filter $($pattern_views) | foreach-object {
	get-content $_.FullName | Out-File -FilePath $dumpfile -Append
}
# ------------------ Table scripting

("Appending PROCS")
("-- Appending PROCS") | Out-File -FilePath $dumpfile -Append
# ------------------ Proc copying
get-childitem .\Procs -Filter $($pattern_sql) | foreach-object {
	get-content $_.FullName | Out-File -FilePath $dumpfile -Append
}
# ------------------ Proc copying

("Appending CONFIG")
("-- Appending CONFIG") | Out-File -FilePath $dumpfile -Append
# ------------------ Config bootstrapping
"SET FOREIGN_KEY_CHECKS=0; " | Out-File -FilePath $dumpfile -Append
get-childitem .\Config -Filter $($pattern_tab) | foreach-object {
	& $ST_REP gram $util_home\mysql_data.gram $_.FullName | Out-File -FilePath $dumpfile -Append
}
get-childitem .\Config -Filter $($pattern_part) | foreach-object {
	& $ST_REP gram $util_home\mysql_data.gram $_.FullName | Out-File -FilePath $dumpfile -Append
}
"SET FOREIGN_KEY_CHECKS=1; " | Out-File -FilePath $dumpfile -Append
# ------------------ Config bootstrapping

(get-content $dumpfile).replace("?schema?", $database) | set-content $dumpfile



# for /r %%i in (*.tab) do ..\%streplace% gram ..\%util_home%mysql_data_trunc.gram %%i >> ..\%dumpfile%
# echo SET FOREIGN_KEY_CHECKS=1; >> ..\%dumpfile%
# cd ..

# cd Struct
# echo Appending struct
# for /r %%i in (*.tab) do ..\%streplace% pfx "2:-- " gram ..\%util_home%mysql.gram %%i >> ..\%dumpfile%
# for /r %%i in (*.views) do echo -- SELECT "Loading view %%~ni"; >> ..\%dumpfile% & type %%i >> ..\%dumpfile% & echo. >> ..\%dumpfile%
# cd ..
# cd Procs
# echo Appending procs
# for /r %%i in (*.sql) do echo -- SELECT "Loading Proc %%~ni"; >> ..\%dumpfile% & type %%i >> ..\%dumpfile% & echo. >> ..\%dumpfile%
# cd ..
# cd Config

# echo Appending config

# echo SET FOREIGN_KEY_CHECKS=0; >> ..\%dumpfile%
# for /r %%i in (*.tab) do ..\%streplace% gram ..\%util_home%mysql_data.gram %%i >> ..\%dumpfile%
# for /r %%i in (*.part) do ..\%streplace% gram ..\%util_home%mysql_data.gram %%i >> ..\%dumpfile%
# echo SET FOREIGN_KEY_CHECKS=1; >> ..\%dumpfile%
# cd ..


# echo Done