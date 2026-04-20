# Docker Brasfoot

Projeto open source para executar o Brasfoot em container, com acesso pelo navegador usando a base LinuxServer Selkies.

O objetivo aqui e facilitar o uso remoto do jogo sem precisar montar manualmente um ambiente grafico Linux no host.

## O que este projeto entrega

- Imagem Docker pronta para rodar Brasfoot no navegador.
- Persistencia dos dados do jogo entre reinicializacoes do container.
- Persistencia do registro/licenca em volume separado.
- Build multi-arch publicado no GHCR.
- Runtime baseado em AppImage para simplificar distribuicao e execucao.

Imagem publicada:

- `ghcr.io/mfbasso/docker-brasfoot:latest`

## Inicio rapido

Se voce quer apenas subir o container e jogar, este e o caminho mais simples:

```bash
docker run --rm \
   --name=brasfoot \
   -e PUID=1000 \
   -e PGID=1000 \
   -e TZ=America/Sao_Paulo \
   -p 3000:3000 \
   -v ./data:/data \
   -v ./register:/config/.local/share/brasfoot \
   --shm-size="2gb" \
   ghcr.io/mfbasso/docker-brasfoot:latest
```

Depois disso, abra no navegador:

- `http://localhost:3000`

### O que esse comando faz

- Publica a interface web na porta `3000`.
- Persiste os dados do jogo em `./data`.
- Persiste registro/licenca em `./register`.
- Define `PUID`, `PGID` e `TZ` para um runtime mais previsivel.
- Reserva `2gb` de memoria compartilhada, o que ajuda na estabilidade de apps graficos.

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
      - ./register:/config/.local/share/brasfoot
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

## Primeiro uso, dados e registro

Este projeto separa os dados em dois pontos principais:

- `/data`: area onde o runtime do AppImage e extraido e reutilizado.
- `/config/.local/share/brasfoot`: area onde o Brasfoot salva dados de registro/licenca.

Na pratica:

- `./data` guarda o runtime persistente do jogo.
- `./register` guarda o estado de registro que voce nao quer perder ao recriar o container.

Na primeira execucao, ou quando o AppImage mudar, o runtime e reextraido automaticamente em `/data`.

### Sobre a licenca do Brasfoot

Este repositorio nao distribui a licenca do Brasfoot. O registro pode ser adquirido gratuitamente no site oficial:

- https://www.brasfoot.com/registro-brasfoot-2022-2023.html

Se voce pretende manter seu uso entre reinicializacoes, preserve o volume/pasta ligado em `./register`.

## Configuracao e variaveis de ambiente

O container ja define alguns defaults no build, como:

- `TITLE=Brasfoot`
- `NO_FULL=true`
- `NO_DECOR=true`
- `PIXELFLUX_WAYLAND=true`

No uso normal, as variaveis mais comuns continuam sendo:

- `PUID`
- `PGID`
- `TZ`

Voce tambem pode sobrescrever as variaveis ja definidas pela imagem e usar outras variaveis suportadas pela base LinuxServer Selkies.

Base utilizada:

- https://github.com/linuxserver/docker-baseimage-selkies

Isso e importante porque boa parte da camada de Wayland, browser streaming e comportamento do ambiente grafico vem dessa imagem base. Se voce ja conhece o ecossistema Selkies, pode aproveitar as mesmas opcoes de customizacao aqui.

## Creditos

Este projeto reutiliza como base a imagem `ghcr.io/linuxserver/baseimage-selkies:debiantrixie`.

Creditos ao trabalho do LinuxServer e do projeto Selkies, que abstraem uma parte importante do acesso remoto via navegador e da camada grafica usada por este container.

## Como funciona por baixo

Se voce quer entender a estrutura interna do runtime, o fluxo e este:

1. O bootstrap baixa o instalador oficial do Brasfoot.
2. O instalador e extraido.
3. O jogo e reempacotado em `brasfoot.AppImage`.
4. No repositorio, o artefato final fica em `root/root/bin/brasfoot.AppImage`.
5. No container, ele passa a existir em `/root/bin/brasfoot.AppImage`.
6. O autostart extrai esse AppImage para `/data` e executa o runtime persistente a partir dali.

