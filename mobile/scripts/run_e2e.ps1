<#
.SYNOPSIS
  Runs the Patrol auth E2E suite against the real backend + Firebase.

.DESCRIPTION
  Starts the local Firebase Admin helper (integration_test/tools/test_admin_helper.py),
  waits for it to become healthy, runs `patrol test`, then stops the helper.

  Prerequisites:
    - An Android emulator running (`flutter devices` shows it).
    - Patrol CLI installed:  dart pub global activate patrol_cli
    - Python deps installed:  pip install -r integration_test/tools/requirements.txt
    - firebase-service-account.json available (pass its path via -ServiceAccount).

.EXAMPLE
  ./scripts/run_e2e.ps1 -ServiceAccount ../backend/firebase-service-account.json `
      -Email e2e-test@yourdomain.com -Password 'SuperSecret123!'
#>
param(
    [Parameter(Mandatory = $true)]
    [string]$ServiceAccount,

    [string]$Email = 'e2e-test@example.com',
    [string]$Password = 'Test1234!',
    [string]$FullName = 'E2E Tester',
    [int]$HelperPort = 8765,
    [string]$Python = 'python',

    # Host address the *device* uses to reach the helper.
    # 127.0.0.1 works for both physical devices and emulators via the
    # adb reverse tunnel set up below (tcp:HelperPort → PC:HelperPort).
    # 10.0.2.2 is an emulator-only alias that breaks on physical hardware.
    [string]$HelperHost = '127.0.0.1',

    # adb/Flutter device id to target (optional; needed when >1 device attached).
    [string]$DeviceId = ''
)

$ErrorActionPreference = 'Stop'
$mobileDir = Split-Path -Parent $PSScriptRoot   # scripts/ -> mobile/
$helperScript = Join-Path $mobileDir 'integration_test/tools/test_admin_helper.py'

if (-not (Test-Path $ServiceAccount)) {
    throw "Service account file not found: $ServiceAccount"
}
$ServiceAccount = (Resolve-Path $ServiceAccount).Path

# ─── Early device connectivity check ─────────────────────────────────────────
# Fail fast before spending 2+ minutes building the APK, so the user sees a
# clear message rather than a cryptic "0 tests / Gradle failed" at the end.
$_earlyAdb = (Get-Command adb -ErrorAction SilentlyContinue).Source
if (-not $_earlyAdb) {
    $cands = @(
        "$env:USERPROFILE\AppData\Local\Android\Sdk\platform-tools\adb.exe",
        "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"
    )
    foreach ($c in $cands) { if (Test-Path $c) { $_earlyAdb = $c; break } }
}
if ($_earlyAdb) {
    $_adbArgs = if ($DeviceId) { @('-s', $DeviceId) } else { @() }
    $_state   = & $_earlyAdb @_adbArgs get-state 2>&1
    if ($_state -ne 'device') {
        $hint = if ($DeviceId) { "device $DeviceId" } else { 'any device' }
        throw "No ADB device ready (state: '$_state'). Reconnect $hint, enable USB debugging, and accept the RSA prompt, then retry."
    }
    Write-Host "Device ready (adb get-state: device)." -ForegroundColor Green
}

# How the device reaches the helper running on this host.
$helperUrl = "http://${HelperHost}:$HelperPort"
Write-Host "Helper URL for device: $helperUrl (via adb reverse tunnel)." -ForegroundColor Cyan

# ─── Firebase Auth Emulator ───────────────────────────────────────────────────
# Firebase Auth SDK v22+ hangs email/password sign-up when Play Integrity
# returns an empty reCAPTCHA token; the SDK waits for an interactive challenge
# that never resolves in automated tests. Route all auth traffic through a
# local Firebase Auth emulator instead.
$firebaseBin = "$env:APPDATA\npm\firebase.cmd"
if (-not (Test-Path $firebaseBin)) {
    throw 'firebase-tools not found. Run: npm install -g firebase-tools'
}
$emulatorProc = $null
$emulatorLog = Join-Path $env:TEMP 'e2e_emulator.txt'
$emulatorErr = Join-Path $env:TEMP 'e2e_emulator_err.txt'

# Reuse if a previous run left the emulator running (clean start still happens
# because the pre-flight delete-user wipes the emulator's in-memory user store).
$emulatorAlreadyUp = $false
$tcpCheck = New-Object System.Net.Sockets.TcpClient
try { $tcpCheck.Connect('127.0.0.1', 9099); $emulatorAlreadyUp = $true; $tcpCheck.Close() }
catch { } finally { $tcpCheck.Dispose() }

if ($emulatorAlreadyUp) {
    Write-Host 'Firebase Auth emulator already up on port 9099 — reusing.' -ForegroundColor Green
} else {
    Write-Host 'Starting Firebase Auth emulator on port 9099 ...' -ForegroundColor Cyan
    $emulatorProc = Start-Process -FilePath $firebaseBin `
        -ArgumentList @('emulators:start', '--only', 'auth', '--project', 'smart-receipt-warranty-manager') `
        -WorkingDirectory $mobileDir `
        -RedirectStandardOutput $emulatorLog `
        -RedirectStandardError $emulatorErr `
        -PassThru -NoNewWindow

    $emulatorReady = $false
    for ($i = 0; $i -lt 60; $i++) {
        Start-Sleep -Milliseconds 1000
        if ($emulatorProc.HasExited) {
            Write-Host 'Emulator stdout:' -ForegroundColor Yellow
            if (Test-Path $emulatorLog) { Get-Content $emulatorLog | Write-Host }
            Write-Host 'Emulator stderr:' -ForegroundColor Yellow
            if (Test-Path $emulatorErr) { Get-Content $emulatorErr | Write-Host }
            throw "Firebase Auth emulator exited early (code $($emulatorProc.ExitCode))."
        }
        $tcp = New-Object System.Net.Sockets.TcpClient
        try { $tcp.Connect('127.0.0.1', 9099); $emulatorReady = $true; $tcp.Close(); break }
        catch { } finally { $tcp.Dispose() }
    }
    if (-not $emulatorReady) { throw 'Firebase Auth emulator did not become ready in 60 seconds.' }
    Write-Host 'Firebase Auth emulator ready on port 9099.' -ForegroundColor Green
}

