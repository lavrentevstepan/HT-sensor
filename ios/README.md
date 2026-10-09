# Minew S1 Beacon Scanner — iOS (Swift & SwiftUI)

Версия мобильного приложения под **iOS** с полностью открытым исходным кодом (**100% Open Source**, без использования закрытых сторонних SDK) для поиска и считывания датчиков температуры и влажности маячков **Minew S1**, а также пакетов **iBeacon**.

---

## 💡 Особенности и специфика платформы iOS

1. **Извлечение реального MAC-адреса на iOS**:
   - В iOS стек `CoreBluetooth` намеренно скрывает аппаратный MAC-адрес периферийных устройств в целях приватности (`peripheral.identifier` возвращает сгенерированный системой UUID).
   - **Решение**: Протокол Minew S1 передает реальный аппаратный MAC-адрес устройства непосредственно внутри кадра телеметрии HT sensor (в байтах 7..12 пакета `Service Data 0xFFE1`).
   - Наш парсер [`MinewPacketParser.swift`](file:///c:/Users/Claudwal/Documents/Projects/Android/Minew_Beacon_Scanner/ios/MinewBeaconScanner/Parsers/MinewPacketParser.swift) извлекает настоящий физический MAC-адрес маячка из тела пакета, сопоставляет его с устройством и отображает в интерфейсе.
2. **Нулевая зависимость от закрытых SDK**:
   - Написано исключительно на стандартных фреймворках Apple: `CoreBluetooth`, `Foundation`, `SwiftUI`, `Combine`.
3. **Современный UI в едином стиле**:
   - Темная тема, неоновые индикаторы, датчики температуры, влажности, уровня батареи, уровня сигнала RSSI.
   - Живые графики изменения температуры и влажности в реальном времени.
   - RAW Hex инспектор пакетов с быстрым копированием в буфер обмена.
   - Поиск по MAC-адресу и имени, фильтры (*Все*, *Minew S1*, *iBeacon*, *Избранные*).

---

## 📂 Структура проекта

```
ios/
├── Package.swift                           # Поддержка Swift Package Manager
├── MinewBeaconScanner.xcodeproj/           # Стандартный проект Xcode
│   └── project.pbxproj
├── MinewBeaconScanner/                     # Исходный код приложения
│   ├── MinewBeaconScannerApp.swift         # Точка входа SwiftUI (@main)
│   ├── Info.plist                          # Разрешения Bluetooth для iOS
│   ├── Models/
│   │   ├── MinewHtData.swift               # Модель данных датчика S1 (температура, влажность, батарея, MAC)
│   │   ├── IBeaconData.swift               # Модель iBeacon (UUID, Major, Minor, TxPower, дистанция)
│   │   ├── SensorDataPoint.swift           # Точка данных для графика истории
│   │   └── BeaconDevice.swift              # Агрегированная модель маячка
│   ├── Parsers/
│   │   ├── MinewPacketParser.swift         # Декодер кадров Minew BeaconPlus (0xA1 0x01 HT, 0xA1 0x08 Info)
│   │   └── IBeaconParser.swift             # Декодер Apple iBeacon
│   ├── Bluetooth/
│   │   └── BleScannerManager.swift         # Менеджер CoreBluetooth CBCentralManager
│   ├── Theme/
│   │   └── AppTheme.swift                  # Цветовая палитра и стили
│   └── Views/
│       ├── ScannerView.swift               # Главный экран (поиск, фильтры, список)
│       ├── BeaconCardView.swift            # Карточка маячка
│       ├── BeaconDetailView.swift          # Детальный просмотр с графиками и Hex-инспектором
│       └── RadarScanIndicatorView.swift    # Анимированный радар сканирования
└── MinewBeaconScannerTests/
    └── MinewPacketParserTests.swift        # XCTest тесты для валидации парсинга
```

---

## 🚀 Как открыть и запустить проект

1. Откройте файл проекта в **Xcode**:
   ```bash
   open ios/MinewBeaconScanner.xcodeproj
   ```
   *Или откройте папку `ios/` в Xcode как Swift Package.*
2. Выберите цель запуска: физический iPhone или симулятор. *(Обратите внимание: на симуляторе iOS поддержка BLE сканирования ограничена Apple, для реального поиска BLE маячков рекомендуется запускать на физическом iPhone).*
3. Нажмите **Cmd + R** для запуска или **Cmd + U** для прогона тестов `MinewBeaconScannerTests`.
