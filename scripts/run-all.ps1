Param([switch]$NoDocker)
$ErrorActionPreference = "Stop"
function Write-Step($m){Write-Host "STEP: $m" -ForegroundColor Cyan}
function Write-Ok($m){Write-Host "OK: $m" -ForegroundColor Green}
function Write-Warn($m){Write-Host "WARN: $m" -ForegroundColor Yellow}

Set-Location (Join-Path $PSScriptRoot "..")

Write-Step "Verificando Node.js 18+"
$nodeVersion = (& node -v) 2>$null
if (-not $nodeVersion){ throw "Node.js no está instalado o no está en PATH." }
$ver = $nodeVersion.TrimStart('v'); try{$verObj=[version]$ver}catch{$verObj=[version]"0.0.0"}
if ($verObj -lt [version]"18.0.0"){ Write-Warn "Se recomienda Node 18+. Detectado: $nodeVersion" } else { Write-Ok "Node $nodeVersion" }

if (-not $NoDocker -and (Test-Path ".\docker-compose.yml") -and (Get-Command docker -ErrorAction SilentlyContinue)){
  Write-Step "Levantando servicios Docker (Mongo/Redis)"; try{ docker compose up -d | Out-Null; Write-Ok "Docker OK" }catch{ Write-Warn "Docker error: $($_.Exception.Message)" }
}

function Ensure-NpmInstall($d){ Push-Location $d; try{ if (-not (Test-Path "node_modules")){ Write-Step "npm install en $d"; npm install | Out-Null; Write-Ok "Instalado $d"} else { Write-Ok "node_modules existe en $d"} } finally { Pop-Location } }
Ensure-NpmInstall "frontend"; Ensure-NpmInstall "backend"

# Ensure @vitejs/plugin-react
$pluginPkg = Join-Path $PWD "frontend\node_modules\@vitejs\plugin-react\package.json"
if (-not (Test-Path $pluginPkg)){ Write-Step "Instalando @vitejs/plugin-react"; Push-Location "frontend"; npm i -D @vitejs/plugin-react | Out-Null; Pop-Location; Write-Ok "Plugin react instalado" } else { Write-Ok "Plugin react presente" }

if (-not (Test-Path ".\backend\.env") -and (Test-Path ".\backend\.env.example")){
  Write-Step "Creando backend/.env"; Copy-Item ".\backend\.env.example" ".\backend\.env"; Write-Warn "Ajusta GOOGLE_MAPS_KEY si usarás /maps/distance"; Write-Ok ".env creado"
}

Write-Step "Iniciando backend (http://localhost:4000)"; Start-Process powershell -ArgumentList '-NoExit','-Command','cd backend; npm run dev'
Start-Sleep -Seconds 2
Write-Step "Iniciando frontend (http://localhost:5173)"; Start-Process powershell -ArgumentList '-NoExit','-Command','cd frontend; npm run dev'

Start-Sleep -Seconds 4
Write-Step "Abriendo URLs"; Start-Process "http://localhost:4000/health"; Start-Process "http://localhost:4000/api-docs"; Start-Process "http://localhost:5173"
Write-Ok "Listo."
