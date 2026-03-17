# inAssist — iOS

Мобильное приложение для планирования событий в Google Calendar через чат на естественном языке. Напишите «встреча завтра в 18:00» — событие появится в календаре.

Часть проекта **inAssist** (бэкенд на FastAPI + ML-сервис для интерпретации запросов).

---

## Возможности

- **Вход через Google** — OAuth без сторонних SDK (`ASWebAuthenticationSession`)
- **Чат с ассистентом** — отправка текста, ответ с созданным событием и ссылкой «Open in calendar»
- **Индикатор «Печатает...»** — отображается пока ждём ответ от сервера
- **Меню** — список чатов, переключение диалогов, кнопка «My calendar»
- **Профиль** — данные пользователя, выход из аккаунта
- **Централизованная обработка ошибок** — при 401 показ экрана входа, при сетевых сбоях — алерт

---

## Стек

| Компонент | Технология |
|-----------|------------|
| UI | UIKit, Auto Layout (программно) |
| Сеть | URLSession, Codable |
| Авторизация | ASWebAuthenticationSession, custom URL scheme `inassist://` |
| Хранение сессии | UserDefaults (SessionStore) |
| Минимальная версия | iOS 15+ |

---

## Требования

- Xcode 15+
- Работающий бэкенд inAssist (для логина и чата)
- Учётная запись Google

---

## Структура проекта

```
iOS_inAssist/
├── App/                    # Точка входа, роутинг
│   ├── AppDelegate.swift
│   ├── SceneDelegate.swift
│   └── AppRouter.swift     # showLogin(), showNetworkErrorAlert()
├── Core/
│   ├── Auth/
│   │   └── SessionStore.swift
│   ├── Network/
│   │   ├── APIClient.swift
│   │   └── Models.swift
│   └── Design/
│       └── Colors.swift   # AppColors, AppFonts, AppShadows, AppCornerRadius
├── Features/
│   ├── Onboarding/        # Экран входа, Google Sign-In
│   ├── MainChat/          # Чат, подсказки, календарь
│   ├── Menu/              # Боковое меню, список чатов
│   └── Profile/           # Профиль, Log out
└── Resources/             # Assets, Info.plist
```

---

## Запуск

1. Клонировать репозиторий:
   ```bash
   git clone https://github.com/nikkol615/iOS-inAssist.git
   cd iOS-inAssist
   ```
2. Открыть `iOS_inAssist.xcodeproj` в Xcode.
3. При необходимости задать базовый URL бэкенда в `iOS_inAssist/Core/Network/Models.swift` (enum `APIConfig`, `baseURL`).
4. Собрать и запустить на симуляторе или устройстве (⌘R).

Убедитесь, что бэкенд доступен по указанному `baseURL` и что в Info.plist настроен URL scheme `inassist` для OAuth callback.

---

## Конфигурация

- **Базовый URL API** — `APIConfig.baseURL` в `Core/Network/Models.swift`.
- **OAuth** — схема `inassist`, redirect URI `inassist://auth` (должны совпадать с настройками бэкенда).

---

## Что проверить вручную

1. **Календарь** — иконка календаря в шапке или «My calendar» в меню открывают Google Calendar в Safari View Controller.
2. **«Печатает...»** — после отправки сообщения внизу чата появляется индикатор, после ответа — сообщение ассистента.
3. **401** — при ответе 401 от API сессия сбрасывается и показывается экран входа.
4. **Сеть** — при отключённом интернете (или таймауте) показывается алерт «Нет подключения».

---

## Лицензия

См. [LICENSE](LICENSE).
