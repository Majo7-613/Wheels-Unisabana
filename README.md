# Wheels Sabana

Plataforma de movilidad universitaria: React + Node + Express + MongoDB + Redis.

## Flujo principal (según reglas y tickets)
1) Autenticación institucional (registro/login con correo @unisabana.edu.co).
2) Configuración del conductor: vehículo y puntos de recogida.
3) Publicación de viajes y reservas (decremento atómico de cupos).
4) Cálculo de distancia/ETA (Google Distance Matrix con caché).
5) Navegación (Waze deep link) y calificaciones.

Autenticación primero: un usuario no autenticado solo debe ver Login/Registro; el resto de rutas son protegidas.

## Requisitos
- Node 18+
- Docker (opcional para MongoDB y Redis)
- PowerShell (Windows) para ejecutar scripts

## Instalación y ejecución (rápido)
- Opción 1 (un clic, Windows):
  - PowerShell en la raíz del proyecto:
    - powershell -ExecutionPolicy Bypass -File .\scripts\run-all.ps1
  - Abre:
    - Frontend: http://localhost:5173
    - Backend: http://localhost:4000 (health: /health, docs: /api-docs)

- Opción 2 (manual):
  1) Instala dependencias:
     - npm run setup
  2) Variables backend:
     - copy backend/.env.example backend/.env
     - Ajusta: JWT_SECRET, MONGO_URI, GOOGLE_MAPS_KEY (si usarás /maps/distance)
  3) Ejecuta en paralelo:
     - npm run dev:win
     - Frontend: http://localhost:5173
     - Backend: http://localhost:4000

## Estructura (resumen)
- frontend: Vite + Tailwind + Router + Tests
- backend: Express + Mongoose + Redis + Swagger + Jest/Supertest

## Endpoints principales (backend)
- Auth:
  - POST /auth/register
  - POST /auth/login
  - GET /auth/me  (Bearer <JWT>)
- Vehículos:
  - CRUD /vehicles
  - POST /vehicles/pickup-points
- Trips:
  - CRUD /trips
  - POST /trips/:id/book  (decremento cupos)
- Integraciones:
  - GET /maps/distance?origin=..&destination=..  (Google Distance Matrix)
  - GET /navigation/waze?lat=..&lng=..          (deep link)
- Swagger: http://localhost:4000/api-docs
- Health: /health

## Variables de entorno (backend)
PORT=4000
MONGO_URI=mongodb://localhost:27017/wheels
JWT_SECRET=supersecret
GOOGLE_MAPS_KEY=your_api_key
REDIS_URL=redis://localhost:6379

## Pruebas (backend)
- npm test
- Nota: los tests mockean Mongo/Redis y validan health, waze, y errores de Distance Matrix.

## Si el backend “no abre”
- Verifica health: http://localhost:4000/health (debe responder {"ok": true})
- Logs de arranque: busca “API Wheels Sabana en http://localhost:4000”
- Puerto ocupado:
  - netstat -ano | findstr :4000  → mata el PID con: taskkill /PID <pid> /F
  - Reintenta: cd backend && npm run dev
- Reinicios constantes (OneDrive):
  - Se añadió backend/nodemon.json para mirar solo /src. Si sigue, cierra otras ventanas de Node.
- Sin Mongo:
  - El server arranca igual (MONGO_URI opcional). /auth devolverá 503 hasta configurar DB.
- Error al iniciar:
  - Reinstala deps solo del backend: cd backend && npm ci
  - Borra caché nodemon (si persiste): npm i -D nodemon@latest

## Roadmap UI (Auth primero)
- Páginas:
  - /login y /register (correo institucional obligatorio)
  - ProtectedRoute para features (solo con JWT)
- Features:
  - AddPickupPointsDriver (tras login)
  - CalculateDistanceSystem (tras login o de solo lectura según ticket)
- Navbar:
  - Mostrar Login/Logout dinámico según sesión.

## Docker Desktop en Windows (necesario para `docker compose`)
1) Abre Docker Desktop y espera a que muestre “Engine running”.

2) Asegúrate de usar Linux containers (no Windows containers).

3) Habilita WSL 2:
   - PowerShell (Admin): wsl --install (reinicia si lo pide)
   - Verifica: wsl -l -v (debe haber una distro con versión 2)

4) Docker Desktop → Settings → Resources → WSL Integration → Enable integration para tu distro.

5) Prueba:
   - docker --version
   - docker info (no debe fallar)
   - docker compose up -d (desde la raíz del proyecto)

Si ves “open //./pipe/dockerDesktopLinuxEngine”:
- Docker Desktop no está corriendo o el motor Linux está apagado. Ábrelo y repite.
- Reinicia WSL: wsl --shutdown y luego reinicia Docker Desktop.

## Fallback sin Docker (temporal)
- Usa MongoDB Atlas:
  - Crea cluster, usuario y agrega tu IP.
  - backend/.env → MONGO_URI=mongodb+srv://USER:PASS@CLUSTER.mongodb.net/wheels
- Redis es opcional (el backend arranca sin Redis).
- Reinicia backend: cd backend && npm run dev
