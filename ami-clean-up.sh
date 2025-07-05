#!/bin/bash

DRY_RUN=true

# --- Parse argumentos
for arg in "$@"; do
  case $arg in
    --dry-run=*)
      DRY_RUN="${arg#*=}"
      shift
      ;;
    *)
      echo "Uso: $0 [--dry-run=true|false]"
      exit 1
      ;;
  esac
done

echo "🔍 Coletando AMIs criadas pelo usuário..."
AMIS=$(aws ec2 describe-images --owners self \
  --query "Images[*].{ID:ImageId,Name:Name,CreationDate:CreationDate}" \
  --output json)

USED_AMIS=$(aws ec2 describe-instances \
  --query "Reservations[*].Instances[*].ImageId" \
  --output text | sort | uniq)

echo "📋 Verificando AMIs não utilizadas..."
echo "$AMIS" | jq -c '.[]' | while read -r ami_info; do
  AMI_ID=$(echo "$ami_info" | jq -r '.ID')
  AMI_NAME=$(echo "$ami_info" | jq -r '.Name')
  CREATION_DATE=$(echo "$ami_info" | jq -r '.CreationDate')

  if echo "$USED_AMIS" | grep -q "$AMI_ID"; then
    continue
  fi

  echo ""
  echo "⚠️  AMI não utilizada detectada:"
  echo "  🔹 ID: $AMI_ID"
  echo "  🔹 Nome: $AMI_NAME"
  echo "  🔹 Criada em: $CREATION_DATE"

  if [[ "$DRY_RUN" == "true" ]]; then
    echo "  🧪 Dry-run ativado: AMI **não será deletada**"
  else
    echo "  🗑️  Deletando AMI $AMI_ID..."
    aws ec2 deregister-image --image-id "$AMI_ID"
  fi

  echo "  🔍 Buscando snapshots vinculados..."
  SNAPSHOTS=$(aws ec2 describe-images --image-ids "$AMI_ID" \
    --query "Images[*].BlockDeviceMappings[*].Ebs.SnapshotId" \
    --output text)

  for SNAPSHOT_ID in $SNAPSHOTS; do
    if [[ -n "$SNAPSHOT_ID" ]]; then
      if [[ "$DRY_RUN" == "true" ]]; then
        echo "    🧪 Dry-run: Snapshot $SNAPSHOT_ID **não será deletado**"
      else
        echo "    🗑️  Deletando snapshot $SNAPSHOT_ID..."
        aws ec2 delete-snapshot --snapshot-id "$SNAPSHOT_ID"
      fi
    fi
  done
done

echo ""
if [[ "$DRY_RUN" == "true" ]]; then
  echo "✅ Execução finalizada em modo dry-run. Nenhum recurso foi deletado."
else
  echo "✅ Execução finalizada. AMIs e snapshots deletados."
fi

