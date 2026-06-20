# Development Startup & Launch Script for MeetingMind AI
# This script automates starting the emulator (cold boot, no state restore), waiting for boot completion, running/bringing the app to foreground.

$ANDROID_SDK = "C:\Users\soniy\AppData\Local\Android\Sdk"
$EMULATOR_EXE = "$ANDROID_SDK\emulator\emulator.exe"
$ADB_EXE = "$ANDROID_SDK\platform-tools\adb.exe"
$AVD_NAME = "Medium_Phone_API_36"
$PACKAGE_NAME = "com.meetingmind.ai.meetingmind_ai"

# 1. Start Emulator (Cold Boot, preventing restoration of previous app states)
Write-Host "🤖 Starting Android Emulator: $AVD_NAME with cold boot (-no-snapshot)..."
Start-Process -FilePath $EMULATOR_EXE -ArgumentList "-avd", $AVD_NAME, "-no-snapshot", "-gpu", "host"

# 2. Wait for boot completion
Write-Host "⏳ Waiting for ADB connection..."
& $ADB_EXE wait-for-device

Write-Host "⏳ Waiting for Android system boot to complete..."
while ($true) {
    $bootCompleted = & $ADB_EXE shell getprop sys.boot_completed
    if ($bootCompleted -eq "1") {
        Write-Host "✅ Android Emulator booted successfully!"
        break
    }
    Start-Sleep -Seconds 2
}

# Setup adb reverse port forwarding
Write-Host "🔗 Setting up port forwarding for Ollama and Emotion Backend..."
& $ADB_EXE reverse tcp:11434 tcp:11434
& $ADB_EXE reverse tcp:5000 tcp:5000

# Start Flask Backend automatically in the background
Write-Host "🐍 Starting Flask Emotion Analysis server in background..."
Start-Process -FilePath "python" -ArgumentList "lib/services/backend/app.py" -WindowStyle Hidden


# 3. Clean previous run state (optional force-stop and clear app data)
Write-Host "🧹 Stopping previous app instances and clearing local cache..."
& $ADB_EXE shell am force-stop $PACKAGE_NAME
& $ADB_EXE shell pm clear $PACKAGE_NAME

# 4. Compile and Run Application via Flutter
Write-Host "🚀 Launching MeetingMind AI on emulator..."
# Run flutter run. It will compile, install and launch the launcher activity automatically.
flutter run -d emulator-5554

# 5. Bring app to foreground (using Android Monkey tool or Activity Manager if needed)
Write-Host "📱 Bringing MeetingMind AI to the foreground..."
& $ADB_EXE shell monkey -p $PACKAGE_NAME -c android.intent.category.LAUNCHER 1
