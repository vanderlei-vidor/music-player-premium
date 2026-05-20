# Release Notes 1.6.0

Data da release: 6 de marco de 2026  
Versao: `1.6.0+1`

## Play Console (PT-BR)

Melhoramos a experiencia de reproducao e o acesso rapido ao app nesta versao:

- Novos widgets Android para player, favoritas, recentes e playlists.
- Widget do player com controles de reproducao, artwork, titulo, artista e fila.
- Gapless playback para reproducao continua entre faixas compativeis.
- Crossfade configuravel para transicoes mais suaves entre musicas.
- Melhorias no equalizador, nos controles de playback e na estabilidade do player.

## Web Release Summary (PT-BR)

Esta atualizacao foca em acesso rapido, reproducao continua e UX de audio:

- Widgets de atalho para Android com visual alinhado ao tema do app.
- Configuracoes de Gapless/Crossfade persistidas por usuario.
- Melhor continuidade de reproducao e controles de fila.
- Base mantida de estados de tela padronizados, logs locais e smoke tests.

## Internal QA Notes

- Validar widgets Android em tamanhos 2x2, 4x2 e 4x4.
- Confirmar controles do widget: play/pause, anterior/proxima, favorita, shuffle/repeat e selecao de faixa.
- Confirmar Gapless/Crossfade em albuns locais e filas mistas.
- Confirmar fluxo completo: Home -> Biblioteca -> Playlists -> Player -> Widgets.
