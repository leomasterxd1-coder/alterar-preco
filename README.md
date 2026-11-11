# Alterar Preço

App Flutter para consultar produtos e alterar preços da loja 291 na Retaguarda Americanas.

## Fluxo

1. Login com prontuário e senha.
2. Busca por EAN, descrição ou código SAP, com leitor de código de barras.
3. Seleção dos itens.
4. Edição do preço provisório, justificativa e opção "Exclusivo Cliente A".
5. Envio das alterações.

## Build

```bash
flutter pub get
flutter build apk --release --target-platform android-arm64
```

O acesso ao servidor depende da rede interna da Americanas. Nenhuma credencial é armazenada no repositório.
