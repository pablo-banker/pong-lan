# Pong LAN

Pong 2D desenvolvido com **Godot 4 e GDScript**, com partidas para dois jogadores no mesmo teclado ou em dispositivos conectados à mesma rede local. Visual minimalista, raquetes com glow e trilhas diferentes para menu e partida.

## Modos de jogo

| Modo | Desktop | Web |
| --- | --- | --- |
| Dois jogadores no mesmo teclado | Sim | Sim |
| Multiplayer em rede local (LAN) | Sim | Não |

Na versão Web, o botão **Jogar** inicia diretamente uma partida no mesmo teclado. No desktop, ele abre a seleção de modo.

A LAN não exige servidor contratado: um jogador cria a sala e seu computador atua como host. Os dois dispositivos precisam conseguir se comunicar na mesma rede. Se o host sair, a conexão termina.

## Funcionalidades

- Partidas até 5 pontos, com saque automático após cada ponto.
- Controles reconfiguráveis e salvos entre sessões.
- Indicadores de teclas (KBDs) com destaque ao pressionar.
- Bola, raquetes e placar sincronizados na LAN.
- Suavização de movimento no convidado.
- Pausa compartilhada e contagem de 3, 2, 1 para retomar.
- Configurações acessíveis durante a pausa.
- Confirmação antes de abandonar uma partida.
- Sons de interface, paredes, raquetes, pontos e contagem.
- Música de menu e partida com transição suave.
- Partida automática no fundo do menu, controlada por um bot.

## Controles

| Ação | Tecla padrão |
| --- | --- |
| Jogador 1: subir / descer | W / S |
| Jogador 2: subir / descer | Seta para cima / seta para baixo |
| Pausar / solicitar retomada | Esc |
| Reiniciar após o fim da partida | Enter |

Os movimentos podem ser alterados em **Configurações**. Esc e Enter permanecem reservados.

Na LAN, cada dispositivo usa os binds do **jogador 1**: o host controla a esquerda e o convidado controla a direita. Os KBDs exibem as teclas configuradas no dispositivo.

Na pausa LAN, quem pausou pode retomar. Ao encerrar a partida, o host pode iniciar outra com Enter.

## Executar no editor

1. Instale a versão da Godot 4 compatível com o projeto. Prefira a mesma versão utilizada no desenvolvimento.
2. Importe o arquivo `project.godot` pelo gerenciador de projetos.
3. Aguarde a importação dos recursos.
4. Pressione **F5** para iniciar pelo menu principal.

O projeto usa o renderizador **Compatibility** e resolução lógica de **1152 × 648**. Para preservar o enquadramento, configure Stretch Mode como `canvas_items` e Stretch Aspect como `keep`.

## Jogar em LAN

1. Abra a mesma versão do jogo nos dois dispositivos.
2. No primeiro, selecione **Jogar → Criar sala LAN**.
3. Copie o IP local exibido pelo host.
4. No segundo, selecione **Jogar → Entrar na sala LAN** e informe esse IP.
5. Aguarde a conexão e o carregamento da partida.

A conexão usa **ENet sobre UDP, porta 7000**, com um convidado por sala. Se necessário, permita o jogo no firewall. Redes de convidados podem impedir a comunicação entre os dispositivos.

Para testar duas instâncias no mesmo computador, use `127.0.0.1`. Em computadores diferentes, use o IP da rede local do host, por exemplo `192.168.1.10`.

Se aparecer mais de um IP no painel, escolha o da interface conectada à mesma rede do convidado.

## Como o multiplayer funciona

O host calcula o movimento das raquetes, a física da bola, colisões e pontos. O convidado envia seus comandos e recebe o estado da partida. A posição recebida é suavizada para reduzir saltos visuais.

A pausa e a retomada são coordenadas pelo host. A conexão permanece ativa enquanto a simulação está parada.

A versão Web não utiliza a LAN: o navegador não suporta o transporte ENet usado pelo projeto. Multiplayer no navegador exigiria uma adaptação para WebSocket ou WebRTC.

## Áudio

O gerenciador `Audio` é um Autoload baseado em cena, para manter as referências dos arquivos e a reprodução entre telas.

| Bus | Uso |
| --- | --- |
| Master | Saída geral |
| Musica | Trilhas do menu e da partida |
| Efeitos | Impactos, pontos e contagem |
| Interface | Hover e clique dos botões |

Os buses `Musica`, `Efeitos` e `Interface` enviam para `Master`. Salve o layout e configure-o como Default Bus Layout do projeto.

Na exportação Web, os players criados pelo gerenciador usam o modo **Stream**. O navegador pode exigir uma interação do usuário antes de liberar o áudio.

## Exportação

Instale os **Export Templates** correspondentes à versão da Godot em **Editor → Manage Export Templates**. Exporte as builds para pastas fora do projeto.

### Windows

1. Abra **Projeto → Exportar** e adicione o preset **Windows Desktop**.
2. Selecione a arquitetura `x86_64`.
3. Exporte como `PongLAN.exe`, com **Export With Debug** desativado para distribuição.
4. Se o PCK estiver separado, distribua o `.exe` e o `.pck` juntos, incluindo quaisquer dependências geradas.

É possível exportar pelo macOS; para validar a build Windows, execute-a em um ambiente Windows.

### Web

1. Adicione o preset **Web**.
2. Mantenha o renderizador Compatibility.
3. Desative **Use Threads / Thread Support** nesta configuração.
4. Exporte como `index.html`, com **Export With Debug** desativado para distribuição.
5. Mantenha todos os arquivos gerados na mesma pasta.

Para testar localmente, abra o terminal na pasta exportada:

```bash
python3 -m http.server 8000
```

Acesse **http://localhost:8000**. Não abra o HTML diretamente pelo Finder. Se a exportação tiver outro nome, abra o arquivo HTML correspondente na listagem do servidor.

## Créditos de áudio

Arquivos selecionados para o projeto:

| Uso | Arquivo | Autor / pacote |
| --- | --- | --- |
| Hover | `select_001.ogg` | Kenney — Interface Sounds |
| Clique | `click_001.ogg` | Kenney — Interface Sounds |
| Ponto | `confirmation_001.ogg` | Kenney — Interface Sounds |
| Parede | `pepSound1.ogg` | Kenney — Digital Audio |
| Raquete | `pepSound3.ogg` | Kenney — Digital Audio |
| Contagem | `tone1.ogg` | Kenney — Digital Audio |
| Música de menu | `neon_sign_circuit_bpm145.ogg` | MintoDog — Neon Sign Circuit |
| Música de partida | `neon_sign_circuit_climax_bpm160.ogg` | MintoDog — Neon Sign Circuit |

- [Kenney — Interface Sounds](https://kenney.nl/assets/interface-sounds)
- [Kenney — Digital Audio](https://kenney.nl/assets/digital-audio)
- [MintoDog — Neon Sign Circuit](https://opengameart.org/content/neon-sign-circuit)

Esses recursos são publicados sob [CC0 1.0](https://creativecommons.org/publicdomain/zero/1.0/). A licença dos áudios não define a licença do código do projeto.
