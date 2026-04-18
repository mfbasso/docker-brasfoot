# Docker Brasfoot

Container para executar o Brasfoot em ambiente LinuxServer Selkies (acesso via navegador), usando **AppImage** como artefato final de runtime.

## Visao geral

Este projeto segue um fluxo AppImage-only:

1. O script `scripts/bootstrap.sh` baixa e extrai o instalador oficial do Brasfoot.
2. O mesmo script empacota o jogo em `brasfoot.AppImage`.
3. O artefato final e colocado no contexto da imagem em `root/root/bin/brasfoot.AppImage`.
4. No container, ele fica disponivel em `/root/bin/brasfoot.AppImage`.
5. Os scripts de autostart executam o AppImage diretamente.

## Estrutura do projeto

- `Dockerfile`: imagem final baseada em `ghcr.io/linuxserver/baseimage-selkies:debiantrixie`.
- `scripts/bootstrap.sh`: pipeline local/CI para gerar o AppImage.
- `root/defaults/autostart`: startup padrao (X11) executando o AppImage.
- `root/defaults/autostart_wayland`: startup Wayland executando o AppImage.
- `.github/workflows/release.yml`: workflow de build/release AppImage + publish no GHCR.

## Pre-requisitos

Para gerar artefatos localmente:

- Docker
- Acesso a internet (download do instalador do Brasfoot e imagens auxiliares)

Nao e necessario Java no host para executar o container final.

## Quick start

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

### 3) Rodar o container

Comando base (equivalente ao seu teste):

```bash
docker run --rm \
  --name=brasfoot \
  -e PUID=1000 \
  -e PGID=1000 \
  -e TZ=America/Sao_Paulo \
  -p 3000:3000 \
  -p 3001:3001 \
  --shm-size="1gb" \
  docker-brasfoot
```

Com persistencia em `/config` (recomendado):

```bash
docker run --rm \
  --name=brasfoot \
  -e PUID=1000 \
  -e PGID=1000 \
  -e TZ=America/Sao_Paulo \
  -p 3000:3000 \
  -p 3001:3001 \
  -v /path/to/config:/config \
  --shm-size="1gb" \
  --restart unless-stopped \
  docker-brasfoot
```

## Variaveis e parametros

### Variaveis de ambiente

- `PUID`: UID do usuario no host.
- `PGID`: GID do grupo no host.
- `TZ`: timezone do container.

### Portas

- `3000`: interface principal no browser (Selkies).
- `3001`: porta auxiliar usada pelo stack da imagem base.

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

1. **Build AppImage Artifact**
   - Executa `scripts/bootstrap.sh`.
   - Publica artifact `brasfoot-appimage`.

2. **Publish Release Asset**
   - Em tags `v*`, publica `brasfoot.AppImage` na release do GitHub.

3. **Build And Push Docker Image**
   - Baixa o artifact AppImage.
   - Builda e publica imagem no GHCR (`ghcr.io/<owner>/<repo>`).

## Troubleshooting

### Erro: `exec /init: no such file or directory`

Causa comum: artefatos sendo copiados para caminho errado no contexto (`root/bin` no repo), sobrescrevendo `/bin` da imagem.

Estado correto deste projeto:

- Artefato final no repo: `root/root/bin/brasfoot.AppImage`
- Artefato final no container: `/root/bin/brasfoot.AppImage`

### AppImage nao inicia no container

Cheque:

1. Se o bootstrap foi executado antes do `docker build`.
2. Se o arquivo existe no contexto: `root/root/bin/brasfoot.AppImage`.
3. Se o build usou a versao mais recente do contexto.
4. Logs do container:

```bash
docker logs brasfoot
```

### Conferir conteudo da imagem

```bash
docker run --rm -it --entrypoint sh docker-brasfoot -lc 'ls -lah /root/bin'
```

## Fluxo recomendado de release

1. Rodar bootstrap localmente ou no CI.
2. Validar build da imagem.
3. Criar tag semantica (`vX.Y.Z`).
4. Deixar o workflow publicar:
   - AppImage na Release
   - Docker image no GHCR

## Limpeza de ambiente local

Se quiser limpar artefatos locais e imagem de teste:

```bash
docker rm -f brasfoot 2>/dev/null || true
docker rmi docker-brasfoot 2>/dev/null || true
```

## Licenca e direitos

Este repositorio empacota e orquestra a execucao. O binario do Brasfoot e baixado da fonte oficial durante o bootstrap. Respeite os termos de uso e distribuicao do software original.