Arquivos importantes do projeto:

- `Dockerfile`: imagem final baseada em Selkies.
- `scripts/bootstrap.sh`: gera o AppImage localmente ou em CI.
- `root/defaults/autostart`: startup padrao para X11.
- `root/defaults/autostart_wayland`: startup para Wayland.
- `.github/workflows/release.yml`: pipeline de release e publish no GHCR.

## Desenvolvimento local

Esta parte e mais util para manutencao, debug e contribuicoes.

### Pre-requisitos

- Docker
- Acesso a internet para baixar o instalador oficial e imagens auxiliares

Nao e necessario ter Java instalado no host para executar o container final.

### Gerar o AppImage

```bash
sh scripts/bootstrap.sh
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
- `make run`: sobe o container local com os mesmos mounts de persistencia usados na documentacao principal

## CI/CD

Workflow principal:

- `.github/workflows/release.yml`

Esse pipeline:

1. Gera uma versao UTC.
2. Builda o AppImage por arquitetura.
3. Publica os artifacts de release.
4. Gera e publica imagens Docker por arquitetura.
5. Publica o manifest multi-arch final no GHCR.

## Troubleshooting

### O container subiu, mas eu nao consigo acessar

Cheque primeiro:

1. Se a porta `3000` foi publicada.
2. Se voce abriu `http://localhost:3000`.
3. Se o container esta em execucao.

Para ver logs:

```bash
docker logs brasfoot
```

### Quero evitar problemas de permissao no host

Se voce estiver em macOS, Colima ou ambiente parecido, um volume nomeado pode ser mais seguro para `/data` do que bind mount direto.

Exemplo:

```bash
docker run --rm \
   --name=brasfoot \
   -e PUID=1000 \
   -e PGID=1000 \
   -e TZ=America/Sao_Paulo \
   -p 3000:3000 \
   -v brasfoot-data:/data \
   -v ./register:/config/.local/share/brasfoot \
   --shm-size="2gb" \
   ghcr.io/mfbasso/docker-brasfoot:latest
```

### Erro: `exec /init: no such file or directory`

Causa comum: artefatos sendo copiados para o caminho errado no contexto de build, como `root/bin` no repo, o que pode sobrescrever `/bin` da imagem base.

Estado correto deste projeto:

- No repo: `root/root/bin/brasfoot.AppImage`
- No container: `/root/bin/brasfoot.AppImage`

### AppImage nao inicia no container

Cheque:

1. Se a imagem certa foi puxada do GHCR.
2. Se o container esta rodando com `--shm-size="2gb"`.
3. Se, em build local, `root/root/bin/brasfoot.AppImage` realmente existe antes do `docker build`.

Se precisar testar manualmente sem FUSE:

```bash
APPIMAGE_EXTRACT_AND_RUN=1 /root/bin/brasfoot.AppImage --appimage-extract-and-run
```

Para reproduzir exatamente o startup com persistencia:

```bash
/data/squashfs-root/AppRun
```

Executar apenas `/root/bin/brasfoot.AppImage` pode falhar com `dlopen(): error loading libfuse.so.2` em imagens sem FUSE.

Se aparecer `bash: $'\r': command not found`, refaca o comando sem caracteres CRLF.

### Conferir o conteudo da imagem

```bash
docker run --rm -it --entrypoint sh docker-brasfoot -lc 'ls -lah /root/bin'
```

## Contribuindo

Contribuicoes sao bem-vindas.

Voce pode ajudar com:

- melhorias de documentacao
- ajustes de compatibilidade
- automacao de build e release
- troubleshooting em diferentes ambientes
- revisoes no fluxo de runtime e persistencia

Se encontrar problema, abra uma issue com o maximo de contexto possivel. Se quiser propor uma melhoria, abra um PR com uma descricao objetiva do que mudou e como validar.

Para alteracoes maiores, vale alinhar a ideia antes para evitar retrabalho.

## Licenca e direitos

Este repositorio empacota e orquestra a execucao do Brasfoot em container, mas nao substitui o software original.

O binario do Brasfoot e baixado da fonte oficial durante o bootstrap. Respeite os termos de uso e distribuicao do software original.
