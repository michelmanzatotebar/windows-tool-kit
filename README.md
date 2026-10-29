# Windows Toolkit

Aplicativo desktop feito com Electron para executar as ferramentas BAT deste projeto.

## Pré-requisitos

- Windows 10 ou Windows 11.
- Node.js instalado, com o npm incluído. A versão LTS atual do Node.js é recomendada.
- Acesso à internet na primeira instalação das dependências.

Não é necessário instalar o Electron globalmente. Ele já está declarado como dependência do projeto no `package.json` e será instalado junto com as demais dependências.

## Instalar depois de clonar

Abra um terminal na pasta do projeto, onde está o `package.json`, e execute:

```powershell
npm.cmd install
```

Esse comando instala o Electron e as dependências listadas no projeto. O `package-lock.json` registra as versões para manter as instalações consistentes.

## Iniciar o aplicativo

Na mesma pasta, execute:

```powershell
npm.cmd start
```

O Electron abre a interface. Não abra `src/index.html` diretamente no navegador: nesse modo, a interface não tem acesso à ponte que executa os BATs.

No Prompt de Comando, os comandos também podem ser executados como `npm install` e `npm start`. No PowerShell deste ambiente, use `npm.cmd` para evitar o bloqueio de scripts do arquivo `npm.ps1`.

## Executar ferramentas que exigem administrador

O comando `npm.cmd start` solicita a permissão de administrador para o próprio aplicativo. Confirme o aviso do Windows; assim, as BATs que verificam privilégios já iniciam elevadas e a saída permanece conectada ao console do aplicativo.

As BATs que não exigem administrador também podem ser iniciadas normalmente pelo aplicativo.

## Comandos resumidos

```powershell
# Instalar dependências (necessário após clonar ou quando elas mudarem)
npm.cmd install

# Abrir o Windows Toolkit
npm.cmd start
```


## Configuração de rede

Na seção **Configuração de rede**, a ferramenta **Configurar IP e DNS do adaptador** lista as placas de rede e permite definir IP fixo ou habilitar DHCP para IP, DNS ou ambos. Cada alteração pede confirmação e afeta somente o adaptador selecionado. Em uma placa Wi-Fi, a configuração fixa vale para essa placa em qualquer rede Wi-Fi conectada.

A opção **Definir papel de parede** fica separada dos scripts de bloqueio e do processamento em lote. Nela, use **Abrir pasta wallpaper** para adicionar imagens antes de executar o script.

## Criar os arquivos para distribuir

Depois de instalar as dependências com `npm.cmd install`, execute:

```powershell
npm.cmd run dist
```

O Electron Builder cria os dois arquivos de 64 bits na pasta `artifacts`:

- `Windows Toolkit-1.0.0-Setup.exe`: instalador do Windows.
- `Windows Toolkit-1.0.0-Portable.exe`: versão portátil, sem instalação.

Os dois aplicativos pedem permissão de administrador ao iniciar para que as ferramentas continuem executando as BATs elevadas pelo console do programa. Para publicar, crie um Release no GitHub e anexe os dois executáveis gerados em `artifacts`.
