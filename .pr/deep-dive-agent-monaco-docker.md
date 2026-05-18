# Deep Dive: Agent Logic, Monaco Editor & Docker Sandbox

This document explains the **actual implementation** of three critical components in OpenHands, with real code examples.

---

## 🤖 Part 1: Agent Logic - How the AI Makes Decisions

### Framework Used: **Custom Python Implementation** (No framework!)

OpenHands doesn't use LangChain or similar frameworks. It's built from scratch using:
- **Python** - Core language
- **FastAPI** - Web server
- **AsyncIO** - Async operations
- **Direct LLM API calls** - OpenAI, Anthropic, Ollama

### Agent Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    AGENT CONTROLLER                         │
│  (openhands/controller/agent_controller.py)                │
│                                                             │
│  Main Loop:                                                 │
│  while not finished:                                        │
│      1. action = agent.step(history)                       │
│      2. observation = runtime.execute(action)              │
│      3. history.append(action, observation)                │
│      4. if action == AgentFinishAction: break              │
└─────────────────────────────────────────────────────────────┘
```

### How Agent.step() Works

The agent doesn't have complex logic - it's surprisingly simple:

```python
# Simplified version of how the agent works

class CodeActAgent:
    def __init__(self, llm):
        self.llm = llm
        self.system_prompt = """
You are a software engineer AI assistant.

You can use these actions:
- run(command) - Execute shell command
- write(path, content) - Create/edit file
- read(path) - Read file
- browse(url) - Browse web page
- think(thought) - Explain your reasoning
- finish(message) - Complete the task

Example:
User: "Create a Flask app"
You: <think>I need to install Flask first</think>
     <run>pip install flask</run>
"""

    async def step(self, conversation_history):
        # 1. Build prompt with system instructions + history
        messages = [
            {"role": "system", "content": self.system_prompt},
            *conversation_history
        ]

        # 2. Ask LLM what to do next
        response = await self.llm.completion(messages)

        # 3. Parse LLM response into Action object
        action = self.parse_response(response)

        return action

    def parse_response(self, llm_response):
        # Extract action from LLM response
        # Example: "<run>pip install flask</run>"
        # → CmdRunAction(command="pip install flask")

        if "<run>" in llm_response:
            command = extract_between(llm_response, "<run>", "</run>")
            return CmdRunAction(command=command)

        elif "<write>" in llm_response:
            path = extract_attribute(llm_response, "path")
            content = extract_between(llm_response, "<write>", "</write>")
            return FileWriteAction(path=path, content=content)

        elif "<finish>" in llm_response:
            message = extract_between(llm_response, "<finish>", "</finish>")
            return AgentFinishAction(message=message)

        # ... more action types
```

### Real Example: Creating a Flask App

```
Iteration 1:
├─ Input: User says "Create a Flask web app"
├─ Agent builds prompt:
│  System: "You are a software engineer..."
│  User: "Create a Flask web app"
│
├─ LLM responds:
│  "<think>I need to check if Flask is installed</think>
│   <run>pip list | grep Flask</run>"
│
├─ Agent parses → CmdRunAction(command="pip list | grep Flask")
└─ Controller executes → Observation: "Flask not found"

Iteration 2:
├─ Input: Previous observation "Flask not found"
├─ Agent builds prompt:
│  System: "You are a software engineer..."
│  User: "Create a Flask web app"
│  Assistant: "<run>pip list | grep Flask</run>"
│  Observation: "Flask not found"
│
├─ LLM responds:
│  "<think>Flask is not installed, I'll install it</think>
│   <run>pip install flask</run>"
│
├─ Agent parses → CmdRunAction(command="pip install flask")
└─ Controller executes → Observation: "Successfully installed Flask"

Iteration 3:
├─ Input: Previous observation "Successfully installed Flask"
├─ LLM responds:
│  "<think>Now I'll create the Flask app file</think>
│   <write path='app.py'>
│   from flask import Flask
│   app = Flask(__name__)
│
│   @app.route('/')
│   def home():
│       return '<h1>Hello World!</h1>'
│
│   if __name__ == '__main__':
│       app.run(debug=True)
│   </write>"
│
├─ Agent parses → FileWriteAction(path="app.py", content="...")
└─ Controller executes → Observation: "File created successfully"

