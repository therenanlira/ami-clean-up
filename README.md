# AMI Clean Up

Script Bash para identificar e remover AMIs (Amazon Machine Images) não utilizadas na sua conta AWS, incluindo snapshots vinculados.

## Pré-requisitos

- AWS CLI configurado
- jq instalado

## Uso

```bash
./ami-clean-up.sh [--dry-run=true|false]
```

- `--dry-run=true` (padrão): Apenas exibe as AMIs e snapshots que seriam removidos, sem deletar nada.
- `--dry-run=false`: Remove as AMIs não utilizadas e seus snapshots vinculados.

## O que o script faz

1. Lista todas as AMIs criadas pelo usuário.
2. Verifica quais AMIs não estão em uso por instâncias EC2.
3. Exibe as AMIs não utilizadas e, se não estiver em modo dry-run, as deleta.
4. Busca e remove snapshots vinculados às AMIs deletadas.

## Aviso

**Use com cautela!** Certifique-se de que as AMIs não estão sendo usadas antes de removê-las.
