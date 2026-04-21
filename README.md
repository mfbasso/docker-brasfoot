# Docker Brasfoot 🐳 ⚽

Projeto open source para executar o **Brasfoot** em container, com acesso via navegador usando a base LinuxServer Selkies. 🖥️🌐

O objetivo é facilitar o uso remoto do jogo, sem precisar montar manualmente um ambiente gráfico Linux no host. 💻🕹️

---

## O que este projeto entrega

- Imagem Docker pronta para rodar Brasfoot no navegador. 🌐
- Persistência dos dados do jogo entre reinicializações do container. ♻️
- Persistência de _save_ e registro/licença no mesmo volume `/data`. 💾
- Build multi‑arch publicado no GHCR. 🧩
- Runtime do jogo em `/data`, inicializado a partir de `/opt/brasfoot` na primeira execução. ⚙️

Imagem publicada:

- `ghcr.io/mfbasso/docker-brasfoot:latest`

---

## Início rápido

Se você quer apenas subir o container e jogar, este é o caminho mais simples:

```bash
docker run --rm \
   --name=brasfoot \
   -e PUID=1000 \
   -e PGID=1000 \
   -e TZ=America/Sao_Paulo \
   -p 3000:3000 \
   -v ./data:/data \
   --shm-size="2gb" \
   ghcr.io/mfbasso/docker-brasfoot:latest
```

Depois disso, abra no navegador:

- `http://localhost:3000`

### O que esse comando faz

- Publica a interface web na porta `3000`. 🚪
- Persiste os dados do jogo, runtime e registro/licença em `./data`. 💾
- Define `PUID`, `PGID` e `TZ` para um runtime mais previsível. 🧩
- Reserva `2gb` de memória compartilhada (`shm`), o que ajuda na estabilidade de aplicações gráficas. 🖥️

---

## Exemplo com Docker Compose

Se preferir subir com Compose:

```yaml
services:
  brasfoot:
    image: ghcr.io/mfbasso/docker-brasfoot:latest
    container_name: brasfoot
    ports:
      - "3000:3000"
    environment:
      PUID: 1000
      PGID: 1000
      TZ: America/Sao_Paulo
    volumes:
      - ./data:/data
    shm_size: "2gb"
    restart: unless-stopped
```

Para iniciar:

```bash
docker compose up -d
```

Para parar:

```bash
docker compose down
```

---

## Primeiro uso, dados e registro

Este projeto usa um único ponto de persistência:

- `/data`

Na prática:

- `./data/brasfoot` guarda os arquivos do jogo usados em runtime. 🕹️
- `./data/register` guarda o estado de registro/licença (usado como `user.home` do Java). 🔐

Na primeira execução, se `/data/brasfoot/bf22-23.exe` ainda não existir, o container copia todo o conteúdo de `/opt/brasfoot` para `/data/brasfoot` e passa a executar a partir de lá. 📂➡️📂

### Sobre a licença do Brasfoot

Este repositório não distribui a licença do Brasfoot. O registro pode ser adquirido gratuitamente no site oficial:

