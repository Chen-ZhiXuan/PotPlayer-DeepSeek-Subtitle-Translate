# PotPlayer DeepSeek Subtitle Translate

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

**PotPlayer 实时字幕翻译插件**，使用 DeepSeek API（OpenAI 兼容格式）对视频字幕进行实时翻译。

A real-time subtitle translation plugin for PotPlayer, powered by DeepSeek API (OpenAI-compatible format).

---

## Features

- **Real-time translation** — Translates subtitles on-the-fly while playing videos
- **Context-aware** — Full version keeps last 30 subtitles as context for coherent translations
- **100+ languages** — Wide language support with auto-detect source language option
- **Customizable model & endpoint** — Supports any OpenAI-compatible API, not limited to DeepSeek
- **Multi-language UI** — Interface in Korean, Traditional Chinese, Simplified Chinese, and English
- **RTL support** — Proper handling for Arabic, Persian, Hebrew and other right-to-left languages
- **Lightweight** — Two variants to choose from based on your needs

## Versions

| File | Description |
|------|-------------|
| `SubtitleTranslate - DeepSeek.as` | **Full version** — Maintains last 30 subtitles as context for translation coherence. Recommended. |
| `SubtitleTranslate - DeepSeek - nocontext.as` | **Simplified version** — Each subtitle translated independently, no context preserved. |

## Installation

1. **Copy** the `.as` file (choose either version) to PotPlayer's `Extension\SubtitleTranslate\` directory.
2. **Open** PotPlayer, right-click → **Preferences** → **Subtitles** → **Subtitle Translation**.
3. **Select** "DeepSeek Translate" from the translation plugin list.
4. **Configure** — Click **Login** (or Settings) and enter:
   - **Model Name \| Base URL**: e.g., `deepseek-v4-flash|https://api.deepseek.com`
   - **API Key**: Your DeepSeek API key
5. **Select** source language (or "Auto Detect") and target language.
6. **Play** a video with subtitles — translation will appear in real-time.

> **Note:** You need a [DeepSeek API key](https://platform.deepseek.com/api_keys) to use this plugin.

## Configuration Details

### Model & Endpoint

The plugin uses OpenAI-compatible `/chat/completions` API format. You can configure:

- **Default model**: `deepseek-v4-flash` (thinking mode disabled)
- **Default endpoint**: `https://api.deepseek.com`
- **Custom**: Any OpenAI-compatible API (e.g., `my-model|https://custom-api.example.com`)

You can also use this plugin with other OpenAI-compatible providers — just change the model name and base URL.

### Plugin Settings in PotPlayer

The plugin saves the following settings persistently:
- API Key
- Model name
- Base URL (full endpoint URL is auto-constructed)

## How It Works

1. PotPlayer calls `Translate(Text, SrcLang, DstLang)` for each subtitle line.
2. The plugin builds a prompt instructing the AI to translate the subtitle.
3. For the **full version**, previous subtitles are included as `Context` for coherent translations.
4. The request is sent to DeepSeek API via `HostUrlGetString()`.
5. The response is parsed — only the last line is returned (to filter out any extra model reasoning).
6. For RTL languages, a Unicode RLE marker (`\u202B`) is prepended.

### Plugin API

| Function | Purpose |
|----------|---------|
| `GetTitle()` / `GetVersion()` / `GetDesc()` | Plugin metadata and multi-language UI labels |
| `GetLoginTitle()` / `GetLoginDesc()` / `GetUserText()` / `GetPasswordText()` | Configuration UI text |
| `GetSrcLangs()` / `GetDstLangs()` | Source/target language lists |
| `ServerLogin(User, Pass)` | Save model name, base URL, and API key |
| `ServerLogout()` | Clear saved configuration |
| `Translate(Text, SrcLang, DstLang)` | Core translation function |
| `OnInitialize()` / `OnFinalize()` | Plugin load/unload hooks |

## Requirements

- **PotPlayer** (any recent version with subtitle translation support)
- **DeepSeek API key** (or any OpenAI-compatible API key)

## Supported Languages

100+ languages including: Afrikaans, Arabic, Bengali, Chinese (Simplified/Traditional), English, French, German, Hindi, Indonesian, Japanese, Korean, Portuguese, Russian, Spanish, Thai, Turkish, Vietnamese, and many more.

## Notes

- The **full version** stores up to 30 recent subtitles in memory for context — no token estimation.
- Deprecated models (`deepseek-chat`, `deepseek-reasoner`) will trigger a warning. They are scheduled for deprecation on **2026/07/24**.
- If the API response contains multiple lines, only the last line is used as the translation result.
- Translation failures will display "翻译失败" on screen.

---

## 功能特点

- **实时翻译** — 播放视频时即时翻译字幕
- **上下文感知** — 完整版保留最近 30 条字幕作为上下文，翻译更连贯
- **支持 100+ 种语言** — 源语言支持自动检测
- **自定义模型与端点** — 支持任何兼容 OpenAI 格式的 API
- **多语言 UI** — 韩文、繁体中文、简体中文、英文界面
- **RTL 语言支持** — 正确处理阿拉伯语、波斯语、希伯来语等从右到左的语言
- **轻量** — 提供两个版本按需选择

## 安装方法

1. 将 `.as` 文件复制到 PotPlayer 的 `Extension\SubtitleTranslate\` 目录
2. 打开 PotPlayer，右键 → **选项** → **字幕** → **字幕翻译**
3. 在翻译插件列表中选择 "DeepSeek 翻译"
4. 点击**登录**（或设置），输入：
   - **模型名|Base URL**：例如 `deepseek-v4-flash|https://api.deepseek.com`
   - **API 密钥**：你的 DeepSeek API 密钥
5. 选择源语言（或"自动检测"）和目标语言
6. 播放带字幕的视频即可实时翻译

## 支持的语言

支持 100+ 种语言，包括自动检测源语言功能。

## 许可证

MIT
