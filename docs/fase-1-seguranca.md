# Fase 1 - Seguranca do ambiente

## Estrutura adotada

```text
C:\Users\Joloano\OneDrive\Área de Trabalho\AusterMobileFaculdade\
  AusterAgX-Mobile-Reference\
  auster_agx_mobile\
```

## Repositorios

- `AusterAgX-Mobile-Reference`: clone usado somente para consulta e execucao local do backend.
- `auster_agx_mobile`: repositorio independente do app academico.

## Protecoes aplicadas na referencia

No clone `AusterAgX-Mobile-Reference`, o remote de push foi desativado:

```text
origin  https://github.com/AusterTec/AusterAgX.git (fetch)
origin  DISABLED_PUSH_REFERENCE_ONLY (push)
```

Tambem foi criado um hook local `.git/hooks/pre-push` que encerra qualquer tentativa de push.

## Regra operacional

Nao alterar o repositorio oficial em:

```text
C:\Users\Joloano\OneDrive\Área de Trabalho\Auster\AusterAgX
```

O app mobile deve evoluir somente dentro de:

```text
C:\Users\Joloano\OneDrive\Área de Trabalho\AusterMobileFaculdade\auster_agx_mobile
```
