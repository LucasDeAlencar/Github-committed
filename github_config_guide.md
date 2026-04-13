# Guia de Configuração do GitHub

## 1. Instalar o Git

### Debian/Ubuntu (apt)
```bash
sudo apt-get update
sudo apt-get install -y git
```

### openSUSE/SUSE (zypper)
```bash
sudo zypper install -y git
```

## 2. Configurar Identidade

```bash
git config --global user.name "Seu Nome"
git config --global user.email "seu.email@example.com"
```

## 3. Gerar Chave SSH

```bash
ssh-keygen -t ed25519 -C "seu.email@example.com"
```

## 4. Adicionar Chave ao SSH Agent

```bash
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519
```

## 5. Adicionar Chave ao GitHub

1. Copie a chave pública:
```bash
cat ~/.ssh/id_ed25519.pub
```

2. Acesse: https://github.com/settings/keys
3. Clique em "New SSH key" e cole o conteúdo

## 6. Testar Conexão

```bash
ssh -T git@github.com
```

Se tudo estiver correto, você verá: "Hi username! You've successfully authenticated..."

## 7. Clonar Repositório

```bash
git clone git@github.com:usuario/repositorio.git
```