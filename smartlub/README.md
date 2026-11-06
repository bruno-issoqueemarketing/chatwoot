# Smartlub Chat — customizações

Fork do Chatwoot com personalizações da operação. Branch de trabalho: `custom`
(baseada na tag oficial `v4.19.1`). Todo código alterado é marcado com `[custom]`.

## Fluxo de entrega (na VPS)

```bash
cd /opt/chatwoot-src
git pull
smartlub/build.sh v4.19.1-cN                      # gera a imagem smartlub-chatwoot:v4.19.1-cN
smartlub/deploy.sh smartlub-chatwoot:v4.19.1-cN   # backup (banco + config) e deploy
```

## Restauração

```bash
smartlub/rollback.sh                 # volta para a imagem anterior (último backup)
smartlub/rollback.sh <id>            # usa um backup específico (/opt/chatwoot/backups/<id>)
smartlub/rollback.sh <id> --restore-db  # também restaura o banco (perde dados posteriores!)
```

## Customizações

| # | Descrição |
|---|-----------|
| c1 | Nome da instalação "Smartlub Chat" (banco + textos da interface) |
