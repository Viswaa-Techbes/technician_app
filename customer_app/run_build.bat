@echo off
cd /d c:\Work\technician_app\customer_app
echo Starting build... > c:\Work\technician_app\customer_app\build_output.txt
call C:\Flutter\flutter\bin\flutter.bat --version >> c:\Work\technician_app\customer_app\build_output.txt 2>&1
echo Done. >> c:\Work\technician_app\customer_app\build_output.txt
