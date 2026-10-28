# SKYLOT Auction — серверна версія 1.2.1

Каркас серверної версії аукціону: **Node.js 20 + Fastify + PostgreSQL**, з реальним захистом (паролі Argon2id, сесії в базі, 2FA, ліміти, незмінний журнал), живими ставками (WebSocket) та імпортом даних із прототипу.

> **Статус.** Сервер: код написано й перевірено на синтаксис, unit-тести безпеки проходять (`npm test`). Інтерфейс (етап 1): реєстрація, підтвердження email, вхід, кабінет, лоти з пошуком/сортуванням, ставки наживо, вікно лота з обговоренням, виставлення лотів із фото, реклама, угоди з чатом — перевірено наскрізним тестом проти **мок-API** (48 перевірок, `npm run test:e2e`). Сервер із живою PostgreSQL я **не запускав**: у середовищі підготовки не було мережі й бази. Тому перший запуск на вашому сервері вважайте приймальним тестуванням: пройдіть «Перший запуск», потім `docs/SECURITY.md`.

## Що всередині

```
src/            сервер: routes/ (auth, lots, deals, admin), security, money, jobs/closer, ws
db/migrations/  схема PostgreSQL (001_init.sql)
scripts/        migrate · create-admin · import-backup
public/         інтерфейс на API: index.html, css/, js/ (модулі), docs/ (Правила, Конфіденційність, Cookie), img/
prototype/      повний інтерфейс-прототип (localStorage-версія 1.1.0) — еталон для решти екранів
docs/           TZ.md (ТЗ) · MIGRATION.md · API.md · SECURITY.md · FRONTEND.md
test/           security.test.js (unit) · mock/server.js (мок API) · e2e/run.mjs (тест інтерфейсу)
Dockerfile · docker-compose.yml · Caddyfile · .env.example
```

> **Хочете спершу спробувати на своєму комп'ютері?** Дивіться `docs/LOCAL.md` (3 способи: від подвійного кліку по прототипу до повного сервера в Docker).

## Перший запуск (Docker, з HTTPS)

1. Сервер із Docker і доменом, що вказує на його IP (порти 80/443 відкриті).
2. `cp .env.example .env` і заповніть: `POSTGRES_PASSWORD`, `COOKIE_SECRET` (`openssl rand -hex 32`), `ADMIN_ENTRY` (випадковий рядок), `PUBLIC_URL`, `DOMAIN`, `DATABASE_URL` (пароль той самий), SMTP для листів.
3. `docker compose up -d --build`
4. Міграції: `docker compose exec app node scripts/migrate.js`
5. Адмін: `docker compose exec -e ADMIN_PASSWORD='<12+ символів, літери й цифри>' app node scripts/create-admin.js you@example.com`
6. Відкрийте `https://<домен>/api/health` → `{"ok":true}`; потім `https://<домен>/` — контрольна сторінка.
7. Увійдіть адміном: `POST /api/<ADMIN_ENTRY>/login`, одразу ввімкніть 2FA (`POST /api/admin/2fa/start` → `confirm`).

## Без Docker

Потрібні Node 20+ і PostgreSQL 14+ (розширення `citext`). `npm install`, задайте змінні з `.env.example` в оточенні, далі `npm run migrate`, `npm run admin -- you@example.com`, `npm start`. За reverse proxy виставте `TRUST_PROXY=1`.

## Перенесення даних із прототипу

Бекап `.json` з адмінки прототипу → `docker compose cp backup.json app:/tmp/ && docker compose exec app node scripts/import-backup.js /tmp/backup.json --dry-run`, потім без `--dry-run`. Деталі й відповідність полів — `docs/MIGRATION.md`.

## Резервні копії та експлуатація

- База: щоденно `pg_dump` (cron) + перевірка відновлення раз на квартал; для PITR — WAL-архівація.
- Фото: том `uploads` (`/data/uploads`) копіюйте разом із базою.
- Логи — stdout контейнера; підключіть Sentry/Grafana за потреби.
- Кілька екземплярів: закривач лотів безпечний (`FOR UPDATE SKIP LOCKED`), але ліміти частоти (`src/limit.js`) і розсилка WebSocket тримаються в памʼяті — для масштабування додайте Redis.

## Розробка інтерфейсу без бази

`npm run mock` → http://localhost:3100 — мок API з тими ж маршрутами й кодами помилок (код підтвердження email `123456`). Наскрізний тест: `npm i -D playwright && npx playwright install chromium && npm run test:e2e`.

## Що ще не перенесено з прототипу (етап 2)

- **Інтерфейс адміністратора** (API готовий): користувачі, угоди з перепискою, спори, налаштування комісій, журнал і CSV, банери, 2FA, прихований вхід.
- Головна: карусель «Топ-10 продавців», бокова панель рейтингу лотів, рекламні банери (потрібні публічні ендпоїнти для рейтингу продавців), конструктор вигляду.
- Фото в коментарях продавця; експорт `.xlsx` (є CSV); платіжний провайдер і API «Нової пошти»; email-сповіщення про ставки й угоди.
- Правила/Політики на сервері зберігають лише версії прийняття; тексти лежать у `public/docs/*.md` — відредагуйте їх (дані оператора!) і піднімайте `settings.docs`, щоб користувачі прийняли нову версію.
