# MeetingMind AI — Wearable Integration Guide

This guide explains how to extend the Wearable Wellness module in MeetingMind AI to integrate with external hardware, APIs, and cloud services (Fitbit Web SDK/API, Oura Cloud API, Apple HealthKit iOS, and Google Health Connect).

---

## 1. Fitbit Integration

### Overview
Fitbit uses a Web API (OAuth 2.0) to fetch continuous biometrics. For production integrations, we utilize their Subscription API to receive near-real-time updates via Webhooks.

### Steps to Implement
1. **OAuth 2.0 Authentication Flow**:
   - Register an application on the [Fitbit Developer Portal](https://dev.fitbit.com/).
   - Implement authorization flow in the app using a plugin like `flutter_web_auth_2`.
   - Obtain and securely store the `AccessToken` and `RefreshToken`.
2. **REST API Queries**:
   - Query sleep profiles: `GET https://api.fitbit.com/1.2/user/[user-id]/sleep/date/[date].json`
   - Query heart rate: `GET https://api.fitbit.com/1/user/[user-id]/activities/heart/date/[date]/1d/1min.json`
3. **Webhooks Setup**:
   - Configure a webhook endpoint on your Flask backend.
   - Subscribe to user data updates using the Fitbit Subscription API.
   - When Fitbit notifies the server of a new sync, push the data to the mobile client using Firebase Cloud Messaging or WebSockets.

---

## 2. Oura Ring Integration

### Overview
Oura exposes a REST API (v2) providing metrics such as Sleep, Readiness, Activity, and Heart Rate.

### Steps to Implement
1. **Developer Token setup**:
   - Prompt the user to link their Oura account by generating a Personal Access Token or completing the OAuth 2.0 authentication flow.
2. **API Endpoint Integration**:
   - Fetch sleep data: `GET https://api.ouraring.com/v2/usercollection/sleep`
   - Fetch heart rate: `GET https://api.ouraring.com/v2/usercollection/heartrate`
   - Header requirement: `Authorization: Bearer <access_token>`
3. **Data Mapping**:
   - Parse the JSON responses into the `SensorReading` models inside `wearable_provider.dart` and save them to the Isar DB.

---

## 3. Apple HealthKit (iOS Fallback)

### Overview
To access biometrics on iOS devices (Apple Watch), use Apple HealthKit.

### Steps to Implement
1. **Package Setup**:
   - Use the `health` Flutter package (already included in dependencies).
2. **Info.plist Configurations**:
   Add descriptions for permissions:
   ```xml
   <key>NSHealthShareUsageDescription</key>
   <string>We share your biometric data to correlate meetings with cognitive stress.</string>
   <key>NSHealthUpdateUsageDescription</key>
   <string>We update health metadata logs securely.</string>
   ```
3. **Trigger SDK Request**:
   - Initialize permissions using:
     ```dart
     final types = [
       HealthDataType.STEPS,
       HealthDataType.SLEEP_IN_BED,
       HealthDataType.ACTIVE_ENERGY_BURNED,
       HealthDataType.HEART_RATE,
     ];
     bool granted = await Health().requestAuthorization(types);
     ```
   - Stream or query Apple Watch telemetry periodically from iOS local storage.

---

## 4. Google Health Connect (Android Fallback)

### Overview
Google Health Connect is already integrated as the fallback mechanism on Android when no BLE device is connected.

### Data Mapping Architecture
- **Steps**: Read through `HealthDataType.STEPS` -> maps to `SensorReading.steps`.
- **Sleep**: Read through `HealthDataType.SLEEP_SESSION` -> maps to `SensorReading.sleep`.
- **Calories**: Read through `HealthDataType.ACTIVE_ENERGY_BURNED` -> maps to `SensorReading.calories`.
- **Distance**: Read through `HealthDataType.DISTANCE_DELTA` -> maps to `SensorReading.distance`.
