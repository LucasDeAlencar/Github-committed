# GitHub Commited

É um aplicativo para facilitar a realização de commit no GitHub em sistemas Linux.

## 📋 Descrição

Este script automatiza o processo de commit e push para o GitHub através de uma interface gráfica simples, eliminando a necessidade de usar comandos Git no terminal.

## 🖥️ Compatibilidade

** ⚠️ IMPORTANTE:** Este script funciona apenas em sistemas baseados em APT e ZYPPER (Debian e derivados, bem como sistemas SUSE):
- Ubuntu
- Debian
- Linux Mint
- Elementary OS
- Pop!_OS
- Opensuse
- Outros derivados do Debian

## 📦 Pré-requisitos

- Sistema Linux baseado em APT
- Git instalado
- Chave SSH configurada no GitHub
- Conexão com a internet

## 🔧 Instalação

1. Baixe o script
2. Torne-o executável:
```bash
chmod +x github-commit.sh
```
3. Execute:
```bash
./github-commit.sh
```

O script instalará automaticamente o Zenity se necessário.

## 📖 Como usar

1. **Execute o script**
2. **Selecione o diretório** do seu projeto
3. **Preencha os dados:**
   - Usuário GitHub
   - Nome do repositório
   - Mensagem do commit (opcional)
4. **Aguarde o processo** ser concluído

## 🔑 Configuração SSH

Certifique-se de ter uma chave SSH configurada no GitHub:

```bash
# Gerar chave SSH (se não tiver)
ssh-keygen -t ed25519 -C "seu-email@exemplo.com"

# Adicionar ao ssh-agent
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519

# Copiar chave pública para adicionar no GitHub
cat ~/.ssh/id_ed25519.pub
```
## ⚠️ Solução de Problemas

### Erro de autenticação SSH
- Verifique se sua chave SSH está configurada no GitHub
- Teste a conexão: `ssh -T git@github.com`

### Zenity não encontrado
- O script instala automaticamente em sistemas APT
- Para outros sistemas: instale manualmente o Zenity

### Repositório já existe
- O script sobrescreve a configuração do repositório remoto
- Certifique-se de que o repositório existe no GitHub