Iteration 4:
├─ LLM responds:
│  "<think>Task complete!</think>
│   <finish>I've created a Flask web app with a homepage</finish>"
│
└─ Agent parses → AgentFinishAction() → Loop ends
```

### Key Insight: The Agent is Just a Prompt Parser!

The "intelligence" comes from:
1. **System Prompt** - Tells LLM what actions it can take
2. **Conversation History** - Provides context
3. **LLM** - Makes decisions based on prompt
4. **Parser** - Converts LLM text into Action objects

**No complex algorithms, no planning trees, no reinforcement learning!**

---

## 🎨 Part 2: Monaco Editor Integration - VS Code in the Browser

### Framework Used: **@monaco-editor/react**

Monaco is the **same editor that powers VS Code**. It's open-source and can be embedded in web apps.

### Installation

```bash
npm install @monaco-editor/react monaco-editor
```

### Real Implementation from OpenHands

```typescript
// frontend/src/components/features/diff-viewer/file-diff-viewer.tsx

import { DiffEditor, Editor, Monaco } from "@monaco-editor/react";
import { editor as editor_t } from "monaco-editor";

// 1. Define custom theme (VS Code dark theme with custom colors)
const beforeMount = (monaco: Monaco) => {
  monaco.editor.defineTheme("custom-diff-theme", {
    base: "vs-dark",
    inherit: true,
    rules: [
      { token: "comment", foreground: "6a9955" },
      { token: "keyword", foreground: "569cd6" },
      { token: "string", foreground: "ce9178" },
      { token: "number", foreground: "b5cea8" },
    ],
    colors: {
      "diffEditor.insertedTextBackground": "#014b01AA",  // Green for additions
      "diffEditor.removedTextBackground": "#750000AA",   // Red for deletions
      "editor.background": "#1e1e1e",                    // Dark background
    },
  });
};

// 2. Use Monaco Editor component
export function FileDiffViewer({ path, type }: FileDiffViewerProps) {
  const [editorHeight, setEditorHeight] = React.useState(400);
  const diffEditorRef = React.useRef<editor_t.IStandaloneDiffEditor>(null);

  // Get file language from extension
  const language = getLanguageFromPath(path); // "python", "javascript", etc.

  // 3. Render Diff Editor (shows old vs new side-by-side)
  return (
    <DiffEditor
      className="w-full h-full"
      language={language}
      original={oldContent}      // Left side (before)
      modified={newContent}      // Right side (after)
      theme="custom-diff-theme"
      onMount={handleDiffEditorMount}
      beforeMount={beforeMount}
      options={{
        readOnly: true,
        scrollBeyondLastLine: false,
        minimap: { enabled: false },
        automaticLayout: true,
        renderSideBySide: true,
        hideUnchangedRegions: { enabled: true },
      }}
    />
  );
}
```

### Monaco Editor Features Used in OpenHands

#### 1. **Diff Viewer** (Side-by-side comparison)
```typescript
<DiffEditor
  original={oldCode}
  modified={newCode}
  language="python"
  theme="vs-dark"
/>
```

#### 2. **Single File Editor**
```typescript
<Editor
  value={fileContent}
  language="typescript"
  theme="vs-dark"
  onChange={(newValue) => saveFile(newValue)}
  options={{
    fontSize: 14,
    lineNumbers: 'on',
    minimap: { enabled: true },
    automaticLayout: true,
  }}
