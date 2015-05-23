for /f %%f in ('npm bin') do (@set JISON=%%f)
@SET JISON=%JISON%\jison
@%JISON% -m js src\SqlParser.jison -o web\js\parser\SqlParser.js
