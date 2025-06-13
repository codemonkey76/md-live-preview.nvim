# ✨ md-live-preview.nvim

A blazing-fast live Markdown preview plugin for Neovim, powered by a Rust backend.

Integrates seamlessly with a companion server ([markdown-live-preview](https://github.com/codemonkey76/markdown-live-preview)) to deliver GitHub-flavored Markdown (GFM) previews in your browser, updated in real time as you type.

> [!TIP]
> This plugin is a frontend for a TCP-connected Rust app that renders your Markdown into HTML using Comrak and serves it via Axum.

---

## 🔥 Features

| Feature                  | Status | Description                                     |
|--------------------------|--------|-------------------------------------------------|
| Live buffer preview      | ✅     | Updates instantly as you type                  |
| Cursor tracking          | ✅     | Cursor position sent to backend in real-time   |
| Incremental updates      | ✅     | Sends only changed lines to backend            |
| Cross-platform TCP       | ✅     | Uses `vim.loop` — no LuaSocket required        |
| Filetype-scoped autocommands | ✅ | Only runs in `markdown` buffers               |
| Rust server integration  | ✅     | Starts preview server and connects automatically |

---

## 🚀 Quickstart

### 📦 Requirements

- Neovim 0.9+
- Rust installed with [markdown-live-preview](https://github.com/codemonkey76/markdown-live-preview) built and available in `$PATH`

### 🧑‍💻 Installation (Lazy.nvim)

```lua
{
  dir = "~/dev/md-live-preview.nvim",
  opts = {
    verbose = true, -- optional: logs connection/debug info
  },
}
```

> [!NOTE]
> This plugin is not yet plublished on a public registry - use `dir =` or a GIT URL.


### 📚 Usage

#### Start live preview

```vim
:MDPreviewStart
```

This will:

- Start the Rust backend via `jobstart()`
- Open your browser to [http://localhost:3000](http://localhost:3000)
- Begin sending buffer/cursor updates automatically

#### Stop live preview

```vim
:MDPreviewStop
```

Stops the Rust process and disables autocommands.

### 🛠 Configuration

Set options via `opts = {}` in your plugin spec:

| Option | Type | Default | Description |
|---|---|---|---|
| verbose | boolean | false | Show debug info with `vim.notify()` |
| cmd | string | "markdown-preview-server" | Binary to launch server |

### 🧠 How it works

```text
[ Neovim plugin ]
    │
    ├── :MDPreviewStart → starts Rust server
    ├── TextChanged → sends only changed lines
    ├── CursorMoved → sends cursor position
    │
    ▼
[ Rust TCP server (127.0.0.1:3001) ]
    ▼
[ HTML preview (http://localhost:3000) ]
```

### 🔌 Integration Notes

- Plugin uses `vim.loop` for portability — no need for `lua-socket`
- Server must be in `$PATH` or configured via `opts.cmd`
- All messages are newline-delimited JSON over TCP

### 🤖 Dev Features (planned)

- [ ] Cursor highlight in browser
- [ ] WebSocket-based live reload
- [ ] Click to scroll sync
- [ ] Buffer-specific preview windows

### 📜 License

MIT © Shane Poppleton

### 🤝 Related Projects

- [markdown-live-preview](https://github.com/codemonkey76/markdown-live-preview) — the backend rendering engine
- [Comrak](https://github.com/kivikakk/comrak) — CommonMark + GFM parser
