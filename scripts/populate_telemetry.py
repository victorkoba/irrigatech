#!/usr/bin/env python3
"""
Script de População de Telemetria — IrrigaTech
----------------------------------------------
Gera leituras de sensores de 10 em 10 segundos para todos os setores ativos
cadastrados no banco de dados PostgreSQL via API do Backend (http://localhost:3000).

Funcionalidades atendidas:
1. Popula o histórico inicial do dia (de 1 em 1 hora) e o comparativo semanal
   assim que o script é iniciado.
2. A cada 10 segundos, busca a lista atualizada de setores do Controle
   (garantindo que setores adicionados ou excluídos sejam refletidos automaticamente)
   e grava novas leituras de:
   - Umidade do Solo (%) -> usada na média de 1 em 1 hora e no gráfico de colunas
   - Temperatura (°C) -> usada na média de 10 em 10 minutos
   - Precipitação (mm) -> usada na média de 10 em 10 minutos
   - Consumo de Energia (kWh) -> usada na média de 1 em 1 hora
   - Consumo de Água (L) e Eficiência (%) -> atualizam o Comparativo Semanal e Dashboard
3. Ocasionalmente simula picos de Água, Energia ou Temperatura para demonstrar
   os alertas condicionais na Dashboard.

Como executar:
    python scripts/populate_telemetry.py
Para executar apenas 1 ciclo e encerrar (útil para testes rápidos):
    python scripts/populate_telemetry.py --once
"""

import json
import random
import sys
import time
import urllib.error
import urllib.request
from datetime import datetime

API_BASE_URL = "http://localhost:3000/api"
INTERVAL_SECONDS = 10


def api_request(method: str, path: str, payload: dict | None = None) -> dict | list | None:
    url = f"{API_BASE_URL}{path}"
    data = None
    headers = {"Content-Type": "application/json"}
    if payload is not None:
        data = json.dumps(payload).encode("utf-8")

    req = urllib.request.Request(url, data=data, headers=headers, method=method)
    try:
        with urllib.request.urlopen(req, timeout=10) as response:
            raw = response.read().decode("utf-8")
            return json.loads(raw) if raw else None
    except urllib.error.HTTPError as e:
        err_body = e.read().decode("utf-8", errors="ignore")
        print(f"[ERRO HTTP {e.code}] {method} {url}: {err_body}")
        return None
    except urllib.error.URLError as e:
        print(f"[ERRO DE CONEXÃO] Não foi possível conectar em {url}: {e.reason}")
        print("Certifique-se de que o backend Node.js está rodando (cd backend && npm start).")
        return None


def seed_initial_history():
    print("=" * 65)
    print("🌱 [IrrigaTech] Inicializando histórico de telemetria no banco...")
    res = api_request("POST", "/monitoring/seed-history", {})
    if res and res.get("success"):
        print(f"✅ {res.get('message')}")
    else:
        print("⚠️ Não foi possível inicializar o histórico inicial. Verifique o backend.")
    print("=" * 65)


def generate_reading_for_sector(sector: dict, tick_count: int) -> dict:
    sector_id = sector.get("id", "A")
    is_irrigating = bool(sector.get("isIrrigating", False))

    # Base de umidade maior se estiver irrigando
    base_moisture = 74.0 if is_irrigating else 64.0
    moisture = round(random.uniform(base_moisture - 6.0, base_moisture + 8.0), 1)

    # Temperatura e precipitação para janela de 10 em 10 minutos
    temperature = round(random.uniform(22.5, 31.0), 1)
    precipitation = round(random.choice([0.0, 0.0, 0.2, 0.5, 1.2, 2.5]), 1)

    # Consumo de água (L) e energia (kWh)
    water_consumption = round(random.uniform(110.0, 170.0) if is_irrigating else random.uniform(40.0, 95.0), 1)
    energy_consumption = round(random.uniform(14.0, 27.0) if is_irrigating else random.uniform(6.0, 14.0), 2)
    efficiency = round(random.uniform(91.0, 98.5), 1)

    # A cada 6 ciclos (~60s), simula um pico em um setor para demonstrar alertas condicionais
    if tick_count > 0 and tick_count % 6 == 0 and sector_id == "A":
        spike_type = random.choice(["water", "energy", "temperature"])
        if spike_type == "water":
            water_consumption = round(random.uniform(210.0, 245.0), 1)
        elif spike_type == "energy":
            energy_consumption = round(random.uniform(36.0, 44.0), 2)
        else:
            temperature = round(random.uniform(36.0, 39.5), 1)

    return {
        "sectorId": sector_id,
        "moisture": moisture,
        "temperature": temperature,
        "precipitation": precipitation,
        "waterConsumption": water_consumption,
        "energyConsumption": energy_consumption,
        "efficiency": efficiency,
        # Na primeira execução forçamos a atualização dos snapshots para refletir imediatamente
        "forceSnapshotRefresh": tick_count == 1,
    }


def run_loop(run_once: bool = False):
    seed_initial_history()
    tick = 0

    try:
        while True:
            tick += 1
            now_str = datetime.now().strftime("%H:%M:%S")
            sectors = api_request("GET", "/sectors")

            if not sectors or not isinstance(sectors, list):
                print(f"[{now_str}] ⚠️ Nenhum setor encontrado ou backend indisponível.")
            else:
                print(f"\n[{now_str}] 🔄 Ciclo #{tick} — Gerando dados (10s em 10s) para {len(sectors)} setor(es):")
                for sector in sectors:
                    payload = generate_reading_for_sector(sector, tick)
                    res = api_request("POST", "/monitoring/readings", payload)
                    if res is not None:
                        print(
                            f"   • Setor {sector.get('id')} ({sector.get('name')}): "
                            f"Umidade={payload['moisture']}% | "
                            f"Temp={payload['temperature']}°C | "
                            f"Precip={payload['precipitation']}mm | "
                            f"Energia={payload['energyConsumption']}kWh | "
                            f"Água={payload['waterConsumption']}L"
                        )

            if run_once:
                print("\n✅ Execução única (--once) concluída com sucesso!")
                break

            time.sleep(INTERVAL_SECONDS)
    except KeyboardInterrupt:
        print("\n🛑 Script de população finalizado pelo usuário.")


if __name__ == "__main__":
    once_flag = "--once" in sys.argv
    run_loop(run_once=once_flag)
