# Alterar Preço

App Android (Kotlin + Jetpack Compose) para consultar produtos e alterar preços da loja 291 na Retaguarda Americanas.

## Fluxo

1. Login com prontuário e senha.
2. Busca de produtos por EAN, descrição ou código SAP.
3. Seleção dos itens.
4. Edição do preço provisório, justificativa e opção "Exclusivo Cliente A".
5. Envio das alterações.

## Build

```bash
./gradlew :app:assembleRelease
```

O acesso ao servidor depende da rede interna da Americanas. Nenhuma credencial é armazenada no repositório.