Write-Host "Starting Firebase Admin helper on port $HelperPort ..." -ForegroundColor Cyan
$env:FIREBASE_SERVICE_ACCOUNT = $ServiceAccount
$helper = Start-Process -FilePath $Python `
    -ArgumentList @($helperScript, '--port', "$HelperPort", '--auth-emulator-host', '127.0.0.1:9099') `
    -PassThru -NoNewWindow

try {
    # Wait for the helper to answer /health on localhost.
    $ready = $false
    for ($i = 0; $i -lt 30; $i++) {
        try {
            $resp = Invoke-WebRequest -Uri "http://127.0.0.1:$HelperPort/health" `
                -UseBasicParsing -TimeoutSec 2
            if ($resp.StatusCode -eq 200) { $ready = $true; break }
        } catch {
            Start-Sleep -Milliseconds 500
        }
    }
    if (-not $ready) { throw 'Firebase Admin helper failed to start.' }
    Write-Host 'Helper is healthy.' -ForegroundColor Green

    # Kill any stale flutter daemon processes left over from previous runs.
    # These orphans cause patrol to hang indefinitely waiting for IPC responses.
    Get-CimInstance Win32_Process -ErrorAction SilentlyContinue |
        Where-Object { $_.CommandLine -match 'flutter_tools\.snapshot\s+daemon' } |
        ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }

    # Keep the device screen on for the duration of the test run.
    # Without this the screen sleeps mid-test, Patrol can't interact with UI,
    # and the instrumentation runner times out with 0 tests recorded.
    $adbArgs = if ($DeviceId) { @('-s', $DeviceId) } else { @() }
    $adb = (Get-Command adb -ErrorAction SilentlyContinue).Source
    if (-not $adb) {
        $adb = Get-ChildItem "$env:USERPROFILE\Documents\Android\platform-tools",
                              "$env:LOCALAPPDATA\Android\Sdk\platform-tools" `
               -Filter 'adb.exe' -ErrorAction SilentlyContinue |
               Select-Object -First 1 -ExpandProperty FullName
    }
    if ($adb) {
        # Samsung devices can briefly reset their USB connection when system settings
        # are written via adb, which turns every subsequent adb command into a
        # NativeCommandError. With $ErrorActionPreference='Stop' that becomes
        # terminating, jumping to the finally block before the build even starts.
        # Run the entire device-setup block under SilentlyContinue so those transient
        # errors don't abort the script, then re-verify the device is still online.
        $ErrorActionPreference = 'SilentlyContinue'

        # Enable Do Not Disturb (zen_mode 2 = total silence) so incoming calls
        # cannot interrupt tests. zen_mode is restored in the outer finally block.
        # Without this, a single incoming call kills the Patrol gRPC handshake and
        # the run reports "0 tests" with a 35-second timeout.
        & $adb @adbArgs shell 'settings put global zen_mode 2' 2>$null
        # Brief pause — Samsung can take ~1 s to settle the USB after a settings write.
        Start-Sleep -Milliseconds 1500

        # Extend screen timeout to 10 minutes and enable stay-awake-while-USB.
        & $adb @adbArgs shell 'settings put system screen_off_timeout 600000' 2>$null
        & $adb @adbArgs shell 'svc power stayon usb' 2>$null
        # Wake the screen and swipe-dismiss the lock screen (swipe-only lock).
        & $adb @adbArgs shell 'input keyevent KEYCODE_WAKEUP' 2>$null
        Start-Sleep -Milliseconds 800
        & $adb @adbArgs shell 'wm dismiss-keyguard' 2>$null
        Start-Sleep -Milliseconds 500
        & $adb @adbArgs shell 'input swipe 540 2200 540 900 500' 2>$null
        Start-Sleep -Milliseconds 800

        $ErrorActionPreference = 'Stop'

        # Verify the device survived the setup commands.
        $_postState = & $adb @adbArgs get-state 2>&1
        if ($_postState -ne 'device') {
            throw "Device disconnected during setup (state: '$_postState'). Check the USB cable and retry."
        }
        Write-Host 'Do Not Disturb enabled. Screen wake-lock, stay-awake, and unlock attempted.' -ForegroundColor Cyan
        Write-Host 'If the device is still locked, unlock it manually now.' -ForegroundColor Yellow

        # Forward device port 8765 → PC port 8765 so the test running on the physical
        # device can reach the helper at http://127.0.0.1:8765 (its own loopback maps
        # to the PC via the reverse tunnel).  No-op on emulators (10.0.2.2 already works).
        & $adb @adbArgs reverse "tcp:$HelperPort" "tcp:$HelperPort" 2>$null
        Write-Host "adb reverse tcp:$HelperPort established." -ForegroundColor Cyan
        & $adb @adbArgs reverse 'tcp:9099' 'tcp:9099' 2>$null
        Write-Host 'adb reverse tcp:9099 established (Firebase Auth emulator).' -ForegroundColor Cyan
    } else {
        Write-Warning 'adb not found — screen may sleep during tests. Enable Stay Awake in Developer Options.'
    }

    # Swap in a gradlew.bat wrapper that silences the :app:dependencies task.
    # patrol calls `gradlew :app:dependencies` via a Dart subprocess whose pipe
    # Dart doesn't drain fast enough on Windows. The Flutter Gradle plugin emits
    # ~1700 bytes of println() warnings on EVERY build (bypassing logging.level=quiet),
    # which fills the 4 KB anonymous pipe buffer and deadlocks gradlew.
    # The wrapper intercepts the exact call pattern and redirects to NUL;
    # all other Gradle invocations (the actual APK build) run normally.
    $androidDir = Join-Path $mobileDir 'android'
    $gradlewBat  = Join-Path $androidDir 'gradlew.bat'
    $gradlewOrig = Join-Path $androidDir 'gradlew_orig.bat'
    Copy-Item $gradlewBat $gradlewOrig -Force
    Set-Content -Path $gradlewBat -Encoding ASCII -Value @'
@if "%DEBUG%" == "" @echo off
if "%OS%"=="Windows_NT" setlocal
set DEFAULT_JVM_OPTS=
set DIRNAME=%~dp0
if "%DIRNAME%" == "" set DIRNAME=.
set APP_BASE_NAME=%~n0
set APP_HOME=%DIRNAME%
if defined JAVA_HOME goto findJavaFromJavaHome
set JAVA_EXE=java.exe
%JAVA_EXE% -version >NUL 2>&1
if "%ERRORLEVEL%" == "0" goto init
echo ERROR: JAVA_HOME is not set and no 'java' command could be found in your PATH.
goto fail
:findJavaFromJavaHome
set JAVA_HOME=%JAVA_HOME:"=%
set JAVA_EXE=%JAVA_HOME%/bin/java.exe
if exist "%JAVA_EXE%" goto init
echo ERROR: JAVA_HOME is set to an invalid directory: %JAVA_HOME%
goto fail
:init
if not "%OS%" == "Windows_NT" goto win9xME_args
if "%@eval[2+2]" == "4" goto 4NT_args
:win9xME_args
set CMD_LINE_ARGS=
set _SKIP=2
:win9xME_args_slurp
if "x%~1" == "x" goto execute
set CMD_LINE_ARGS=%*
goto execute
:4NT_args
set CMD_LINE_ARGS=%$
:execute
set CLASSPATH=%APP_HOME%\gradle\wrapper\gradle-wrapper.jar
if "%1"==":app:dependencies" if "%2"=="" goto silent_exec
"%JAVA_EXE%" %DEFAULT_JVM_OPTS% %JAVA_OPTS% %GRADLE_OPTS% "-Dorg.gradle.appname=%APP_BASE_NAME%" -classpath "%CLASSPATH%" org.gradle.wrapper.GradleWrapperMain %CMD_LINE_ARGS%
goto end
:silent_exec
rem --no-daemon prevents the long-lived daemon from inheriting the caller's pipe
rem write handle. Without it, the launcher exits but the daemon keeps the handle
rem open, so patrol's Dart process.stdout never reaches EOF and hangs forever.
"%JAVA_EXE%" %DEFAULT_JVM_OPTS% %JAVA_OPTS% %GRADLE_OPTS% "-Dorg.gradle.appname=%APP_BASE_NAME%" -classpath "%CLASSPATH%" org.gradle.wrapper.GradleWrapperMain %CMD_LINE_ARGS% --no-daemon >NUL 2>&1
:end
if "%ERRORLEVEL%"=="0" goto mainEnd
:fail
if  not "" == "%GRADLE_EXIT_CONSOLE%" exit 1
exit /b 1
:mainEnd
if "%OS%"=="Windows_NT" endlocal
:omega
'@

    try {
        Write-Host 'Running patrol test ...' -ForegroundColor Cyan
        $patrolArgs = @(
            'test',
            '--verbose',  # Shows gRPC/IPC detail; helps diagnose "0 tests" timeouts.
            '--dart-define', "E2E_EMAIL=$Email",
            '--dart-define', "E2E_PASSWORD=$Password",
            '--dart-define', "E2E_FULL_NAME=$FullName",
            '--dart-define', "E2E_HELPER_URL=$helperUrl"
        )
        if ($DeviceId) { $patrolArgs += @('-d', $DeviceId) }

        # Capture broad logcat for debugging. Tags:
        #   flutter:V       — Dart/Flutter engine output
        #   AndroidRuntime:V — Java crash stack traces
        #   ActivityManager:W — activity lifecycle events
        #   *:W             — warnings/errors from every other tag (broader than *:E)
        $logFile = Join-Path $env:TEMP 'e2e_logcat.txt'
        $logProc = $null
        if ($adb) {
            & $adb @adbArgs logcat -c 2>$null
            $logProc = Start-Process -FilePath $adb `
                -ArgumentList (@($adbArgs) + @('logcat', '-s', 'flutter:V', 'AndroidRuntime:V', 'ActivityManager:W', '*:W')) `
                -RedirectStandardOutput $logFile -PassThru -NoNewWindow
            Write-Host "Logcat capture started -> $logFile" -ForegroundColor Cyan
        }

        # Resolve patrol CLI; Pub global bin may not be on PATH in all shells.
        $patrolExe = (Get-Command patrol -ErrorAction SilentlyContinue).Source
        if (-not $patrolExe) {
            $patrolExe = "$env:USERPROFILE\AppData\Local\Pub\Cache\bin\patrol.bat"
        }
        if (-not (Test-Path $patrolExe)) { throw "patrol CLI not found. Run: dart pub global activate patrol_cli" }

        Push-Location $mobileDir
        try {
            # patrol (and flutter tools it invokes) may write deprecation/version
            # warnings to stderr. PowerShell wraps native-exe stderr as
            # NativeCommandError, which with ErrorActionPreference=Stop becomes a
            # terminating exception before any test runs. Switch to Continue so
            # those warnings are displayed but don't abort the script; pass/fail
            # is determined by $LASTEXITCODE below, not by the error stream.
            $ErrorActionPreference = 'Continue'
            & $patrolExe @patrolArgs
            $exitCode = $LASTEXITCODE
        } finally {
            $ErrorActionPreference = 'Stop'
            Pop-Location
        }

        if ($logProc -and -not $logProc.HasExited) {
            Stop-Process -Id $logProc.Id -Force -ErrorAction SilentlyContinue
        }
        Write-Host "Logcat saved to: $logFile" -ForegroundColor Cyan

        if ($exitCode -ne 0) {
            Write-Host "patrol test failed (exit $exitCode)." -ForegroundColor Red
            exit $exitCode
        }
        Write-Host 'E2E suite passed.' -ForegroundColor Green
    } finally {
        # Always restore the original gradlew.bat.
        if (Test-Path $gradlewOrig) {
            Copy-Item $gradlewOrig $gradlewBat -Force
            Remove-Item $gradlewOrig -Force -ErrorAction SilentlyContinue
        }
    }
} finally {
    Write-Host 'Stopping Firebase Admin helper ...' -ForegroundColor Cyan
    if ($helper -and -not $helper.HasExited) {
        Stop-Process -Id $helper.Id -Force -ErrorAction SilentlyContinue
    }
    if ($emulatorProc -and -not $emulatorProc.HasExited) {
        # /T kills the full process tree (firebase.cmd → node.js children).
        taskkill /F /T /PID "$($emulatorProc.Id)" 2>&1 | Out-Null
        Write-Host 'Firebase Auth emulator stopped.' -ForegroundColor Cyan
    }
    # Restore Do Not Disturb to off (zen_mode=0). Silently ignore if device gone.
    if ($adb) {
        try { & $adb @adbArgs shell 'settings put global zen_mode 0' 2>$null } catch {}
        Write-Host 'Do Not Disturb restored to off.' -ForegroundColor Cyan
    }
    Remove-Item Env:\FIREBASE_SERVICE_ACCOUNT -ErrorAction SilentlyContinue
}
