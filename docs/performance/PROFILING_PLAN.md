# Performance Profiling Plan

## Objetivo

Estabelecer um fluxo leve e repetivel de profiling real para reduzir jank, rebuilds excessivos, leaks de memoria e picos de CPU antes de cada release relevante.

O foco inicial desta fase e validar quatro superficies criticas:

- `Home`
- `Player`
- `Queue`
- `Scan`

## Quando rodar

Rodar este plano nos seguintes casos:

- antes de release candidata (`RC`) ou release final
- apos mudancas grandes em navegacao, player, fila, scan ou artwork
- apos introduzir widgets animados, listas pesadas ou novos observers/listeners
- quando houver relato de travamento, lag, aquecimento ou consumo anormal

## Ambiente padrao

- build: `flutter run --profile`
- dispositivo: Android real principal do projeto
- biblioteca realista: usar acervo de teste com volume suficiente para expor gargalos
- apps em segundo plano: minimizar interferencia
- repetir cada cenario ao menos 2 vezes

Registrar sempre:

- data
- commit ou branch
- device
- versao Android
- tamanho aproximado da biblioteca
- observacoes do ambiente

## Ferramentas DevTools

Usar as quatro visoes abaixo:

- `Performance`: frame chart
- `Memory`
- `CPU Profiler`
- `Flutter Inspector`: track widget rebuilds

Para o passo a passo de captura e padrao de evidencias, usar `docs/performance/DEVTOOLS_CAPTURE_GUIDE.md`.

## Jornadas obrigatorias

### 1. Home

Cenario:

- abrir o app em profile mode
- aguardar a primeira renderizacao util
- navegar pelas tabs principais da Home
- rolar listas e cards com scroll continuo
- abrir e fechar destinos de maior uso a partir da Home

Observar:

- picos de frame acima do budget
- stutter no primeiro scroll
- rebuilds excessivos de secoes inteiras
- crescimento de memoria sem retorno apos navegar e voltar

### 2. Player

Cenario:

- abrir player com faixa em reproducao
- executar `play/pause`
- arrastar `seek`
- alternar `shuffle`
- alternar `repeat`
- abrir/fechar painel e voltar para Home

Observar:

- hitch ao abrir player
- custo de animacoes e artwork
- rebuilds em massa em controles pequenos
- leaks apos abrir/fechar player repetidamente

### 3. Queue

Cenario:

- abrir fila atual
- rolar lista longa
- tocar item distante
- reordenar itens
- voltar para player e retornar para fila

Observar:

- frames perdidos durante reorder e scroll
- custo alto de listas com artwork
- rebuilds desnecessarios por item
- aumento de memoria apos multiplas interacoes

### 4. Scan

Cenario:

- iniciar scan/import em biblioteca real
- observar progresso do inicio ao fim
- navegar minimamente durante o scan, se suportado
- repetir scan incremental quando aplicavel

Observar:

- CPU sustentada alta demais
- travamento perceptivel da UI
- crescimento de memoria nao recuperado
- burst de logs ou excecoes silenciosas

## Criterios de aceitacao iniciais

Estes criterios sao o gate inicial. Refinamos depois com baseline historica.

- sem travamento perceptivel nas jornadas obrigatorias
- sem explosao progressiva de memoria apos abrir/fechar telas criticas
- sem rebuilds obvios de tela inteira por interacao local
- sem excecoes no console durante profiling
- sem regressao clara versus build anterior validada

## Como registrar achados

Para cada tela, registrar:

- superficie
- cenario
- sintoma observado
- evidencia
- severidade
- hipotese tecnica
- acao proposta
- status

Modelo:

```md
### Home

- Cenario: abrir app e fazer primeiro scroll na tab principal
- Sintoma: jank no primeiro scroll
- Evidencia: frame chart com burst logo apos render inicial
- Severidade: media
- Hipotese tecnica: preload pesado + rebuild da secao inteira
- Acao proposta: adiar preload nao critico e reduzir escopo de listeners
- Status: aberto
```

## Evidencias minimas por rodada

Salvar ou anexar:

- 1 captura ou export do frame chart por superficie
- 1 observacao de memoria por superficie
- 1 observacao de CPU para `Scan`
- 1 observacao de rebuilds para `Home` e `Player`

## Saida esperada da rodada

Ao fim de cada rodada de profiling, produzir:

- lista curta de gargalos priorizados
- comparacao com ultima rodada valida
- decisao `go/no-go` para release
- backlog tecnico com correcoes de alta prioridade

## Onde salvar a baseline

Usar `docs/performance/PERF_BASELINE_TEMPLATE.md` como modelo e salvar cada rodada real em:

```text
docs/performance/baselines/PERF_BASELINE_YYYY-MM-DD_vX.Y.Z.md
```

Exemplo:

```text
docs/performance/baselines/PERF_BASELINE_2026-05-21_v1.6.0.md
```

## Fase 1 de maturidade

Esta primeira fase nao busca perfeicao. Busca:

- visibilidade real de performance
- disciplina de medir antes de publicar
- deteccao de regressao antes do usuario
- historico minimo para criar baseline confiavel

## Proximos passos recomendados

- anexar resultados por versao em `docs/release/`
- transformar gargalos recorrentes em testes e guardrails de arquitetura
