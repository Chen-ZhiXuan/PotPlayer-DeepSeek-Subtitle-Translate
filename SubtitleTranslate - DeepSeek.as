/*
    Real-time subtitle translation for PotPlayer using DeepSeek API
    API Endpoint: https://api.deepseek.com/chat/completions (auto-appended)
    Simplified version: directly uses last 30 subtitles as context (no token estimation)
*/

// Plugin Information Functions
string GetTitle() {
    return "{$CP949=DeepSeek 번역$}{$CP950=DeepSeek 翻譯$}{$CP0=DeepSeek Translate$}";
}

string GetVersion() {
    return "3";
}

string GetDesc() {
    return "{$CP949=DeepSeek를 사용한 실시간 자막 번역$}{$CP950=使用 DeepSeek 的實時字幕翻譯$}{$CP0=Real-time subtitle translation using DeepSeek$}";
}

string GetLoginTitle() {
    return "{$CP949=DeepSeek 모델 및 API 키 구성$}{$CP950=DeepSeek 模型與 API 金鑰配置$}{$CP0=DeepSeek Model + Base URL and API Key Configuration$}";
}

string GetLoginDesc() {
    return "{$CP949=모델 이름과 API 주소, 그리고 API 키를 입력하십시오 (예: deepseek-v4-flash|https://api.deepseek.com).$}{$CP950=請輸入模型名稱與 API 地址，以及 API 金鑰（例如 deepseek-v4-flash|https://api.deepseek.com）。$}{$CP0=Please enter the model name + Base URL and provide the API Key (e.g., deepseek-v4-flash|https://api.deepseek.com).$}";
}

string GetUserText() {
    return "{$CP949=모델 이름|API 주소 (현재: " + selected_model + " | " + apiBaseUrl + ")$}{$CP950=模型名稱|API 地址 (目前: " + selected_model + " | " + apiBaseUrl + ")$}{$CP0=Model Name|Base URL (Current: " + selected_model + " | " + apiBaseUrl + ")$}";
}

string GetPasswordText() {
    return "{$CP949=API 키:$}{$CP950=API 金鑰:$}{$CP0=API Key:$}";
}

// Global Variables
string api_key = "";
string selected_model = "deepseek-v4-flash";
string apiBaseUrl = "https://api.deepseek.com";          // 用户可见的基础地址
string apiFullUrl = "https://api.deepseek.com/chat/completions"; // 实际请求的完整地址
string UserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64)";

// 保存最近30句字幕用于上下文
array<string> subtitleHistory;
string UNICODE_RLE = "\u202B"; // For Right-to-Left languages

// Supported Language List
array<string> LangTable =
{
    "{$CP0=Auto Detect$}", "af", "sq", "am", "ar", "hy", "az", "eu", "be", "bn", "bs", "bg", "ca",
    "ceb", "ny", "zh-CN", "zh-TW", "co", "hr", "cs", "da", "nl", "en", "eo", "et", "tl", "fi", "fr",
    "fy", "gl", "ka", "de", "el", "gu", "ht", "ha", "haw", "he", "hi", "hmn", "hu", "is", "ig", "id", "ga", "it", "ja", "jw", "kn", "kk", "km",
    "ko", "ku", "ky", "lo", "la", "lv", "lt", "lb", "mk", "ms", "mg", "ml", "mt", "mi", "mr", "mn", "my", "ne", "no", "ps", "fa", "pl", "pt",
    "pa", "ro", "ru", "sm", "gd", "sr", "st", "sn", "sd", "si", "sk", "sl", "so", "es", "su", "sw", "sv", "tg", "ta", "te", "th", "tr", "uk",
    "ur", "uz", "vi", "cy", "xh", "yi", "yo", "zu"
};

// Get Source Language List
array<string> GetSrcLangs() {
    array<string> ret = LangTable;
    return ret;
}

// Get Destination Language List
array<string> GetDstLangs() {
    array<string> ret = LangTable;
    return ret;
}

// 辅助函数：将用户输入的 Base URL 转换为完整请求 URL (添加 /chat/completions)
string BuildFullUrl(const string &in base) {
    string url = base.Trim();
    // 如果已经包含 /chat/completions 路径，直接返回
    if (url.find("/chat/completions") != -1) {
        return url;
    }
    // 去除末尾的斜杠（如果有）
    if (url.substr(url.length() - 1) == "/") {
        url = url.substr(0, url.length() - 1);
    }
    // 拼接完整路径
    return url + "/chat/completions";
}

