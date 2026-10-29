#!/usr/bin/env python3
"""
Script de Limpeza de Telemetria — IrrigaTech
--------------------------------------------
Remove todos os dados de monitoramento do banco de dados PostgreSQL via API
(leituras de sensores, snapshots de 1h e 10min, histórico do dia, comparativo
semanal e alertas gerados).

Após rodar este script, as telas de Monitoramento e Dashboard ficarão sem
dados de sensores até que o script `scripts/populate_telemetry.py` seja
executado novamente.

Como executar:
    python scripts/clear_telemetry.py
"""

import json
import urllib.error
import urllib.request

API_BASE_URL = "http://localhost:3000/api"


def clear_telemetry():
    url = f"{API_BASE_URL}/monitoring/clear"
    req = urllib.request.Request(url, method="DELETE", headers={"Content-Type": "application/json"})
    print("=" * 65)
    print("🧹 [IrrigaTech] Limpando dados de monitoramento do banco de dados...")
    try:
        with urllib.request.urlopen(req, timeout=10) as response:
            raw = response.read().decode("utf-8")
            data = json.loads(raw) if raw else {}
            print(f"✅ {data.get('message', 'Dados removidos com sucesso!')}")
            print("ℹ️  A tela de Monitoramento agora exibirá o estado vazio até que")
            print("   o script `python scripts/populate_telemetry.py` seja executado.")
    except urllib.error.HTTPError as e:
        err_body = e.read().decode("utf-8", errors="ignore")
        print(f"[ERRO HTTP {e.code}] Falha ao limpar dados: {err_body}")
    except urllib.error.URLError as e:
        print(f"[ERRO DE CONEXÃO] Não foi possível conectar em {url}: {e.reason}")
        print("Certifique-se de que o backend Node.js está rodando (cd backend && npm start).")
    print("=" * 65)


if __name__ == "__main__":
    clear_telemetry()
