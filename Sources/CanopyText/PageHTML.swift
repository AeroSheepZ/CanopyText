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
    html, body {
      margin: 0;
      height: 100%;
      overflow: hidden;
      background: #000;
      color: rgba(255,255,255,0.9);
    }
    #app {
      position: absolute;
      inset: 0;
      box-sizing: border-box;
      display: flex;
      flex-direction: column;
      gap: 8px;
      padding: 8px;
      font: 13px/1.4 -apple-system, BlinkMacSystemFont, "PingFang SC", "Noto Sans SC", sans-serif;
      -webkit-font-smoothing: antialiased;
    }
    button, input, textarea { font: inherit; color: inherit; }
    button {
      height: 28px;
      flex: 0 0 auto;
      border: 0;
      border-radius: 6px;
      padding: 0 10px;
      background: rgba(255,255,255,0.08);
      color: rgba(255,255,255,0.9);
      transition: transform 120ms cubic-bezier(0.16, 1, 0.3, 1);
    }
    button:active { transform: scale(0.96); }
    button:focus-visible, textarea:focus-visible, input:focus-visible {
      outline: 1px solid rgba(255,255,255,0.4);
      outline-offset: 1px;
    }
    @media (prefers-reduced-motion: reduce) {
      button { transition: none; }
      button:active { transform: none; }
    }
    .segment {
      display: flex;
      flex: 0 0 auto;
      height: 28px;
      box-sizing: border-box;
      padding: 2px;
      gap: 2px;
      border-radius: 8px;
      background: rgba(255,255,255,0.06);
    }
    .segment > button {
      flex: 1 1 auto;
      height: 24px;
      border-radius: 6px;
      background: transparent;
    }
    .segment > button[aria-selected="true"] { background: rgba(255,255,255,0.12); }
    .segment.mini { height: 28px; }
    .segment.mini > button { flex: 0 0 auto; padding: 0 10px; }
    #panes { flex: 1 1 auto; min-height: 0; display: flex; }
    .pane {
      display: none;
      flex: 1 1 auto;
      min-height: 0;
      flex-direction: column;
      gap: 8px;
    }
    .pane.on { display: flex; }
    .toolbar, .mid, .field-head {
      display: flex;
      align-items: center;
      gap: 6px;
      flex: 0 0 auto;
      min-width: 0;
    }
    .field-head { color: rgba(255,255,255,0.6); font-size: 12px; }
    .field-head button { height: 22px; padding: 0 8px; }
    .check {
      display: flex;
      align-items: center;
      gap: 4px;
      height: 28px;
      color: rgba(255,255,255,0.6);
      font-size: 12px;
    }
    .status {
      margin-left: auto;
      min-width: 0;
      overflow: hidden;
      text-overflow: ellipsis;
      white-space: nowrap;
      color: rgba(255,255,255,0.6);
      font-size: 12px;
    }
    .status.bad { color: oklch(0.75 0.12 25); }
    .editor {
      position: relative;
      flex: 1 1 auto;
      min-height: 0;
      border-radius: 8px;
      background: rgba(255,255,255,0.06);
      overflow: hidden;
    }
    .editor pre,
    .editor textarea {
      position: absolute;
      inset: 0;
      box-sizing: border-box;
      margin: 0;
      border: 0;
      padding: 8px;
      overflow: auto;
      background: transparent;
      white-space: pre;
      overflow-wrap: normal;
      word-break: normal;
      font-family: ui-monospace, "SF Mono", SFMono-Regular, Menlo, monospace;
      font-size: 12px;
      line-height: 18px;
      letter-spacing: 0;
      tab-size: 2;
    }
    .editor pre {
      pointer-events: none;
      user-select: none;
      overflow: hidden;
      color: rgba(255,255,255,0.9);
    }
    .editor textarea {
      resize: none;
      caret-color: rgba(255,255,255,0.9);
      color: rgba(255,255,255,0.9);
    }
    .editor.lit textarea {
      color: transparent;
      -webkit-text-fill-color: transparent;
    }
    .editor textarea::placeholder {
      color: rgba(255,255,255,0.35);
      -webkit-text-fill-color: rgba(255,255,255,0.35);
    }
    .editor.lit textarea::selection {
      background: rgba(255,255,255,0.18);
      color: transparent;
      -webkit-text-fill-color: transparent;
    }
    #json-paint .key { color: oklch(0.86 0.045 85); }
    #json-paint .string { color: oklch(0.82 0.055 145); }
    #json-paint .number { color: oklch(0.84 0.04 230); }
    #json-paint .literal { color: oklch(0.8 0.06 25); }
    #json-paint .punct { color: rgba(255,255,255,0.45); }
    textarea.fill, input.line {
      box-sizing: border-box;
      border: 0;
      border-radius: 8px;
      background: rgba(255,255,255,0.06);
      color: rgba(255,255,255,0.9);
      font-family: ui-monospace, "SF Mono", SFMono-Regular, Menlo, monospace;
      font-size: 12px;
      line-height: 18px;
    }
    textarea.fill {
      flex: 1 1 0;
      min-height: 0;
      resize: none;
      padding: 8px;
    }
    input.line {
      width: 100%;
      height: 28px;
      padding: 0 8px;
      font-variant-numeric: tabular-nums;
    }
    input.line::placeholder { color: rgba(255,255,255,0.35); }
    .time-row { display: flex; flex-direction: column; gap: 4px; flex: 0 0 auto; }
    </style>
    </head>
    <body>
    <div id="app">
      <div class="segment" role="tablist">
        <button type="button" role="tab" id="tab-json" aria-selected="true" aria-controls="pane-json">JSON</button>
        <button type="button" role="tab" id="tab-base64" aria-selected="false" aria-controls="pane-base64">Base64</button>
        <button type="button" role="tab" id="tab-url" aria-selected="false" aria-controls="pane-url">URL</button>
        <button type="button" role="tab" id="tab-time" aria-selected="false" aria-controls="pane-time">时间</button>
      </div>
      <div id="panes">
        <section class="pane on" id="pane-json" role="tabpanel">
          <div class="toolbar">
            <button type="button" id="json-pretty">美化</button>
            <button type="button" id="json-compact">压缩</button>
            <button type="button" id="json-copy">复制</button>
            <label class="check"><input type="checkbox" id="json-sort" checked>排序键</label>
            <div class="status" id="json-status" aria-live="polite"></div>
          </div>
          <div class="editor" id="json-editor">
            <pre id="json-paint" aria-hidden="true"></pre>
            <textarea id="json-input" wrap="off" spellcheck="false" autocomplete="off" autocapitalize="off" autocorrect="off" placeholder='{"name":"CanopyText"}'></textarea>
          </div>
        </section>
        <section class="pane" id="pane-base64" role="tabpanel">
          <div class="field-head"><span>文本</span><button type="button" id="b64-copy-text">复制</button></div>
          <textarea class="fill" id="b64-text" spellcheck="false" autocomplete="off" autocapitalize="off" autocorrect="off" placeholder="要编码的文本"></textarea>
          <div class="mid">
            <button type="button" id="b64-swap">对调</button>
            <label class="check"><input type="checkbox" id="b64-urlsafe">URL-safe</label>
            <div class="status" id="b64-status" aria-live="polite"></div>
          </div>
          <div class="field-head"><span>Base64</span><button type="button" id="b64-copy-encoded">复制</button></div>
          <textarea class="fill" id="b64-encoded" spellcheck="false" autocomplete="off" autocapitalize="off" autocorrect="off" placeholder="要解码的 Base64"></textarea>
        </section>
        <section class="pane" id="pane-url" role="tabpanel">
          <div class="field-head"><span>文本</span><button type="button" id="url-copy-text">复制</button></div>
          <textarea class="fill" id="url-text" spellcheck="false" autocomplete="off" autocapitalize="off" autocorrect="off" placeholder="https://example.com/a b"></textarea>
          <div class="mid">
            <button type="button" id="url-swap">对调</button>
            <div class="segment mini" role="group" aria-label="编码范围">
              <button type="button" id="url-component" aria-selected="true">片段</button>
              <button type="button" id="url-full" aria-selected="false">整段</button>
            </div>
            <div class="status" id="url-status" aria-live="polite"></div>
          </div>
          <div class="field-head"><span>编码</span><button type="button" id="url-copy-encoded">复制</button></div>
          <textarea class="fill" id="url-encoded" spellcheck="false" autocomplete="off" autocapitalize="off" autocorrect="off" placeholder="百分号编码"></textarea>
        </section>
        <section class="pane" id="pane-time" role="tabpanel">
          <div class="time-row">
            <div class="field-head">
              <span>本地时间</span>
              <button type="button" id="time-now">现在</button>
              <button type="button" id="time-copy-local">复制</button>
              <div class="status" id="time-status" aria-live="polite"></div>
            </div>
            <input class="line" id="time-local" spellcheck="false" autocomplete="off" placeholder="2026-10-17 11:14:00">
          </div>
          <div class="time-row">
            <div class="field-head"><span>秒</span><button type="button" id="time-copy-seconds">复制</button></div>
            <input class="line" id="time-seconds" spellcheck="false" autocomplete="off" inputmode="numeric" placeholder="10 位">
          </div>
          <div class="time-row">
            <div class="field-head"><span>毫秒</span><button type="button" id="time-copy-millis">复制</button></div>
            <input class="line" id="time-millis" spellcheck="false" autocomplete="off" inputmode="numeric" placeholder="13 位">
          </div>
        </section>
      </div>
    </div>
    <script>
    const panes = ["json", "base64", "url", "time"];
    const LIVE_LIMIT = 200000;
    let paintTimer = 0;
    let urlScope = "component";
    const tickets = { b64: 0, url: 0, time: 0 };
    const origin = { b64: "", url: "" };

    function setStatus(node, text, bad) {
      node.textContent = text || "";
      node.className = bad ? "status bad" : "status";
    }

    function show(id) {
      panes.forEach(function (key) {
        document.getElementById("pane-" + key).classList.toggle("on", key === id);
        document.getElementById("tab-" + key).setAttribute("aria-selected", key === id ? "true" : "false");
      });
    }

    panes.forEach(function (key) {
      document.getElementById("tab-" + key).addEventListener("click", function () { show(key); });
    });

    async function post(action, text, options) {
      const response = await fetch("/convert", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ action: action, text: text, options: options || {} })
      });
      return response.json();
    }

    async function copyField(text, field, status) {
      if (!text) {
        setStatus(status, "没有结果", true);
        return;
      }
      try {
        await navigator.clipboard.writeText(text);
        setStatus(status, "已复制");
      } catch (error) {
        field.focus();
        field.select();
        setStatus(status, "选中了结果，可以手动复制", true);
      }
    }

    const tokenClass = { key: 1, string: 1, number: 1, literal: 1, punct: 1 };

    function highlightJSON(text) {
      try {
        JSON.parse(text);
      } catch (error) {
        return null;
      }
      const tokens = [];
      let index = 0;
      while (index < text.length) {
        const character = text[index];
        if (character === " " || character === "\n" || character === "\r" || character === "\t") {
          let next = index + 1;
          while (next < text.length && " \n\r\t".indexOf(text[next]) !== -1) next += 1;
          tokens.push(["ws", text.slice(index, next)]);
          index = next;
          continue;
        }
        if ("{}[],:".indexOf(character) !== -1) {
          tokens.push(["punct", character]);
          index += 1;
          continue;
        }
        if (character === '"') {
          let next = index + 1;
          let closed = false;
          while (next < text.length) {
            if (text[next] === "\\") {
              next += 2;
              continue;
            }
            if (text[next] === '"') {
              next += 1;
              closed = true;
              break;
            }
            next += 1;
          }
          if (!closed) return null;
          tokens.push(["string", text.slice(index, next)]);
          index = next;
          continue;
        }
        if (character === "-" || (character >= "0" && character <= "9")) {
          const matched = text.slice(index).match(/^-?(?:0|[1-9]\d*)(?:\.\d+)?(?:[eE][+-]?\d+)?/);
          if (!matched) return null;
          tokens.push(["number", matched[0]]);
          index += matched[0].length;
          continue;
        }
        if (text.startsWith("true", index)) { tokens.push(["literal", "true"]); index += 4; continue; }
        if (text.startsWith("false", index)) { tokens.push(["literal", "false"]); index += 5; continue; }
        if (text.startsWith("null", index)) { tokens.push(["literal", "null"]); index += 4; continue; }
        return null;
      }
      for (let cursor = 0; cursor < tokens.length; cursor += 1) {
        if (tokens[cursor][0] !== "string") continue;
        let look = cursor + 1;
        while (look < tokens.length && tokens[look][0] === "ws") look += 1;
        if (look < tokens.length && tokens[look][1] === ":") tokens[cursor][0] = "key";
      }
      return tokens;
    }

    const jsonInput = document.getElementById("json-input");
    const jsonPaint = document.getElementById("json-paint");
    const jsonEditor = document.getElementById("json-editor");
    const jsonStatus = document.getElementById("json-status");

    function applyPaint(tokens) {
      const top = jsonInput.scrollTop;
      const left = jsonInput.scrollLeft;
      jsonPaint.replaceChildren();
      if (!tokens) {
        jsonEditor.classList.remove("lit");
        return;
      }
      const fragment = document.createDocumentFragment();
      for (let cursor = 0; cursor < tokens.length; cursor += 1) {
        const type = tokens[cursor][0];
        const value = tokens[cursor][1];
        if (type === "ws") {
          fragment.appendChild(document.createTextNode(value));
          continue;
        }
        if (!tokenClass[type]) {
          jsonEditor.classList.remove("lit");
          return;
        }
        const span = document.createElement("span");
        span.className = type;
        span.textContent = value;
        fragment.appendChild(span);
      }
      fragment.appendChild(document.createTextNode("\n"));
      jsonPaint.replaceChildren(fragment);
      jsonEditor.classList.add("lit");
      jsonPaint.scrollTop = top;
      jsonPaint.scrollLeft = left;
    }

    function paintJSON(force) {
      const text = jsonInput.value;
      if (!text) {
        applyPaint(null);
        return;
      }
      if (!force && text.length > LIVE_LIMIT) {
        applyPaint(null);
        return;
      }
      applyPaint(highlightJSON(text));
    }

    function schedulePaint() {
      window.clearTimeout(paintTimer);
      paintTimer = window.setTimeout(function () { paintJSON(false); }, 50);
    }

    jsonInput.addEventListener("input", function () {
      setStatus(jsonStatus, "");
      schedulePaint();
    });
    jsonInput.addEventListener("scroll", function () {
      jsonPaint.scrollTop = jsonInput.scrollTop;
      jsonPaint.scrollLeft = jsonInput.scrollLeft;
    });

    async function runJSON(action, done) {
      setStatus(jsonStatus, "");
      try {
        const payload = await post(action, jsonInput.value, {
          sortKeys: document.getElementById("json-sort").checked
        });
        if (!payload.ok) {
          setStatus(jsonStatus, payload.message || "转换没有完成", true);
          paintJSON(false);
          return;
        }
        jsonInput.value = payload.text || "";
        jsonInput.setSelectionRange(0, 0);
        jsonInput.scrollTop = 0;
        jsonInput.scrollLeft = 0;
        paintJSON(true);
        setStatus(jsonStatus, done);
      } catch (error) {
        setStatus(jsonStatus, "转换没有完成", true);
      }
    }

    document.getElementById("json-pretty").addEventListener("click", function () { runJSON("json.pretty", "已美化"); });
    document.getElementById("json-compact").addEventListener("click", function () { runJSON("json.compact", "已压缩"); });
    document.getElementById("json-copy").addEventListener("click", function () {
      copyField(jsonInput.value, jsonInput, jsonStatus);
    });

    function bindPair(name, encodeAction, decodeAction, options) {
      const text = document.getElementById(name + "-text");
      const encoded = document.getElementById(name + "-encoded");
      const status = document.getElementById(name + "-status");
      let timer = 0;

      async function run(side) {
        origin[name] = side;
        const ticket = ++tickets[name];
        const source = side === "text" ? text : encoded;
        const target = side === "text" ? encoded : text;
        const action = side === "text" ? encodeAction : decodeAction;
        if (!source.value) {
          target.value = "";
          setStatus(status, "");
          return;
        }
        try {
          const payload = await post(action, source.value, options());
          if (ticket !== tickets[name]) return;
          if (!payload.ok) {
            setStatus(status, payload.message || "转换没有完成", true);
            return;
          }
          target.value = payload.text || "";
          setStatus(status, "");
        } catch (error) {
          if (ticket !== tickets[name]) return;
          setStatus(status, "转换没有完成", true);
        }
      }

      function schedule(side) {
        origin[name] = side;
        window.clearTimeout(timer);
        timer = window.setTimeout(function () { run(side); }, 150);
      }

      text.addEventListener("input", function () { schedule("text"); });
      encoded.addEventListener("input", function () { schedule("encoded"); });
      document.getElementById(name + "-swap").addEventListener("click", function () {
        const left = text.value;
        text.value = encoded.value;
        encoded.value = left;
        origin[name] = "";
        setStatus(status, "");
      });
      document.getElementById(name + "-copy-text").addEventListener("click", function () {
        copyField(text.value, text, status);
      });
      document.getElementById(name + "-copy-encoded").addEventListener("click", function () {
        copyField(encoded.value, encoded, status);
      });
      return run;
    }

    const runBase64 = bindPair("b64", "base64.encode", "base64.decode", function () {
      return { urlSafe: document.getElementById("b64-urlsafe").checked };
    });
    document.getElementById("b64-urlsafe").addEventListener("change", function () {
      const side = origin.b64 || (document.getElementById("b64-text").value ? "text" : "encoded");
      if (side) runBase64(side);
    });

    const runURL = bindPair("url", "url.encode", "url.decode", function () {
      return { scope: urlScope };
    });

    function setScope(scope) {
      urlScope = scope;
      document.getElementById("url-component").setAttribute("aria-selected", scope === "component" ? "true" : "false");
      document.getElementById("url-full").setAttribute("aria-selected", scope === "full" ? "true" : "false");
    }
    document.getElementById("url-component").addEventListener("click", function () {
      setScope("component");
      if (document.getElementById("url-text").value) runURL("text");
    });
    document.getElementById("url-full").addEventListener("click", function () {
      setScope("full");
      if (document.getElementById("url-text").value) runURL("text");
    });

    const timeLocal = document.getElementById("time-local");
    const timeSeconds = document.getElementById("time-seconds");
    const timeMillis = document.getElementById("time-millis");
    const timeStatus = document.getElementById("time-status");
    const timeFields = { local: timeLocal, seconds: timeSeconds, millis: timeMillis };
    let timeTimer = 0;

    async function runTime(side) {
      const ticket = ++tickets.time;
      const source = timeFields[side];
      if (!source.value.trim()) {
        Object.keys(timeFields).forEach(function (key) {
          if (key !== side) timeFields[key].value = "";
        });
        setStatus(timeStatus, "");
        return;
      }
      try {
        const payload = await post("time.parse", source.value, {});
        if (ticket !== tickets.time) return;
        if (!payload.ok || !payload.fields) {
          setStatus(timeStatus, (payload && payload.message) || "转换没有完成", true);
          return;
        }
        Object.keys(timeFields).forEach(function (key) {
          if (key !== side) timeFields[key].value = payload.fields[key] || "";
        });
        setStatus(timeStatus, "");
      } catch (error) {
        if (ticket !== tickets.time) return;
        setStatus(timeStatus, "转换没有完成", true);
      }
    }

    function scheduleTime(side) {
      window.clearTimeout(timeTimer);
      timeTimer = window.setTimeout(function () { runTime(side); }, 150);
    }

    Object.keys(timeFields).forEach(function (key) {
      timeFields[key].addEventListener("input", function () { scheduleTime(key); });
      document.getElementById("time-copy-" + key).addEventListener("click", function () {
        copyField(timeFields[key].value, timeFields[key], timeStatus);
      });
    });

    document.getElementById("time-now").addEventListener("click", async function () {
      const ticket = ++tickets.time;
      setStatus(timeStatus, "");
      try {
        const payload = await post("time.now", "", {});
        if (ticket !== tickets.time) return;
        if (!payload.ok || !payload.fields) {
          setStatus(timeStatus, (payload && payload.message) || "转换没有完成", true);
          return;
        }
        timeLocal.value = payload.fields.local || "";
        timeSeconds.value = payload.fields.seconds || "";
        timeMillis.value = payload.fields.millis || "";
      } catch (error) {
        if (ticket !== tickets.time) return;
        setStatus(timeStatus, "转换没有完成", true);
      }
    });

    show("json");
    </script>
    </body>
    </html>
    """##
}