// Login Interface for entering model name + base URL and API Key
string ServerLogin(string User, string Pass) {
    User = User.Trim();
    Pass = Pass.Trim();

    int sepPos = User.find("|");
    string userModel = "";
    string customBaseUrl = "";

    if (sepPos != -1) {
        userModel = User.substr(0, sepPos).Trim();
        customBaseUrl = User.substr(sepPos + 1).Trim();
    } else {
        userModel = User;
        customBaseUrl = "";
    }

    if (userModel.empty()) {
        HostPrintUTF8("{$CP0=Model name not entered. Please enter a valid model name.$}\n");
        userModel = "deepseek-v4-flash";
    }

    if (!customBaseUrl.empty()) {
        apiBaseUrl = customBaseUrl;
    } else {
        apiBaseUrl = "https://api.deepseek.com";
    }

    if (Pass.empty()) {
        HostPrintUTF8("{$CP0=API Key not configured. Please enter a valid API Key.$}\n");
        return "fail";
    }

    selected_model = userModel;
    api_key = Pass;
    apiFullUrl = BuildFullUrl(apiBaseUrl);  // 构建完整请求 URL

    // 保存设置
    HostSaveString("api_key", api_key);
    HostSaveString("selected_model", selected_model);
    HostSaveString("apiBaseUrl", apiBaseUrl);
    HostSaveString("apiFullUrl", apiFullUrl);

    HostPrintUTF8("{$CP0=API Key and model name successfully configured. Full URL: $}" + apiFullUrl + "\n");
    return "200 ok";
}

// Logout Interface to clear model name and API Key
void ServerLogout() {
    api_key = "";
    selected_model = "deepseek-v4-flash";
    apiBaseUrl = "https://api.deepseek.com";
    apiFullUrl = "https://api.deepseek.com/chat/completions";
    subtitleHistory.resize(0);  // 清空历史字幕
    HostSaveString("api_key", "");
    HostSaveString("selected_model", selected_model);
    HostSaveString("apiBaseUrl", apiBaseUrl);
    HostSaveString("apiFullUrl", apiFullUrl);
    HostPrintUTF8("{$CP0=Successfully logged out.$}\n");
}

// JSON String Escape Function
string JsonEscape(const string &in input) {
    string output = input;
    output.replace("\\", "\\\\");
    output.replace("\"", "\\\"");
    output.replace("\n", "\\n");
    output.replace("\r", "\\r");
    output.replace("\t", "\\t");
    return output;
}

