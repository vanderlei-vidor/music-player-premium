# Release Checklist (Android/Web)

## 1. Pre-release (obrigatorio)

- [ ] Confirmar versao no `pubspec.yaml` (release alvo atual).
- [ ] Revisar changelog em `CHANGELOG.md`.
- [ ] Rodar qualidade local:
  - [ ] `flutter clean`
  - [ ] `flutter pub get`
  - [ ] `flutter analyze`
  - [ ] `flutter test`
- [x] Rodar profiling real em `--profile` conforme `docs/performance/PROFILING_PLAN.md`:
  - [x] Ambiente Flutter/DevTools validado (`flutter doctor -v` sem issues)
  - [x] Home: frame chart, memory e rebuild stats
  - [x] Player: frame chart, memory e rebuild stats
  - [x] Queue: frame chart, memory e rebuild stats
  - [x] Scan: CPU, memory e responsividade geral
  - [x] Criar registro da rodada em `docs/performance/baselines/` usando `docs/performance/PERF_BASELINE_TEMPLATE.md`
- [ ] Validar assets e branding:
  - [ ] Icone correto
  - [ ] Nome do app (`Music Music`) em telas e metadados
  - [ ] `README.md` atualizado
- [ ] Smoke test manual:
  - [ ] Splash -> Welcome/Home
  - [ ] Scan/import de musicas
  - [ ] Capa/thumbnail de arquivo local sem erro no terminal (`file://`, caminho Windows/Android)
  - [ ] Player (play/pause, seek, shuffle, repeat, sleep timer)
  - [ ] Playlists (criar, adicionar, remover, tocar)
  - [ ] Favoritas, Recentes e Mais tocadas
  - [ ] Navegacao Album/Player/Home sem erro apos `dispose` ou listener tardio

## 2. Android (producao)

### Configuracao
- [ ] Conferir `applicationId` e package final (evitar `com.example.*` em producao).
- [ ] Conferir assinatura de release (`key.properties`/keystore).
- [ ] Conferir permissoes no `AndroidManifest.xml`.

### Build
- [ ] Gerar App Bundle:
  - [ ] `flutter build appbundle --release`
- [ ] (Opcional) Gerar APK:
  - [ ] `flutter build apk --release`

### Validacao de artefato
- [ ] Instalar build release em dispositivo real.
- [ ] Validar controles de midia/notificacao em background.
- [ ] Validar artwork local e fallback de capa em Android real.
- [ ] Verificar tamanho do bundle e regressao de startup.

### Publicacao Play Console
- [ ] Subir `.aab` na trilha interna/fechada.
- [ ] Preencher notas da versao (usar `CHANGELOG.md`).
- [ ] Validar politica de permissoes e conteudo.
- [ ] Promover para producao apos validacao.

## 3. Web (producao)

### Build
- [ ] `flutter build web --release`

### Deploy
- [ ] Publicar conteudo de `build/web` no hosting/CDN.
- [ ] Configurar cache headers adequados (evitar cache agressivo do `index.html`).
- [ ] Garantir fallback de rotas para SPA (servir `index.html`).

### Validacao pos-deploy
- [ ] Testar em Chrome/Edge (desktop) e Android/iOS navegador.
- [ ] Validar upload/import web, navegacao e player.
- [ ] Validar fallback de artwork quando provider local nao estiver disponivel na Web.
- [ ] Verificar Lighthouse basico (Performance/Best Practices/SEO).

## 4. Pos-release

- [ ] Conferir terminal/logcat sem excecoes de `ImageProvider` ou listeners apos navegacao.
- [ ] Criar tag Git da versao (ex.: `v1.6.0`).
- [ ] Arquivar artefatos de build.
- [ ] Monitorar crashes/feedback nas primeiras 24-72h.
- [ ] Abrir backlog de hotfix se necessario.