/>
```

#### 3. **Language Detection**
```typescript
// Automatically detect language from file extension
function getLanguageFromPath(path: string): string {
  const ext = path.split('.').pop()?.toLowerCase();

  const languageMap: Record<string, string> = {
    'py': 'python',
    'js': 'javascript',
    'ts': 'typescript',
    'tsx': 'typescriptreact',
    'jsx': 'javascriptreact',
    'java': 'java',
    'cpp': 'cpp',
    'c': 'c',
    'go': 'go',
    'rs': 'rust',
    'md': 'markdown',
    'json': 'json',
    'yaml': 'yaml',
    'yml': 'yaml',
    'html': 'html',
    'css': 'css',
    'scss': 'scss',
    'sql': 'sql',
    'sh': 'shell',
    'bash': 'shell',
  };

  return languageMap[ext || ''] || 'plaintext';
}
```

#### 4. **Custom Themes**
```typescript
monaco.editor.defineTheme("my-custom-theme", {
  base: "vs-dark",  // Start with dark theme
  inherit: true,    // Inherit default colors
  rules: [
    // Syntax highlighting rules
    { token: "comment", foreground: "6a9955", fontStyle: "italic" },
    { token: "keyword", foreground: "569cd6", fontStyle: "bold" },
    { token: "string", foreground: "ce9178" },
    { token: "number", foreground: "b5cea8" },
    { token: "function", foreground: "dcdcaa" },
  ],
  colors: {
    // Editor colors
    "editor.background": "#1e1e1e",
    "editor.foreground": "#d4d4d4",
    "editor.lineHighlightBackground": "#2a2a2a",
    "editorCursor.foreground": "#ffffff",
    "editorLineNumber.foreground": "#858585",
  },
});
```

#### 5. **Auto-resize Editor**
```typescript
const handleEditorMount = (editor: editor_t.IStandaloneCodeEditor) => {
  // Auto-adjust height based on content
  const updateHeight = () => {
    const contentHeight = editor.getContentHeight();
    setEditorHeight(contentHeight + 20); // Add padding
  };

  editor.onDidContentSizeChange(updateHeight);
  updateHeight();
};
```

### Complete Monaco Editor Example

```typescript
import { Editor } from "@monaco-editor/react";
import { useState } from "react";

function CodeEditor() {
  const [code, setCode] = useState(`def hello():
    print("Hello World!")

hello()`);

  return (
    <div className="h-screen">
      <Editor
        height="100%"
        language="python"
        value={code}
        onChange={(newValue) => setCode(newValue || "")}
        theme="vs-dark"
        options={{
          fontSize: 14,
          lineNumbers: "on",
          minimap: { enabled: true },
          automaticLayout: true,
          scrollBeyondLastLine: false,
          wordWrap: "on",
          tabSize: 4,
          insertSpaces: true,
          // Enable IntelliSense
          quickSuggestions: true,
          suggestOnTriggerCharacters: true,
          // Enable bracket matching
          matchBrackets: "always",
          // Enable code folding
          folding: true,
          // Enable find/replace
          find: {
            seedSearchStringFromSelection: "always",
            autoFindInSelection: "always",
          },
        }}
      />
    </div>
  );
}
```

### Monaco Editor Features

✅ **Syntax Highlighting** - 100+ languages
✅ **IntelliSense** - Auto-completion
✅ **Code Folding** - Collapse/expand blocks
✅ **Find & Replace** - Search in code
✅ **Multi-cursor** - Edit multiple lines
✅ **Diff Viewer** - Side-by-side comparison
✅ **Minimap** - Code overview
✅ **Bracket Matching** - Highlight matching brackets
✅ **Custom Themes** - Full customization
✅ **Keyboard Shortcuts** - VS Code shortcuts work!

---

## 🐳 Part 3: Docker Sandbox - Isolated Code Execution

### Framework Used: **docker-py** (Official Docker SDK for Python)

```bash
pip install docker
```

### Real Implementation from OpenHands

```python
# openhands/app_server/sandbox/docker_sandbox_service.py

import docker
import base62
import os

