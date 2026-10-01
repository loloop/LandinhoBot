#!/usr/bin/env python3
"""Checks the actual result written after the native AppIntent.perform() call."""
import json
import sys

scenario, path = sys.argv[1:]
with open(path) as source:
    result = json.load(source)
assert result.get("developmentLocalization", "").replace("_", "-") == "pt-BR", result
assert "pt-BR" in [locale.replace("_", "-") for locale in result["bundleLocalizations"]], result
text = result.get("text", "")
error = result.get("error", "")
if scenario == "offline":
    assert not text and "Confira sua conexão" in error, result
elif scenario == "pending":
    assert "horário pendente" in text and "00:00" not in text, result
elif scenario == "cancelled":
    assert "canceladas" in text, result
elif scenario == "empty":
    assert "Não encontrei" in text, result
elif scenario == "race":
    assert "Corrida 1, Interlagos, de Stock Car Brasil" in text, result
    assert "fuso" in text and not error, result
elif scenario == "session":
    assert "Treino livre, São Paulo, de Fórmula 1" in text, result
    assert "fuso" in text and not error, result
elif scenario == "category":
    assert "Corrida, São Paulo, de Fórmula 1" in text, result
    assert result.get("categoryTag") == "f1" and not error, result
else:
    raise ValueError(f"Unknown native query scenario: {scenario}")
print(json.dumps({"scenario": scenario, "verified": True, "result": result}, ensure_ascii=False))
