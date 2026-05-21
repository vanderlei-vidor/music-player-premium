# Performance Docs

Documentacao para medir, comparar e decidir performance antes de releases relevantes.

## Arquivos

- `PROFILING_PLAN.md`: roteiro de profiling real com DevTools.
- `DEVTOOLS_CAPTURE_GUIDE.md`: passo a passo operacional para capturar evidencias.
- `PERF_BASELINE_TEMPLATE.md`: modelo para registrar uma rodada.
- `baselines/`: historico de rodadas reais por data e versao.

## Fluxo recomendado

1. Rodar o app em `flutter run --profile`.
2. Executar as jornadas obrigatorias em Home, Player, Queue e Scan.
3. Capturar evidencias seguindo `DEVTOOLS_CAPTURE_GUIDE.md`.
4. Copiar `PERF_BASELINE_TEMPLATE.md` para `baselines/PERF_BASELINE_YYYY-MM-DD_vX.Y.Z.md`.
5. Registrar evidencias, achados priorizados e decisao `go/no-go`.
