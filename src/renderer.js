document.addEventListener("DOMContentLoaded", () => {
    const menuItems = document.querySelectorAll(".nav-item");
    const pages = document.querySelectorAll(".tool-page");
    const pageTitle = document.getElementById("page-title");
    const pageDescription = document.getElementById("page-description");
    const consoleOutput = document.getElementById("console-output");
    const consoleStatus = document.getElementById("console-status");
    const terminalState = document.querySelector(".terminal-state");
    const inputForm = document.getElementById("console-input-form");
    const consoleInput = document.getElementById("console-input");
    const consoleSend = document.getElementById("console-send");
    const runner = window.batRunner;
    const terminal = document.querySelector(".terminal");
    const resizeHandle = document.getElementById("terminal-resize-handle");
    const content = document.querySelector(".content");
    const topbar = document.querySelector(".topbar");
    const minTerminalHeight = 150;

    function getMaxTerminalHeight() {
        // Deixa pelo menos 100 px para a lista, que continua rolavel.
        return Math.max(minTerminalHeight, content.clientHeight - topbar.offsetHeight - 130);
    }

    function setTerminalHeight(height, persist = true) {
        const boundedHeight = Math.min(getMaxTerminalHeight(), Math.max(minTerminalHeight, height));
        terminal.style.height = `${boundedHeight}px`;
        resizeHandle.setAttribute("aria-valuemax", String(getMaxTerminalHeight()));
        resizeHandle.setAttribute("aria-valuenow", String(Math.round(boundedHeight)));
        if (persist) {
            try { sessionStorage.setItem("windows-toolkit-console-height", String(boundedHeight)); } catch (_) { /* storage can be unavailable */ }
        }
    }

    let savedTerminalHeight = 205;
    try {
        const saved = Number(sessionStorage.getItem("windows-toolkit-console-height"));
        if (Number.isFinite(saved) && saved > 0) savedTerminalHeight = saved;
    } catch (_) { /* storage can be unavailable */ }
    setTerminalHeight(savedTerminalHeight, false);

    let dragStartY = 0;
    let dragStartHeight = 0;
    resizeHandle.addEventListener("pointerdown", (event) => {
        dragStartY = event.clientY;
        dragStartHeight = terminal.getBoundingClientRect().height;
        resizeHandle.classList.add("dragging");
        resizeHandle.setPointerCapture(event.pointerId);
        event.preventDefault();
    });
    resizeHandle.addEventListener("pointermove", (event) => {
        if (!resizeHandle.hasPointerCapture(event.pointerId)) return;
        setTerminalHeight(dragStartHeight + dragStartY - event.clientY);
    });
    function endResize(event) {
        if (resizeHandle.hasPointerCapture(event.pointerId)) resizeHandle.releasePointerCapture(event.pointerId);
        resizeHandle.classList.remove("dragging");
    }
    resizeHandle.addEventListener("pointerup", endResize);
    resizeHandle.addEventListener("pointercancel", endResize);
    resizeHandle.addEventListener("keydown", (event) => {
        if (event.key === "ArrowUp") {
            event.preventDefault();
            setTerminalHeight(terminal.getBoundingClientRect().height + 24);
        } else if (event.key === "ArrowDown") {
            event.preventDefault();
            setTerminalHeight(terminal.getBoundingClientRect().height - 24);
        } else if (event.key === "Home") {
            event.preventDefault();
            setTerminalHeight(minTerminalHeight);
        } else if (event.key === "End") {
            event.preventDefault();
            setTerminalHeight(getMaxTerminalHeight());
        }
    });
    window.addEventListener("resize", () => setTerminalHeight(terminal.getBoundingClientRect().height, false));

    const pageInfo = {
        aplicar: { title: "Aplicar scripts", description: "Aplicar políticas e configurações do Windows." },
        wallpaper: { title: "Definir papel de parede", description: "Escolher uma imagem, criar e aplicar o tema do Windows." },
        limpeza: { title: "Limpeza", description: "Executar rotinas de limpeza." },
        reparar: { title: "Reparar sistema", description: "Diagnosticar e reparar o Windows." },
        rede: { title: "Configuração de rede", description: "Redefinir a rede ou configurar IP e DNS por adaptador." },
        reverter: { title: "Reverter scripts", description: "Restaurar configurações anteriormente aplicadas." }
    };

    const scriptsPorCategoria = {
        aplicar: [
            "Aplicar scripts/1-Executar-todos-os-scripts.bat",
            "Aplicar scripts/2-bloquear-Wifi.bat",
            "Aplicar scripts/3-bloqueio-tela-personalizacao-e-tela-contas.bat",
            "Aplicar scripts/4-Bloquear-microsoft-store.bat",
            "Aplicar scripts/5-Aplicar-Control-de-senha.bat",
            "Aplicar scripts/6-Desativar-Arquivos-offline-e-backup.bat"
        ],
        wallpaper: ["Papel de parede/0-Definir-papel-de-parede-padrao.bat"],
        limpeza: ["lixeira limpar/ExecLimparLixeira.bat"],
        reparar: ["reparar sistema/RepararWindows.bat"],
        rede: ["config de rede/ipReset.bat", "config de rede/Configurar-IP.bat"],
        reverter: [
            "Reverter scripts/Reativar-Desbloquear-todos-scripts.bat",
            "Reverter scripts/1-Desbloquear-wifi.bat",
            "Reverter scripts/2-Desbloquear-tela-personalizacao-e-tela-contas.bat",
            "Reverter scripts/3-Desbloquear-microsoft-store.bat",
            "Reverter scripts/4-Desbloquear-controle-de-senhas.bat",
            "Reverter scripts/5-Reativar-Arquivos-offline.bat"
        ]
    };

    function showPage(pageName) {
        const info = pageInfo[pageName];
        if (!info) return;

        pages.forEach((page) => { page.hidden = page.dataset.page !== pageName; });
        menuItems.forEach((item) => {
            const active = item.dataset.target === pageName;
            item.classList.toggle("active", active);
            if (active) item.setAttribute("aria-current", "page");
            else item.removeAttribute("aria-current");
        });

        const activeMenuItem = document.querySelector(".nav-item.active");
        if (activeMenuItem && window.matchMedia("(max-width: 700px)").matches) {
            activeMenuItem.scrollIntoView({ block: "nearest", inline: "nearest" });
        }
        pageTitle.textContent = info.title;
        pageDescription.textContent = info.description;
        document.querySelector(".pages").scrollTop = 0;
    }

    function writeConsole(message, className = "") {
        const line = document.createElement("p");
        if (className) line.className = className;
        const prompt = document.createElement("span");
        prompt.className = "prompt";
        prompt.textContent = ">";
        line.append(prompt, document.createTextNode(` ${message}`));
        consoleOutput.append(line);
        consoleOutput.scrollTop = consoleOutput.scrollHeight;
    }

    if (runner && typeof runner.onOutput === "function") {
        runner.onOutput((output) => {
            const line = document.createElement("p");
            line.className = `terminal-output-line${output.stream === "stderr" ? " stderr" : ""}`;
            line.textContent = output.text;
            consoleOutput.append(line);
            consoleOutput.scrollTop = consoleOutput.scrollHeight;
        });
    }

    function getRunner() {
        return runner && typeof runner.execute === "function" ? runner.execute.bind(runner) : null;
    }

    let running = false;
    async function runScript(button, relativePath) {
        if (running) return;
        const run = getRunner();
        const scriptName = relativePath.split("/").pop();

        if (!run) {
            writeConsole("Abra o Windows Toolkit pelo Electron. No terminal, execute npm install e depois npm start.", "console-muted");
            consoleStatus.textContent = "INDISPONÍVEL";
            terminalState.lastChild.textContent = " Electron não configurado";
            return;
        }

        running = true;
        button.disabled = true;
        button.textContent = "Executando…";
        consoleInput.disabled = false;
        consoleSend.disabled = false;
        consoleStatus.textContent = "EXECUTANDO";
        terminalState.lastChild.textContent = ` Executando ${scriptName}`;
        writeConsole(`Iniciando ${scriptName}`);

        try {
            const result = await run(relativePath);
            if (result.code === 0) {
                writeConsole(`Concluído: ${scriptName}`);
                consoleStatus.textContent = "CONCLUÍDO";
                terminalState.lastChild.textContent = " Processo concluído";
            } else {
                writeConsole(`O BAT terminou com código ${result.code}: ${scriptName}`, "console-muted");
                consoleStatus.textContent = "FINALIZADO COM AVISO";
                terminalState.lastChild.textContent = " Processo finalizado";
            }
        } catch (error) {
            const message = error instanceof Error ? error.message : String(error);
            writeConsole(`Falha ao executar ${scriptName}: ${message}`, "console-muted");
            consoleStatus.textContent = "ERRO";
            terminalState.lastChild.textContent = " Falha na execução";
        } finally {
            running = false;
            consoleInput.disabled = true;
            consoleSend.disabled = true;
            button.disabled = false;
            button.textContent = "Executar";
        }
    }

    inputForm.addEventListener("submit", (event) => {
        event.preventDefault();
        if (!running || !runner || typeof runner.sendInput !== "function") return;
        const input = consoleInput.value;
        writeConsole(input);
        runner.sendInput(input);
        consoleInput.value = "";
        consoleInput.focus();
    });

    const openWallpaperFolderButton = document.getElementById("open-wallpaper-folder");
    openWallpaperFolderButton?.addEventListener("click", async () => {
        if (!runner || typeof runner.openWallpaperFolder !== "function") {
            writeConsole("Abra o Windows Toolkit pelo Electron para abrir a pasta wallpaper.", "console-muted");
            return;
        }
        try {
            await runner.openWallpaperFolder();
            writeConsole("Pasta wallpaper aberta.");
        } catch (error) {
            writeConsole(`Falha ao abrir a pasta wallpaper: ${error instanceof Error ? error.message : String(error)}`, "console-muted");
        }
    });

    document.querySelectorAll(".tool-page").forEach((page) => {
        const scripts = scriptsPorCategoria[page.dataset.page] || [];
        page.querySelectorAll(".tool-card button").forEach((button, index) => {
            const script = scripts[index];
            if (script) button.addEventListener("click", () => runScript(button, script));
        });
    });

    menuItems.forEach((item) => {
        item.addEventListener("click", (event) => {
            event.preventDefault();
            showPage(item.dataset.target);
        });
    });

    window.addEventListener("resize", () => {
        const activeMenuItem = document.querySelector(".nav-item.active");
        if (activeMenuItem && window.matchMedia("(max-width: 700px)").matches) {
            activeMenuItem.scrollIntoView({ block: "nearest", inline: "nearest" });
        }
    });

    showPage("aplicar");
});
