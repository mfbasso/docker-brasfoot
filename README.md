# Docker Brasfoot

Container para executar o Brasfoot em ambiente LinuxServer Selkies (acesso via navegador), usando AppImage como artefato final de runtime.

## Uso recomendado (GHCR)

Imagem publicada:

- `ghcr.io/mfbasso/docker-brasfoot:latest`

### Run rapido

```bash
docker run --rm \
   --name=brasfoot \
   -e PUID=1000 \
   -e PGID=1000 \
   -e TZ=America/Sao_Paulo \
   -p 3000:3000 \
   --shm-size="1gb" \
   ghcr.io/mfbasso/docker-brasfoot:latest
```

## Visao geral do runtime

Fluxo AppImage-only:

1. O bootstrap baixa e extrai o instalador oficial do Brasfoot.
2. O bootstrap empacota o jogo em `brasfoot.AppImage`.
3. No build context, o artefato fica em `root/root/bin/brasfoot.AppImage`.
4. No container, ele fica em `/root/bin/brasfoot.AppImage`.
5. Os scripts de autostart executam esse AppImage diretamente.

## Estrutura do projeto

- `Dockerfile`: imagem final baseada em `ghcr.io/linuxserver/baseimage-selkies:debiantrixie`.
- `scripts/bootstrap.sh`: pipeline local/CI para gerar o AppImage.
- `root/defaults/autostart`: startup padrao (X11) executando o AppImage.
- `root/defaults/autostart_wayland`: startup Wayland executando o AppImage.
- `.github/workflows/release.yml`: workflow de build/release AppImage + publish no GHCR.

## Desenvolvimento local (manual)

Use esta secao apenas se quiser montar tudo localmente (debug/manutencao).

### Pre-requisitos

- Docker
- Acesso a internet (download do instalador do Brasfoot e imagens auxiliares)

Nao e necessario Java no host para executar o container final.

### 1) Gerar o AppImage (bootstrap)

```bash
sh scripts/bootstrap.sh
```

Ao final, o artefato esperado e:

- `root/root/bin/brasfoot.AppImage`

### 2) Build da imagem

```bash
docker build -t docker-brasfoot .
```

### 3) Rodar imagem local

```bash
docker run --rm \
  --name=brasfoot \
  -e PUID=1000 \
  -e PGID=1000 \
  -e TZ=America/Sao_Paulo \
  -p 3000:3000 \
  --shm-size="1gb" \
  docker-brasfoot
```

### Portas

- `3000`: interface principal no browser (Selkies).

### Memoria compartilhada

- `--shm-size="1gb"`: recomendado para apps graficos e estabilidade.

## Como funciona o runtime

- O `Dockerfile` copia `root/` para a raiz da imagem com `COPY /root /`.
- Por isso, qualquer arquivo em `root/root/bin` no repo passa a existir em `/root/bin` dentro do container.
- O autostart procura e executa:

```bash
/root/bin/brasfoot.AppImage
```

## CI/CD

Workflow: `.github/workflows/release.yml`

Jobs implementados:

1. **Prepare Version**
   - Gera versao UTC no formato `YYYYMMDD.hh.mm`.

2. **Build AppImage Artifact**
   - Executa `scripts/bootstrap.sh` por arquitetura.
   - Publica artifacts versionados para `amd64` e `arm64`.

3. **Publish Release Asset**
   - Cria release automatica na `main`.
   - Anexa `brasfoot-amd64.AppImage` e `brasfoot-arm64.AppImage`.

4. **Build And Push Docker Image**
   - Baixa o artifact AppImage correto para cada arquitetura.
   - Publica imagens temporarias por arquitetura.

5. **Publish Docker Manifest**
   - Cria o manifest multi-arch final no GHCR.
   - Publica as tags de versao e `latest` apontando para `amd64` e `arm64`.

## Troubleshooting

### Erro: `exec /init: no such file or directory`

Causa comum: artefatos sendo copiados para caminho errado no contexto (`root/bin` no repo), sobrescrevendo `/bin` da imagem.

Estado correto deste projeto:

- Artefato final no repo: `root/root/bin/brasfoot.AppImage`
- Artefato final no container: `/root/bin/brasfoot.AppImage`

### AppImage nao inicia no container

Cheque:

1. Se a imagem certa foi puxada do GHCR.
2. Se o container esta rodando com portas e `shm-size` esperados.
3. Se quiser validar localmente, confira `root/root/bin/brasfoot.AppImage` antes do `docker build`.
4. Logs do container:

```bash
docker logs brasfoot
```

Se voce entrar no shell do container e rodar o arquivo manualmente, use o modo sem FUSE:

```bash
APPIMAGE_EXTRACT_AND_RUN=1 /root/bin/brasfoot.AppImage --appimage-extract-and-run
```

Executar apenas `/root/bin/brasfoot.AppImage` pode falhar com `dlopen(): error loading libfuse.so.2` em imagens que nao possuem FUSE.
Se aparecer `bash: $'\r': command not found`, refaça o comando sem caracteres CRLF (copiar/colar com fim de linha Unix).

### Conferir conteudo da imagem

```bash
docker run --rm -it --entrypoint sh docker-brasfoot -lc 'ls -lah /root/bin'
```

## Fluxo recomendado de release

1. Fazer push para `main`.
2. Deixar o workflow publicar automaticamente:
   - AppImages `amd64` e `arm64` na Release
   - Docker image multi-arch no GHCR

## Limpeza de ambiente local

Se quiser limpar artefatos locais e imagem de teste:

```bash
docker rm -f brasfoot 2>/dev/null || true
docker rmi docker-brasfoot 2>/dev/null || true
```

## Licenca e direitos

Este repositorio empacota e orquestra a execucao. O binario do Brasfoot e baixado da fonte oficial durante o bootstrap. Respeite os termos de uso e distribuicao do software original.