- [https://www.brasfoot.com/registro-brasfoot-2022-2023.html](https://www.brasfoot.com/registro-brasfoot-2022-2023.html)

Se você pretende manter seu uso entre reinicializações, preserve o volume/pasta ligado em `./data`. 📦

---

## Configuração e variáveis de ambiente

O container já define alguns _defaults_ no build, como:

- `TITLE=Brasfoot`
- `NO_FULL=true`
- `NO_DECOR=true`
- `PIXELFLUX_WAYLAND=true`

No uso normal, as variáveis mais comuns continuam sendo:

- `PUID`
- `PGID`
- `TZ`

Você também pode sobrescrever as variáveis já definidas pela imagem e usar outras variáveis suportadas pela base LinuxServer Selkies.

Base utilizada:

- [https://github.com/linuxserver/docker-baseimage-selkies](https://github.com/linuxserver/docker-baseimage-selkies)

Isso é importante porque boa parte da camada de Wayland, streaming via navegador e comportamento do ambiente gráfico vem dessa imagem base. Se você já conhece o ecossistema Selkies, pode aproveitar as mesmas opções de customização aqui. 🧩🌐

---

## Créditos

Este projeto reutiliza como base a imagem `ghcr.io/linuxserver/baseimage-selkies:debiantrixie`.

Créditos ao trabalho da equipe **LinuxServer** e do projeto **Selkies**, que abstraem parte importante do acesso remoto via navegador e da camada gráfica usada por este container. 🙌

---

## Como funciona por baixo

Se você quer entender a estrutura interna do runtime, o fluxo é este:

1. O `Dockerfile` baixa o instalador oficial do Brasfoot durante o build. 📥
2. O instalador é extraído para `/opt/brasfoot`. 📂
3. No runtime, o script `/usr/bin/brasfoot` verifica `/data/brasfoot/bf22-23.exe`. 🧐
4. Se ainda não existir, copia todo o conteúdo de `/opt/brasfoot` para `/data/brasfoot`. 🔁
5. A execução acontece sempre a partir de `/data/brasfoot`. ▶️
6. _Save_ e registro/licença persistem sob `/data` (incluindo `/data/register`). 💾

Arquivos importantes do projeto:

- `Dockerfile`: imagem final baseada em Selkies. 🐳
- `scripts/generate_app_image.sh`: gera AppImage para release Linux. 🐧
- `root/usr/bin/brasfoot`: _wrapper_ de execução e _bootstrap_ do runtime em `/data`. ⚙️
- `root/defaults/autostart`: startup padrão para X11. 🖥️
- `root/defaults/autostart_wayland`: startup para Wayland. 🌐
- `.github/workflows/release.yml`: pipeline de release e publish no GHCR. 🔄

---

## Desenvolvimento local

Esta parte é mais útil para manutenção, debug e contribuições. 🛠️

### Pré‑requisitos

- Docker
- Acesso à internet para baixar o instalador oficial e imagens auxiliares

Não é necessário ter Java instalado no host para executar o container final. 🚫📦

### Gerar o AppImage (opcional, para release Linux)

```bash
bash scripts/generate_app_image.sh
```

Artefato esperado ao final:

- `root/root/bin/brasfoot.AppImage`

### Build da imagem

```bash
docker build -t docker-brasfoot .
```

Ou, se preferir, usando o `Makefile`:

```bash
make build
make run
```

Resumo dos alvos atuais:

- `make build`: executa `docker build -t docker-brasfoot .`
- `make run`: sobe o container local com os mesmos _mounts_ de persistência usados na documentação principal

---

## CI/CD

Workflow principal:

- `.github/workflows/release.yml`

Esse pipeline:

1. Gera uma versão UTC. 🕰️
2. Gera AppImage por arquitetura para anexar no release. 📦
3. Publica os artefatos de release. 📤
4. Gera e publica imagens Docker por arquitetura. 🐳
5. Publica o manifest multi‑arch final no GHCR. 🧩

---

## Troubleshooting

### O container subiu, mas eu não consigo acessar

Cheque primeiro:

1. Se a porta `3000` foi publicada. 🚪
2. Se você abriu `http://localhost:3000`. 🌐
3. Se o container está em execução. ▶️

Para ver logs:

```bash
docker logs brasfoot
```

### Quero evitar problemas de permissão no host

Se você estiver em macOS, Colima ou ambiente parecido, um volume nomeado pode ser mais seguro para `/data` do que um _bind mount_ direto.

Exemplo:

```bash
docker run --rm \
   --name=brasfoot \
   -e PUID=1000 \
   -e PGID=1000 \
   -e TZ=America/Sao_Paulo \
   -p 3000:3000 \
   -v brasfoot-data:/data \
   --shm-size="2gb" \
   ghcr.io/mfbasso/docker-brasfoot:latest
```

### Erro: `exec /init: no such file or directory`

**Causa comum:** artefatos sendo copiados para o caminho errado no contexto de build, como `root/bin` no repositório, o que pode sobrescrever `/bin` da imagem base.

**Estado correto deste projeto:**

- No repo: os arquivos de customização ficam sob `root/`.
- No container: eles são copiados para `/` via `COPY /root /`.

### O jogo não abre automaticamente no primeiro boot

Cheque:

1. Se a imagem certa foi puxada do GHCR. 🐳
2. Se o container está rodando com `--shm-size="2gb"`. 🖥️
3. Se o `DISPLAY` foi inicializado corretamente na sessão Selkies. 🖼️
4. Se `/data` permite escrita para os arquivos de runtime e registro. 🔐

Para inspecionar manualmente dentro do container:

```bash
docker run --rm -it --entrypoint sh docker-brasfoot
```

E testar o launcher:

```bash
/usr/bin/brasfoot
```

### Conferir o conteúdo da imagem

```bash
docker run --rm -it --entrypoint sh docker-brasfoot -lc 'ls -lah /opt/brasfoot /data /usr/bin/brasfoot'
```

---

## Contribuindo

Contribuições são bem‑vindas! 🙌

Você pode ajudar com:

- Melhorias na documentação
- Ajustes de compatibilidade
- Automação de build e release
- Troubleshooting em diferentes ambientes
- Revisões no fluxo de runtime e persistência

Se encontrar um problema, abra uma **issue** com o máximo de contexto possível. Se quiser propor uma melhoria, abra um **PR** com uma descrição objetiva do que mudou e como validar.

Para alterações maiores, vale alinhar a ideia antes para evitar retrabalho. 🤝

---

## Licença e direitos

Este repositório apenas empacota e orquestra a execução do Brasfoot em container; ele não substitui o software original. 🧩

O binário do Brasfoot é baixado da fonte oficial durante o build da imagem Docker e na geração opcional do AppImage para release. Respeite sempre os termos de uso e distribuição do software original. ✅