class DockerSandboxService:
    def __init__(self):
        # Connect to Docker daemon
        self.docker_client = docker.from_env()
        self.container_name_prefix = "oh-agent-server-"

    async def start_sandbox(self, sandbox_spec_id: str) -> SandboxInfo:
        """Start a new isolated Docker container for code execution."""

        # 1. Generate unique container name and API key
        sandbox_id = base62.encodebytes(os.urandom(16))
        container_name = f"{self.container_name_prefix}{sandbox_id}"
        session_api_key = base62.encodebytes(os.urandom(32))

        # 2. Prepare environment variables
        env_vars = {
            "SESSION_API_KEY": session_api_key,
            "WORKSPACE_DIR": "/workspace",
            "PYTHONUNBUFFERED": "1",
            "LOG_JSON": "true",
        }

        # 3. Find unused ports on host
        host_port_8000 = self._find_unused_port()  # For agent server
        host_port_8001 = self._find_unused_port()  # For VS Code server

        # 4. Prepare port mappings (container port → host port)
        port_mappings = {
            8000: host_port_8000,  # Agent server
            8001: host_port_8001,  # VS Code server
        }

        # 5. Prepare volume mounts (host path → container path)
        volumes = {
            "/tmp/workspace": {
                "bind": "/workspace",
                "mode": "rw"  # read-write
            }
        }

        # 6. Create and start container
        container = self.docker_client.containers.run(
            image="ghcr.io/openhands/agent-server:latest",
            command=["--port", "8000"],
            name=container_name,
            environment=env_vars,
            ports=port_mappings,
            volumes=volumes,
            working_dir="/workspace/project",
            detach=True,  # Run in background
            remove=False,  # Don't auto-remove
            init=True,    # Use init process for proper signal handling
            extra_hosts={
                "host.docker.internal": "host-gateway"  # Allow container to reach host
            },
        )

        # 7. Return sandbox info
        return SandboxInfo(
            id=container_name,
            status="RUNNING",
            session_api_key=session_api_key,
            exposed_urls=[
                {"name": "agent-server", "url": f"http://localhost:{host_port_8000}"},
                {"name": "vscode", "url": f"http://localhost:{host_port_8001}"},
            ],
        )

    def _find_unused_port(self) -> int:
        """Find an available port on the host machine."""
        import socket
        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
            s.bind(('', 0))  # Bind to any available port
            s.listen(1)
            port = s.getsockname()[1]
        return port

    async def execute_command(self, container_name: str, command: str):
        """Execute a command inside the container."""
        container = self.docker_client.containers.get(container_name)

        # Execute command and get output
        result = container.exec_run(
            cmd=command,
            workdir="/workspace/project",
            environment={"PYTHONUNBUFFERED": "1"},
        )

        return {
            "output": result.output.decode("utf-8"),
            "exit_code": result.exit_code,
        }

    async def write_file(self, container_name: str, path: str, content: str):
        """Write a file inside the container."""
        container = self.docker_client.containers.get(container_name)

        # Create file content as tar archive
        import tarfile
        import io

        tar_stream = io.BytesIO()
        tar = tarfile.open(fileobj=tar_stream, mode='w')

        file_data = content.encode('utf-8')
        tarinfo = tarfile.TarInfo(name=path)
        tarinfo.size = len(file_data)
        tar.addfile(tarinfo, io.BytesIO(file_data))
        tar.close()

        # Upload to container
        tar_stream.seek(0)
        container.put_archive("/workspace/project", tar_stream)

    async def read_file(self, container_name: str, path: str) -> str:
        """Read a file from the container."""
        container = self.docker_client.containers.get(container_name)

        # Download file as tar archive
        bits, stat = container.get_archive(f"/workspace/project/{path}")

        # Extract content
        import tarfile
        import io

        tar_stream = io.BytesIO(b"".join(bits))
        tar = tarfile.open(fileobj=tar_stream)
        file_obj = tar.extractfile(path)
        content = file_obj.read().decode('utf-8')

        return content

    async def pause_sandbox(self, container_name: str):
        """Pause a running container."""
        container = self.docker_client.containers.get(container_name)
        container.pause()

    async def resume_sandbox(self, container_name: str):
        """Resume a paused container."""
        container = self.docker_client.containers.get(container_name)
        container.unpause()

    async def delete_sandbox(self, container_name: str):
        """Stop and remove a container."""
        container = self.docker_client.containers.get(container_name)

        # Stop container (10 second timeout)
        if container.status in ['running', 'paused']:
            container.stop(timeout=10)

        # Remove container
        container.remove()
