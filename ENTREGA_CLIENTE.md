# Entrega ao cliente — SIS Icpro (Web/PWA + Android)

Este arquivo é para você colocar no **Google Drive** junto com o APK e enviar ao cliente.

---

## 1) O que vai no Drive

- `app-release.apk` (Android)
- Este arquivo: `ENTREGA_CLIENTE.md`

Opcional:
- `app-release.aab` (Play Store) — só se for publicar na loja.

---

## 2) Como colocar o APK no Google Drive (PC)

1. Abra o Google Drive no navegador.
2. Clique em **Novo** → **Upload de arquivo**.
3. Selecione o arquivo:
   - `app_escola/build/app/outputs/flutter-apk/app-release.apk`
4. Aguarde terminar o upload.
5. Clique com o botão direito no APK → **Compartilhar**.
6. Em **Acesso geral**, selecione **Qualquer pessoa com o link** (ou adicione o e-mail do cliente).
7. Clique em **Copiar link** e envie para o cliente.

---

## 3) Acesso no iPhone/iPad (iOS) — Web App (PWA)

Link do sistema:
- https://app-escola-fda78.web.app

Para instalar como “app” no iPhone/iPad:

1. Abra o link no **Safari** (importante: Safari, não Chrome).
2. Toque no botão **Compartilhar**.
3. Toque em **Adicionar à Tela de Início**.
4. Confirme o nome e toque em **Adicionar**.
5. Abra o sistema pelo ícone que apareceu na tela inicial.

---

## 4) Instalar no Android (APK)

1. Baixe o arquivo **`app-release.apk`** do Drive no celular Android.
2. Abra o arquivo baixado para instalar.
3. Se aparecer bloqueio de segurança:
   - toque em **Configurações** no aviso
   - habilite **Permitir desta fonte** (Chrome/Drive/Files)
   - volte e tente instalar novamente.

Depois de instalado, o app aparece na lista de aplicativos.

---

## 5) Login (contas)

O sistema usa login com as contas configuradas no Firebase (Administrador e Colaboradores).
Se o cliente não conseguir entrar, confirmar:
- e-mail/senha corretos
- e os documentos em `usuarios/{uid}` com `role` (`admin`/`colab`).

