enum PageHTML {
    static let source = ##"""
    <!DOCTYPE html>
    <html lang="zh-Hans">
    <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>文本</title>
    <style>
    :root { color-scheme: dark; }
    html, body { height: 100%; margin: 0; background: #000; color: #fff; }
    body {
      box-sizing: border-box;
      display: flex;
      flex-direction: column;
      gap: 8px;
      height: 100%;
      padding: 10px;
      font: 13px -apple-system, BlinkMacSystemFont, sans-serif;
    }
    .tabs, .actions { display: flex; gap: 6px; }
    button {
      flex: 1;
      border: 0;
      border-radius: 999px;
      padding: 6px 0;
      background: rgba(255,255,255,0.14);
      color: #fff;
      font: inherit;
    }
    button.on { background: rgba(255,255,255,0.32); }
    .actions button { border-radius: 8px; padding: 7px 0; }
    textarea {
      flex: 1;
      min-height: 0;
      resize: none;
      border: 0;
      border-radius: 10px;
      padding: 8px;
      background: rgba(255,255,255,0.08);
      color: #fff;
      font: 12px ui-monospace, SFMono-Regular, Menlo, monospace;
    }
    #status { min-height: 16px; color: rgba(255,255,255,0.72); font-size: 12px; }
    #status.bad { color: #ff8a80; }
    </style>
    </head>
    <body>
    <div class="tabs" id="tabs"></div>
    <textarea id="input" spellcheck="false"></textarea>
    <div class="actions" id="actions"></div>
    <textarea id="output" spellcheck="false" readonly></textarea>
    <div id="status"></div>
    <script>
    const tabs = [
      { id: "json", title: "JSON", input: "{\"name\":\"CanopyText\",\"items\":[1,2]}", placeholder: "", actions: [["json.pretty", "美化"], ["json.compact", "压缩"]] },
      { id: "base64", title: "Base64", input: "", placeholder: "要编码或解码的文本", actions: [["base64.encode", "编码"], ["base64.decode", "解码"]] },
      { id: "url", title: "URL", input: "", placeholder: "https://example.com/a b", actions: [["url.encode", "编码"], ["url.decode", "解码"]] },
      { id: "time", title: "时间", input: "", placeholder: "2026-10-17 11:14:00 或时间戳", actions: [["time.convert", "转换"], ["time.now", "现在"]] }
    ];
    const saved = {};
    tabs.forEach(function (tab) { saved[tab.id] = { input: tab.input, output: "" }; });
    let current = "json";
    const input = document.getElementById("input");
    const output = document.getElementById("output");
    const status = document.getElementById("status");

    function setStatus(text, bad) {
      status.textContent = text || "";
      status.className = bad ? "bad" : "";
    }

    function remember() {
      saved[current].input = input.value;
      saved[current].output = output.value;
    }

    function show(id) {
      remember();
      current = id;
      const tab = tabs.find(function (item) { return item.id === id; });
      input.value = saved[id].input;
      input.placeholder = tab.placeholder;
      output.value = saved[id].output;
      setStatus("");
      document.querySelectorAll(".tabs button").forEach(function (button) {
        button.className = button.dataset.id === id ? "on" : "";
      });
      const row = document.getElementById("actions");
      row.replaceChildren();
      tab.actions.forEach(function (item) {
        const button = document.createElement("button");
        button.type = "button";
        button.textContent = item[1];
        button.addEventListener("click", function () { run(item[0]); });
        row.appendChild(button);
      });
      const copy = document.createElement("button");
      copy.type = "button";
      copy.textContent = "复制";
      copy.addEventListener("click", copyOutput);
      row.appendChild(copy);
    }

    function renderTabs() {
      const row = document.getElementById("tabs");
      tabs.forEach(function (tab) {
        const button = document.createElement("button");
        button.type = "button";
        button.dataset.id = tab.id;
        button.textContent = tab.title;
        button.addEventListener("click", function () { show(tab.id); });
        row.appendChild(button);
      });
    }

    async function run(action) {
      remember();
      setStatus("正在转换…");
      try {
        const response = await fetch("/convert", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ action: action, text: input.value })
        });
        const payload = await response.json();
        if (!payload.ok) {
          setStatus(payload.message || "转换没有完成", true);
          return;
        }
        output.value = payload.text || "";
        saved[current].output = output.value;
        setStatus("完成");
      } catch (error) {
        setStatus("转换没有完成", true);
      }
    }

    async function copyOutput() {
      const text = output.value;
      if (!text) {
        setStatus("没有结果", true);
        return;
      }
      try {
        await navigator.clipboard.writeText(text);
        setStatus("已复制");
      } catch (error) {
        output.focus();
        output.select();
        setStatus("选中了结果，可以手动复制", true);
      }
    }

    renderTabs();
    show("json");
    run("json.pretty");
    </script>
    </body>
    </html>
    """##
}
