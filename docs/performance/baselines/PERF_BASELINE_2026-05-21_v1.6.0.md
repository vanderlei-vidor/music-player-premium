# Performance Baseline - 2026-05-21 - v1.6.0

## Contexto da rodada

- Data: 2026-05-21
- Versao: 1.6.0+1
- Commit: ed57085
- Device: SM M146B (`RQCW805VFCB`, android-arm64)
- Android: Android 15 (API 35)
- Biblioteca de teste: ~1.700 a ~2.000 musicas locais
- Build usada: `flutter run --profile`
- Flutter: 3.35.1 stable (`20f8274939`)
- Dart: 3.9.0
- DevTools: 2.48.0
- Host: Windows 11 Home Single Language 64-bit, 25H2
- Android SDK: 35.0.0
- Java/JDK: Temurin OpenJDK 17.0.13+11
- Flutter doctor: sem issues em 2026-05-21
- Devices detectados: SM M146B, Windows desktop, Chrome, Edge

## Ambiente validado

- `flutter --version`: ok
- `flutter devices`: ok, device Android real detectado
- `flutter doctor -v`: ok, sem issues

## Home

- Frame chart: estavel na maior parte da jornada, com picos isolados de jank no carregamento inicial/primeira rolagem. A rolagem estabilizou depois do primeiro uso.
- Memory: Dart Heap 29.7 MB; total size 32.1 MB. Consumo baixo para abertura da Home.
- CPU: 2502 samples em aproximadamente 1s de extent. Atividade baixa em repouso e processamento sem travamento perceptivel durante rolagem.
- Rebuild stats: sem indicio de rebuild em loop com o app em repouso. O contador especifico nao ficou acessivel nesta rodada; validacao feita por estabilidade do frame chart durante scroll.
- Resultado: aprovado para producao.
- Observacoes: picos iniciais podem estar ligados a shader warmup, I/O inicial ou primeira montagem de widgets/listas. Nao houve evidencia de memory leak apos interacoes repetidas de scroll.

## Player

- Frame chart: estavel, sem quedas bruscas observadas durante transicao para o Player.
- Memory: impacto baixo para `MusicEntity` e `ProgressiveAudioSource`; objetos observados somaram aproximadamente 0.3 MB.
- CPU: estavel, com consumo concentrado no processamento normal de audio/stream.
- Rebuild stats: sem sinal de rebuild amplo durante interacoes principais; uso de `_StaggerReveal` sugere animacoes controladas.
- Resultado: aprovado.
- Observacoes: comportamento saudavel mesmo com volume alto de musicas carregadas. Nao houve sinal de lentidao perceptivel no Player durante a rodada.

## Queue

- Frame chart: estavel, com pequenas oscilacoes esperadas durante reorder/scroll, sem engasgo visivel.
- Memory: aproximadamente 38 MB a 42 MB durante a jornada.
- CPU: baixa, com picos pontuais ao trocar faixa ou reorganizar itens.
- Rebuild stats: renderizacao aparentemente restrita aos itens visiveis da lista.
- Resultado: aprovado.
- Observacoes: a gestao da fila via `audio_service` se manteve limpa. Mesmo com centenas de itens, a memoria nao escalou de forma perigosa nesta rodada.

## Scan

- Frame chart: oscilacao moderada durante leitura/indexacao, esperada por carga de I/O.
- Memory: subida temporaria para aproximadamente 50 MB a 60 MB durante indexacao; estabilizou apos o termino.
- CPU: alta durante o scan, dentro do esperado para import/indexacao. A UI permaneceu responsiva.
- Rebuild stats: concentrado no progresso do scan, como barra/contador.
- Resultado: aprovado.
- Observacoes: `sqflite` e construcao de entidades se comportaram bem para aproximadamente 1.700 musicas, sem travar a thread principal de forma perceptivel.

## Achados priorizados

- P0: nenhum bloqueante. Nao foram detectados memory leaks, travamentos totais ou ANR.
- P1: investigar shader warmup ou primeira montagem da Home para reduzir picos iniciais de jank.
- P2: avaliar descarte/cache de imagens de capas ao fechar Queue/Scan para manter o heap previsivel em bibliotecas maiores.

## Go / No-Go

- Decisao: GO para seguir no fluxo de release.
- Justificativa: performance aprovada em Home, Player, Queue e Scan no device real SM M146B em profile mode. Memoria e CPU ficaram dentro do esperado, sem travamento perceptivel, sem evidencia de leak progressivo e sem bloqueante encontrado.