```

### Docker Sandbox Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      HOST MACHINE                           │
│                                                             │
│  ┌───────────────────────────────────────────────────┐    │
│  │  OpenHands Backend (FastAPI)                      │    │
│  │  Port: 3000                                        │    │
│  └───────────────────┬───────────────────────────────┘    │
│                      │                                      │
│                      │ Docker API                           │
│                      │                                      │
│  ┌───────────────────▼───────────────────────────────┐    │
│  │  Docker Daemon                                     │    │
│  │                                                    │    │
│  │  ┌──────────────────────────────────────────┐    │    │
│  │  │  Container: oh-agent-server-abc123       │    │    │
│  │  │                                           │    │    │
│  │  │  Image: agent-server:latest              │    │    │
│  │  │  Ports: 8000→54321, 8001→54322          │    │    │
│  │  │  Volumes: /tmp/workspace → /workspace    │    │    │
│  │  │                                           │    │    │
│  │  │  ┌─────────────────────────────────┐    │    │    │
│  │  │  │  /workspace/project/            │    │    │    │
│  │  │  │  ├── app.py                     │    │    │    │
│  │  │  │  ├── requirements.txt           │    │    │    │
│  │  │  │  └── tests/                     │    │    │    │
│  │  │  └─────────────────────────────────┘    │    │    │
│  │  │                                           │    │    │
│  │  │  Processes:                              │    │    │
│  │  │  • Agent Server (port 8000)              │    │    │
│  │  │  • VS Code Server (port 8001)            │    │    │
│  │  │  • User code (python, node, etc.)        │    │    │
│  │  └──────────────────────────────────────────┘    │    │
│  └────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────┘
```

### Security Features

1. **Isolated Filesystem** - Container can't access host files (except mounted volumes)
2. **Network Isolation** - Container has its own network namespace
3. **Resource Limits** - Can limit CPU, memory, disk usage
4. **User Permissions** - Runs as non-root user inside container
5. **Read-only Mounts** - Can mount volumes as read-only

### Example: Complete Workflow

```python
# 1. Start sandbox
sandbox = await docker_service.start_sandbox("agent-server:latest")
# → Container created: oh-agent-server-abc123
# → Ports: 8000→54321, 8001→54322

# 2. Write code file
await docker_service.write_file(
    sandbox.id,
    "app.py",
    """
from flask import Flask
app = Flask(__name__)

@app.route('/')
def home():
    return 'Hello World!'

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8000)
"""
)

# 3. Install dependencies
result = await docker_service.execute_command(
    sandbox.id,
    "pip install flask"
)
print(result["output"])  # "Successfully installed Flask"

# 4. Run the app
result = await docker_service.execute_command(
    sandbox.id,
    "python app.py &"
)

# 5. Access the app
# http://localhost:54321 → Flask app running inside container

# 6. Clean up
await docker_service.delete_sandbox(sandbox.id)
```

---

## 🎯 Summary: How It All Works Together

### Complete Flow

```
1. USER TYPES: "Create a Flask app"
   ↓
2. FRONTEND (React + Monaco)
   • Chat input captures message
   • Sends to backend via WebSocket
   ↓
3. BACKEND (FastAPI)
   • Receives message
   • Creates/resumes Docker sandbox
   ↓
4. DOCKER SANDBOX
   • Isolated container starts
   • Agent server runs inside
   ↓
5. AGENT CONTROLLER
   • Calls agent.step(history)
   ↓
6. AGENT (AI Logic)
   • Builds prompt with system instructions + history
   • Sends to LLM (Ollama)
   • LLM responds: "<run>pip install flask</run>"
   • Parses into CmdRunAction
   ↓
7. RUNTIME (Docker Execution)
   • Executes command in container
   • Returns observation: "Successfully installed Flask"
   ↓
8. AGENT (Next Iteration)
   • LLM sees success
   • Responds: "<write path='app.py'>...</write>"
   • Parses into FileWriteAction
   ↓
9. RUNTIME
   • Writes file in container
   • Returns observation: "File created"
   ↓
10. FRONTEND (Monaco Editor)
    • Receives file content via WebSocket
    • Displays in Monaco editor with syntax highlighting
    • User can edit and save changes
    ↓
11. AGENT (Final Iteration)
    • LLM responds: "<finish>Task complete!</finish>"
    • Loop ends
```

