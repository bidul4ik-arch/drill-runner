# Платёжная интеграция: подготовленная часть и границы

Реальные покупки **отключены**. `StoreBridge.gd` обслуживает явно маркированный тестовый магазин только с `--test-store`/`--test`. Тестовый профиль использует отдельный campaign_sandbox.json (автотесты — campaign_test.json). Тестовые премиум-монеты хранятся отдельно, не имеют денежной стоимости и не должны переноситься в платный баланс. По умолчанию UI не показывает выдуманные реальные цены.

`purchase_ledger.py` — проверяемое ядро серверного учёта, не опубликованный сервер. SQLite-транзакция атомарно записывает уникальную транзакцию магазина и баланс. Повторная доставка не начисляет второй раз, повтор покупки скина не списывает второй раз. Очередь acknowledgement сохраняется после перезапуска. По умолчанию verifier отклоняет все чеки. Тесты используют явно подставной verifier.

Для реального запуска необходимы:
- Google Play Console и App Store Connect, package/bundle identifiers, созданные consumable product IDs (текущие crystals_60 / crystals_180 — локальные ключи каталога, не зарегистрированные товары);
- Android Godot billing-плагин и iOS StoreKit-плагин/нативные мосты, соответствующие версии сборочных инструментов;
- ключи и права серверного доступа Google Play Developer API / App Store Server API, Team ID и сертификаты подписи мобильной сборки;
- HTTPS-сервер с аутентификацией пользователя, реальной проверкой receipt/token/JWS, привязкой транзакции к аккаунту, обработкой возвратов и уведомлений платформ;
- тестовые аккаунты и физические устройства/официальная sandbox-среда магазинов.

## Контракт для нативного моста

Каталог: `get_products(ids)` возвращает `{id, display_price, currency_code}` непосредственно от магазина. Покупка передаёт `product_id`; результат содержит `cancelled|pending|failed|purchased` и непрозрачный token/JWS. Событие purchased само по себе не даёт валюту. После authenticated `POST /purchases/verify {provider, receipt}` клиент перечитывает `GET /wallet`, сервер проверяет провайдера, приложение, аккаунт, продукт, статус и уникальность транзакции. Только затем выполняется подтверждение/consumption согласно магазину. Незавершённые receipt/token повторно отправляются при следующем запуске, а acknowledgement обрабатывается из серверной очереди. Покупка премиум-скина — атомарный `POST /cosmetics/purchase`, источник истины — серверные wallet + cosmetics.

В этом проекте нет работающего нативного моста, реального verifier, HTTP-развёртывания и аккаунтной системы. Наличие ядра и контракта не означает готовую оплату. Внешние запросы и реальные платежи не выполнялись.

Официальные источники:
- [Google: защита и серверная проверка](https://developer.android.com/google/play/billing/security)
- [Google: статусы, pending и интеграция](https://developer.android.com/google/play/billing/integrate)
- [Apple: App Store Server API](https://developer.apple.com/documentation/appstoreserverapi)
- [Apple: StoreKit In-App Purchase](https://developer.apple.com/documentation/storekit/in-app-purchase)