// Translation Function (simplified: no token estimation, just use last 30 subtitles as context)
string Translate(string Text, string &in SrcLang, string &in DstLang) {
    // 从存储中加载配置
    api_key = HostLoadString("api_key", "");
    selected_model = HostLoadString("selected_model", "deepseek-v4-flash");
    apiBaseUrl = HostLoadString("apiBaseUrl", "https://api.deepseek.com");
    apiFullUrl = HostLoadString("apiFullUrl", "https://api.deepseek.com/chat/completions");

    if (api_key.empty()) {
        HostPrintUTF8("{$CP0=API Key not configured. Please enter it in the settings menu.$}\n");
        return "翻译失败";
    }

    // 检查并警告弃用模型
    if (selected_model == "deepseek-chat" || selected_model == "deepseek-reasoner") {
        HostPrintUTF8("{$CP0=Warning: Model " + selected_model + " will be deprecated on 2026/07/24. Please switch to deepseek-v4-flash or deepseek-v4-pro.$}\n");
    }

    if (DstLang.empty() || DstLang == "{$CP0=Auto Detect$}") {
        HostPrintUTF8("{$CP0=Target language not specified. Please select a target language.$}\n");
        return "翻译失败";
    }

    if (SrcLang.empty() || SrcLang == "{$CP0=Auto Detect$}") {
        SrcLang = "";
    }

    // 添加当前字幕到历史，并限制历史最多保存30句
    subtitleHistory.insertLast(Text);
    while (subtitleHistory.length() > 30) {
        subtitleHistory.removeAt(0);
    }

    // 构建上下文：使用所有历史字幕（最多30句），用换行分隔
    string context = "";
    // 历史中除了当前添加的最后一句（即当前字幕）外，前面的都是旧字幕
    // 我们想要把除了当前字幕之外的历史作为上下文，以便模型理解连贯性
    // 注意：当前字幕是最后插入的，所以我们取前 length-1 条作为上下文
    if (subtitleHistory.length() > 1) {
        for (int idx = 0; idx < int(subtitleHistory.length()) - 1; idx++) {
            context += subtitleHistory[idx] + "\n";
        }
        // 去除最后一个多余的换行
        context = context.Trim();
    }

    // 构造提示词
    string prompt = "You are a professional translator. Please translate the following subtitle, output only translated results. If content that violates the Terms of Service appears, just output the translation result that complies with safety standards.";
    if (!SrcLang.empty()) {
        prompt += " from " + SrcLang;
    }
    prompt += " to " + DstLang + ". Use the context provided to maintain coherence.\n";
    if (!context.empty()) {
        prompt += "Context:\n" + context + "\n";
    }
    prompt += "Subtitle to translate:\n" + Text;

    // JSON escape
    string escapedPrompt = JsonEscape(prompt);

    // 请求数据
    string requestData = "{\"model\":\"" + selected_model + "\","
                         "\"messages\":[{\"role\":\"user\",\"content\":\"" + escapedPrompt + "\"}],"
                         "\"max_tokens\":1000,\"temperature\":0,"
                         "\"thinking\":{\"type\":\"disabled\"}}";

    string headers = "Authorization: Bearer " + api_key + "\nContent-Type: application/json";

    // 发送请求
    string response = HostUrlGetString(apiFullUrl, UserAgent, headers, requestData);
    if (response.empty()) {
        HostPrintUTF8("{$CP0=Translation request failed. Please check network connection or API Key.$}\n");
        return "翻译失败";
    }

    // 解析响应
    JsonReader Reader;
    JsonValue Root;
    if (!Reader.parse(response, Root)) {
        HostPrintUTF8("{$CP0=Failed to parse API response.$}\n");
        return "翻译失败";
    }

    JsonValue choices = Root["choices"];
    if (choices.isArray() && choices[0]["message"]["content"].isString()) {
        string translatedText = choices[0]["message"]["content"].asString();

        // 处理多行翻译结果：只取最后一行
        translatedText = translatedText.Trim();
        if (translatedText.find("\n") != -1) {
            array<string> lines = translatedText.split("\n");
            translatedText = lines[lines.length() - 1].Trim();
        }

        // 处理 RTL 语言
        if (DstLang == "fa" || DstLang == "ar" || DstLang == "he") {
            translatedText = UNICODE_RLE + translatedText;
        }

        SrcLang = "UTF8";
        DstLang = "UTF8";
        return translatedText;
    }

    // 处理 API 错误
    if (Root["error"]["message"].isString()) {
        string errorMessage = Root["error"]["message"].asString();
        HostPrintUTF8("{$CP0=API Error: $}" + errorMessage + "\n");
    } else {
        HostPrintUTF8("{$CP0=Translation failed. Please check input parameters or API Key configuration.$}\n");
    }

    return "翻译失败";
}

// Plugin Initialization
void OnInitialize() {
    HostPrintUTF8("{$CP0=DeepSeek translation plugin loaded (simplified version, context: last 30 subtitles).$}\n");
    // 加载保存的配置
    api_key = HostLoadString("api_key", "");
    selected_model = HostLoadString("selected_model", "deepseek-v4-flash");
    apiBaseUrl = HostLoadString("apiBaseUrl", "https://api.deepseek.com");
    apiFullUrl = HostLoadString("apiFullUrl", "https://api.deepseek.com/chat/completions");
    if (!api_key.empty()) {
        HostPrintUTF8("{$CP0=Saved API Key, model name, and Base URL loaded.$}\n");
    }
    subtitleHistory.resize(0); // 清空历史字幕
}

// Plugin Finalization
void OnFinalize() {
    HostPrintUTF8("{$CP0=DeepSeek translation plugin unloaded.$}\n");
}