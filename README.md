# ⚽ Futebol Arcade — Fase 1 (Polished)

Jogo de futebol arcade estilo FIFA/PES para Android (APK).
Motor: Godot 4.x | Arte: Cartoon vibrante | Física: Custom

## 🎮 Controles

### Player 1 (Time Azul 🔵)
- **WASD / Joystick Esq** — Movimentação
- **ESPAÇO / Botão CHUTE** — Segurar = charge, soltar = chute forte
- **Encostar na bola** — Toque suave automático (passe curto)

### Player 2 (Time Vermelho 🔴)
- **Setas / Joystick Dir** — Movimentação
- **J / Botão CHUTE** — Segurar = charge, soltar = chute forte
- **Encostar na bola** — Toque suave automático (passe curto)

### Touch (Mobile — 2 jogadores mesmo device)
- **Metade esquerda da tela** = Joystick P1
- **Metade direita da tela** = Joystick P2
- **Botão CHUTE em cada lado** = Chute com charge

## 🧠 Mecânicas Implementadas

### Sistema de Chute com Charge
- Toque suave automático ao encostar na bola (força leve = passe)
- Botão de charge: segurar até 0.5s → soltar = chute forte
- Barra de carga visual por jogador (topo da tela)
- Chute forte = mais velocidade + trajetória mais fechada

### Física da Bola (Custom)
- Sem RigidBody2D — controle total via código
- Fricção: 0.99/frame (bola mais "viva")
- Bounce: 0.5 nas paredes (menos pinball)
- Max speed: 650 px/s
- Arco no chute via componente vertical

### Campo
- Desenhado via `_draw()` do Godot
- Faixas de grama (efeito visual)
- Goleiras coloridas (azul/vermelho)
- Rede da goleira (linhas sutis)
- Áreas do gol (semi-transparentes)

### Partida
- 2 tempos de 2 minutos
- Detecção de gol (rect da goleira)
- Celebração de gol (2.5s pausa)
- Kickoff delay (1.5s entre lances)
- Placar em tempo real
- Mensagem de fim de jogo

### HUD Completo
- Placar (topo central)
- Timer (MM:SS)
- Barras de charge (por jogador)
- Dois joysticks virtuais (split screen)
- Dois botões de chute
- Mensagens de gol/fim de jogo

## 📁 Estrutura

```
futebol-arcade/
├── project.godot
├── README.md
├── scenes/
│   ├── main.tscn          # Cena principal
│   ├── field.tscn         # Campo
│   ├── ball.tscn          # Bola
│   └── player.tscn        # Jogador
└── scripts/
    ├── ball.gd            # Física custom da bola
    ├── player.gd          # Controle + charge
    ├── player_visual.gd   # Cores por equipe
    ├── field.gd           # Campo (draw)
    ├── match.gd           # Lógica da partida
    ├── hud.gd             # Interface completa
    └── input_setup.gd     # Inputs P2
```

## 🚀 Como Rodar

1. Godot 4.x → Import Project → selecionar `project.godot`
2. F5 para rodar
3. P1=WASD+ESPAÇO | P2=Setas+J

## 📱 Gerar APK

1. Project → Export → Add → Android
2. Configurar export templates
3. Build → Export Project

## 🎯 Próximos Passos

- [ ] Fase 2: Arte (sprites, animações, efeitos)
- [ ] Fase 3: Multiplayer local (WiFi/Bluetooth)
- [ ] Fase 4: Conteúdo (times, estádios, torneio)
- [ ] IA básica (modo solo)
- [ ] Som (chute, torcida, UI)
