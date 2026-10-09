# Minew S1 Beacon Scanner (100% Open Source Android App)

Полнофункциональное мобильное приложение под Android с полностью открытым исходным кодом (**без использования закрытых сторонних SDK**) для сканирования BLE маячков **Minew S1** (температура и влажность воздуха HT sensor), а также стандартных **iBeacon**.

---

## 🚀 Особенности и возможности

1. **100% Open Source & Zero Closed SDKs**:
   - Никаких проприетарных библиотек Minew или сторонних платных SDK.
   - Чистый нативный Android BLE стек (`android.bluetooth.le.*`), Jetpack Compose и Material 3.
2. **Поддержка Minew BeaconPlus / S1 (HT Sensor)**:
   - Декодирование пакетов телеметрии `Service Data` с UUID `0xFFE1` (`0000ffe1-0000-1000-8000-00805f9b34fb`).
   - Извлечение температуры (signed 8.8 fixed-point), относительной влажности (%) и заряда батареи (0–100%).
   - Извлечение аппаратного MAC-адреса из тела рекламного кадра Minew.
   - Извлечение имени устройства из Info-кадра (`0xA1 0x08`).
3. **Поддержка iBeacon (Apple Profile)**:
   - Декодирование Manufacturer Data (`0x004C`).
   - Отображение Proximity UUID, Major, Minor, TxPower (на расстоянии 1м) и расчет примерной дистанции в метрах.
4. **Агрегация по MAC-адресу**:
   - Поскольку Minew S1 шлет пакеты слотами (чередуя iBeacon и HT sensor), приложение склеивает данные от одного маячка по его MAC-адресу в единую карточку устройства.
5. **Удобный поиск и фильтрация**:
   - Поиск по MAC-адресу (например, `AC:23` или полный адрес) и имени.
   - Фильтры: *Все устройства*, *Только Minew S1*, *Только iBeacon*, *Избранные*.
   - Кнопка быстрого копирования MAC-адреса и UUID в буфер обмена.
6. **Детальный инспектор и телеметрия**:
   - Живые графики изменения температуры и влажности в реальном времени.
   - RAW инспектор пакетов: полный Hex-дамп рекламного пакета, дампы Service Data и Manufacturer Data.

---

## 🛠 Стек технологий

- **Язык**: Kotlin 1.9.24
- **UI Framework**: Jetpack Compose + Material 3
- **Сборка**: Gradle 8.8, Android Gradle Plugin 8.3.2
- **Минимальная версия Android**: Android 8.0 (API 26)
- **Целевая версия**: Android 14+ (API 34)

---

## 📂 Структура проекта

- [`app/src/main/java/com/openbeacon/minewscanner/data/parser/MinewPacketParser.kt`](file:///c:/Users/Claudwal/Documents/Projects/Android/Minew_Beacon_Scanner/app/src/main/java/com/openbeacon/minewscanner/data/parser/MinewPacketParser.kt) — парсер пакетов Minew BeaconPlus S1 (`0xA1 0x01` HT sensor, `0xA1 0x08` Info).
- [`app/src/main/java/com/openbeacon/minewscanner/data/parser/IBeaconParser.kt`](file:///c:/Users/Claudwal/Documents/Projects/Android/Minew_Beacon_Scanner/app/src/main/java/com/openbeacon/minewscanner/data/parser/IBeaconParser.kt) — парсер Apple iBeacon.
- [`app/src/main/java/com/openbeacon/minewscanner/data/ble/BleScannerManager.kt`](file:///c:/Users/Claudwal/Documents/Projects/Android/Minew_Beacon_Scanner/app/src/main/java/com/openbeacon/minewscanner/data/ble/BleScannerManager.kt) — управление BLE сканером и агрегацией пакетов.
- [`app/src/main/java/com/openbeacon/minewscanner/ui/screens/ScannerScreen.kt`](file:///c:/Users/Claudwal/Documents/Projects/Android/Minew_Beacon_Scanner/app/src/main/java/com/openbeacon/minewscanner/ui/screens/ScannerScreen.kt) — главный экран с поиском, фильтрами и списком.
- [`app/src/main/java/com/openbeacon/minewscanner/ui/components/BeaconCard.kt`](file:///c:/Users/Claudwal/Documents/Projects/Android/Minew_Beacon_Scanner/app/src/main/java/com/openbeacon/minewscanner/ui/components/BeaconCard.kt) — карточка маячка с датчиками и уровнем сигнала.
- [`app/src/main/java/com/openbeacon/minewscanner/ui/components/BeaconDetailDialog.kt`](file:///c:/Users/Claudwal/Documents/Projects/Android/Minew_Beacon_Scanner/app/src/main/java/com/openbeacon/minewscanner/ui/components/BeaconDetailDialog.kt) — детальный просмотр с графиками и RAW Hex дампом.
- [`app/src/test/java/com/openbeacon/minewscanner/PacketParserTest.kt`](file:///c:/Users/Claudwal/Documents/Projects/Android/Minew_Beacon_Scanner/app/src/test/java/com/openbeacon/minewscanner/PacketParserTest.kt) — автоматические тесты парсинга реальных hex-пакетов Minew S1 и iBeacon.

---

## 📦 Сборка и запуск

### 1. Запуск тестов:
```powershell
.\gradlew.bat testDebugUnitTest
```

### 2. Сборка APK:
```powershell
.\gradlew.bat assembleDebug
```
Собранный APK будет находиться в `app/build/outputs/apk/debug/app-debug.apk`.

### 3. Установка на подключенный телефон:
```powershell
adb install -r app/build/outputs/apk/debug/app-debug.apk
```
