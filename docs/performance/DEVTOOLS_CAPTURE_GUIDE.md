# DevTools Capture Guide

Guia operacional para capturar evidencias de performance em build profile.

## Preparacao

- Fechar apps pesados em segundo plano.
- Conectar dispositivo Android real via USB.
- Confirmar que o device aparece em `flutter devices`.
- Confirmar que `flutter doctor -v` esta sem issues antes da rodada oficial.
- Usar biblioteca de teste com volume realista.
- Rodar o app com:

```bash
flutter run --profile -d RQCW805VFCB
```

Quando o terminal exibir o link do DevTools, abrir no navegador e manter a sessao ate concluir a rodada.

## Evidencias por superficie

### Home

- `Performance`: gravar abertura da Home, troca de tabs e scroll continuo.
- `Memory`: observar heap antes/depois de navegar e voltar.
- `Flutter Inspector`: habilitar rebuild stats e interagir com tabs/listas.
- Registrar jank perceptivel, rebuilds de tela inteira e crescimento de memoria.

### Player

- `Performance`: gravar abertura do Player e interacoes de controle.
- `Memory`: repetir abrir/fechar Player algumas vezes e observar retorno.
- `Flutter Inspector`: verificar se play/pause, seek, shuffle e repeat nao disparam rebuild amplo.
- Registrar custo de artwork, animacoes e painel.

### Queue

- `Performance`: gravar scroll longo, tocar item distante e reorder.
- `Memory`: observar comportamento apos multiplas interacoes.
- `Flutter Inspector`: verificar rebuild por item versus lista inteira.
- Registrar queda de frames durante reorder/scroll.

### Scan

- `CPU Profiler`: gravar scan/import com biblioteca real.
- `Memory`: observar crescimento durante e apos scan.
- `Performance`: verificar se a UI segue responsiva enquanto o scan roda.
- Registrar CPU sustentada, travamentos e logs/excecoes.

## Padrao de arquivos

Salvar capturas/exportacoes, quando existirem, com nomes descritivos:

```text
docs/performance/baselines/evidence/YYYY-MM-DD_vX.Y.Z_home_frame-chart.png
docs/performance/baselines/evidence/YYYY-MM-DD_vX.Y.Z_player_memory.png
docs/performance/baselines/evidence/YYYY-MM-DD_vX.Y.Z_queue_rebuilds.png
docs/performance/baselines/evidence/YYYY-MM-DD_vX.Y.Z_scan_cpu.json
```

Se a evidencia ficar fora do repositorio, registrar o caminho ou referencia no arquivo da baseline.

## Registro minimo na baseline

Para cada superficie, preencher:

- Frame chart: resumo do comportamento e referencia da captura.
- Memory: antes/depois e qualquer crescimento suspeito.
- CPU: relevante principalmente para `Scan`.
- Rebuild stats: componentes com rebuild excessivo.
- Resultado: `ok`, `atencao` ou `bloqueante`.
- Observacoes: contexto que explique variacao da rodada.

## Decisao go/no-go

Usar `no-go` se houver:

- travamento perceptivel em fluxo principal
- crescimento progressivo de memoria sem retorno
- excecoes no console durante a jornada
- rebuild amplo causado por interacao local simples
- regressao clara versus baseline anterior

Usar `go` apenas quando os achados restantes forem aceitaveis para a release e tiverem backlog definido.
