@echo off
set "PYTHON=%~dp0..\venv\Scripts\python.exe"
if not exist "%PYTHON%" (
    echo fancy-shells: tools venv not found. Run install-fancy-shells.ps1 1>&2
    exit /b 1
)
"%PYTHON%" "%~dp0..\envcheck\envcheck.py" %*