### Technologies Summary

| Component | Technology | Purpose |
|-----------|-----------|---------|
| **Agent Logic** | Custom Python + AsyncIO | AI decision making |
| **LLM Integration** | Direct API calls (Ollama/OpenAI) | Get AI responses |
| **Monaco Editor** | @monaco-editor/react | Code editing in browser |
| **Docker Sandbox** | docker-py SDK | Isolated code execution |
| **Backend** | FastAPI + Python | API server |
| **Frontend** | React + TypeScript | User interface |
| **WebSocket** | FastAPI WebSocket | Real-time updates |
| **State Management** | Zustand | Frontend state |

---

## 🚀 Building Your Own System

### Minimal Implementation (500 lines of code!)

```python
# backend/main.py
from fastapi import FastAPI, WebSocket
import docker
import ollama

app = FastAPI()
docker_client = docker.from_env()

@app.websocket("/ws")
async def websocket_endpoint(websocket: WebSocket):
    await websocket.accept()

    # Start Docker container
    container = docker_client.containers.run(
        "python:3.11",
        command="sleep infinity",
        detach=True,
        volumes={'/workspace': {'bind': '/workspace', 'mode': 'rw'}}
    )

    history = []

    while True:
        # Receive user message
        user_msg = await websocket.receive_text()
        history.append({"role": "user", "content": user_msg})

        # Agent loop
        while True:
            # Ask LLM
            response = ollama.chat(
                model="qwen2.5-coder:7b",
                messages=[
                    {"role": "system", "content": "You are a coding assistant. Use <run>command</run> or <write path='file'>content</write> or <finish>message</finish>"},
                    *history
                ]
            )

            llm_text = response["message"]["content"]

            # Parse action
            if "<run>" in llm_text:
                cmd = extract_between(llm_text, "<run>", "</run>")
                result = container.exec_run(cmd)
                obs = result.output.decode()
                history.append({"role": "assistant", "content": llm_text})
                history.append({"role": "system", "content": f"Output: {obs}"})
                await websocket.send_text(f"Ran: {cmd}\nOutput: {obs}")

            elif "<write>" in llm_text:
                path = extract_attr(llm_text, "path")
                content = extract_between(llm_text, "<write", "</write>")
                # Write file to container...
                await websocket.send_text(f"Created: {path}")

            elif "<finish>" in llm_text:
                await websocket.send_text("Task complete!")
                break
```

```typescript
// frontend/src/App.tsx
import { Editor } from "@monaco-editor/react";
import { useState, useEffect } from "react";

function App() {
  const [messages, setMessages] = useState([]);
  const [code, setCode] = useState("");
  const [ws, setWs] = useState(null);

  useEffect(() => {
    const websocket = new WebSocket("ws://localhost:8000/ws");
    websocket.onmessage = (event) => {
      setMessages(prev => [...prev, event.data]);
    };
    setWs(websocket);
  }, []);

  const sendMessage = (msg) => {
    ws.send(msg);
  };

  return (
    <div className="flex h-screen">
      {/* Chat */}
      <div className="w-1/2 p-4">
        <div className="messages">
          {messages.map((msg, i) => <div key={i}>{msg}</div>)}
        </div>
        <input onKeyPress={(e) => {
          if (e.key === 'Enter') sendMessage(e.target.value);
        }} />
      </div>

      {/* Code Editor */}
      <div className="w-1/2">
        <Editor
          height="100%"
          language="python"
          value={code}
          onChange={setCode}
          theme="vs-dark"
        />
      </div>
    </div>
  );
}
```

That's it! **~500 lines** for a basic AI coding assistant!

---

**Questions?** Let me know which part you want to explore further!
