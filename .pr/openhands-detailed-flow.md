# OpenHands Detailed Flow: How It Works

## 🎯 Your Goal
Build an AI agent system that:
1. Takes SRS document or application idea as input
2. Generates complete application code
3. Provides VS Code-like environment for editing
4. Tests and validates the code

---

## 📊 OpenHands Complete Flow Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                         USER INTERFACE                          │
│  (React Frontend - frontend/src/)                               │
│                                                                 │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐        │
│  │ Chat Input   │  │ Code Editor  │  │ File Browser │        │
│  │ (Monaco)     │  │ (Monaco)     │  │              │        │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘        │
│         │                  │                  │                 │
└─────────┼──────────────────┼──────────────────┼─────────────────┘
          │                  │                  │
          │ WebSocket        │ HTTP API         │ HTTP API
          │                  │                  │
┌─────────▼──────────────────▼──────────────────▼─────────────────┐
│                      BACKEND API SERVER                          │
│  (FastAPI - openhands/app_server/)                              │
│                                                                  │
│  ┌────────────────────────────────────────────────────────┐    │
│  │  Routes (routes/)                                       │    │
│  │  • /api/v1/conversations - Create/manage conversations │    │
│  │  • /api/v1/messages - Send/receive messages            │    │
│  │  • /api/v1/files - File operations                     │    │
│  │  • /ws - WebSocket for real-time events                │    │
│  └────────────────────┬───────────────────────────────────┘    │
│                       │                                          │
└───────────────────────┼──────────────────────────────────────────┘
                        │
                        │ Creates & Manages
                        │
┌───────────────────────▼──────────────────────────────────────────┐
│                    AGENT CONTROLLER                              │
│  (openhands/controller/agent_controller.py)                     │
│                                                                  │
│  Main Loop:                                                      │
│  1. Receive user message                                         │
│  2. Add to conversation history                                  │
│  3. Call Agent.step()                                            │
│  4. Execute action                                               │
│  5. Get observation                                              │
│  6. Repeat until task complete                                   │
│                                                                  │
│  ┌────────────────────────────────────────────────────────┐    │
│  │  State Management:                                      │    │
│  │  • Conversation history                                 │    │
│  │  • Current task                                         │    │
│  │  • Agent state (running/paused/stopped)                │    │
│  └────────────────────┬───────────────────────────────────┘    │
└───────────────────────┼──────────────────────────────────────────┘
                        │
                        │ Calls
                        │
┌───────────────────────▼──────────────────────────────────────────┐
│                         AGENT                                    │
│  (openhands/agenthub/codeact_agent/)                            │
│                                                                  │
│  Agent.step():                                                   │
│  1. Build prompt with:                                           │
│     • System prompt (agent's instructions)                       │
│     • Conversation history                                       │
│     • Available actions                                          │
│     • Current workspace state                                    │
│  2. Send to LLM                                                  │
│  3. Parse LLM response                                           │
│  4. Return Action object                                         │
│                                                                  │
│  ┌────────────────────────────────────────────────────────┐    │
│  │  System Prompt (prompt.py):                            │    │
│  │  "You are a software engineer. You can:                │    │
│  │   - Read/write files                                    │    │
│  │   - Run commands                                        │    │
│  │   - Browse web                                          │    │
│  │   Use these actions to complete tasks."                │    │
│  └────────────────────┬───────────────────────────────────┘    │
└───────────────────────┼──────────────────────────────────────────┘
                        │
                        │ Sends prompt to
                        │
┌───────────────────────▼──────────────────────────────────────────┐
│                      LLM INTEGRATION                             │
│  (openhands/llm/llm.py)                                         │
│                                                                  │
│  Supports multiple providers:                                    │
│  • OpenAI (GPT-4, GPT-3.5)                                      │
│  • Anthropic (Claude)                                            │
│  • Ollama (Local models) ← YOUR SETUP                          │
│  • Google (Gemini)                                               │
│  • Azure OpenAI                                                  │
│                                                                  │
│  ┌────────────────────────────────────────────────────────┐    │
│  │  LLM.completion():                                      │    │
│  │  1. Format messages for provider                        │    │
│  │  2. Add function calling schema (if supported)          │    │
│  │  3. Send HTTP request to LLM API                        │    │
│  │  4. Parse response                                       │    │
│  │  5. Return text + function calls                        │    │
│  └────────────────────┬───────────────────────────────────┘    │
└───────────────────────┼──────────────────────────────────────────┘
                        │
                        │ Returns Action
                        │
┌───────────────────────▼──────────────────────────────────────────┐
│                    ACTION EXECUTION                              │
│  (openhands/events/action.py)                                   │
│                                                                  │
│  Action Types:                                                   │
│  ┌──────────────────────────────────────────────────────┐      │
│  │ • CmdRunAction - Run shell command                    │      │
│  │ • FileReadAction - Read file contents                 │      │
│  │ • FileWriteAction - Write/edit file                   │      │
│  │ • BrowseURLAction - Browse web page                   │      │
│  │ • AgentThinkAction - Agent reasoning                  │      │
│  │ • AgentFinishAction - Task complete                   │      │
│  └──────────────────────────────────────────────────────┘      │
│                                                                  │
│  Example:                                                        │
│  Action: FileWriteAction(                                        │
│    path="app.py",                                                │
│    content="print('Hello World')"                                │
│  )                                                               │
└───────────────────────┼──────────────────────────────────────────┘
                        │
                        │ Executes in
                        │
┌───────────────────────▼──────────────────────────────────────────┐
│                    RUNTIME / SANDBOX                             │
│  (openhands/runtime/)                                           │
│                                                                  │
│  Isolated Docker Container:                                      │
│  • Separate filesystem                                           │
│  • Limited resources                                             │
│  • Network isolation                                             │
│  • User permissions                                              │
│                                                                  │
│  ┌────────────────────────────────────────────────────────┐    │
│  │  Runtime.run_action():                                  │    │
│  │  1. Validate action                                     │    │
│  │  2. Execute in sandbox:                                 │    │
│  │     • File operations → filesystem                      │    │
│  │     • Commands → bash/python/node                       │    │
│  │     • Web → browser automation                          │    │
│  │  3. Capture output                                      │    │
│  │  4. Return Observation                                  │    │
│  └────────────────────┬───────────────────────────────────┘    │
└───────────────────────┼──────────────────────────────────────────┘
                        │
                        │ Returns
                        │
┌───────────────────────▼──────────────────────────────────────────┐
│                      OBSERVATION                                 │
│  (openhands/events/observation.py)                              │
│                                                                  │
│  Observation Types:                                              │
│  ┌──────────────────────────────────────────────────────┐      │
│  │ • CmdOutputObservation - Command output               │      │
│  │ • FileReadObservation - File contents                 │      │
│  │ • FileWriteObservation - Write confirmation           │      │
│  │ • BrowserOutputObservation - Web page content         │      │
│  │ • ErrorObservation - Error messages                   │      │
│  └──────────────────────────────────────────────────────┘      │
│                                                                  │
│  Example:                                                        │
│  Observation: CmdOutputObservation(                              │
│    command="python app.py",                                      │
│    exit_code=0,                                                  │
│    output="Hello World"                                          │
│  )                                                               │
└───────────────────────┼──────────────────────────────────────────┘
                        │
                        │ Feeds back to
                        │
                   ┌────▼────┐
                   │  AGENT  │ ← Loop continues
                   └─────────┘
```

---

## 🔄 Complete Request Flow Example

### User Request: "Create a Flask web app with a homepage"

```
Step 1: User Input
├─ User types in chat: "Create a Flask web app with a homepage"
└─ Frontend sends to: POST /api/v1/messages

Step 2: Controller Receives
├─ AgentController.add_message()
├─ Adds to conversation history
└─ Calls Agent.step()

Step 3: Agent Thinks (First Iteration)
├─ Builds prompt:
│  System: "You are a software engineer..."
│  History: [User: "Create a Flask web app..."]
│  Available actions: [CmdRun, FileWrite, FileRead, ...]
│
├─ Sends to LLM (Ollama)
│
└─ LLM responds:
   "I'll create a Flask app. First, let me check if Flask is installed."
   Action: CmdRunAction(command="pip list | grep Flask")

Step 4: Execute Action
├─ Runtime receives CmdRunAction
├─ Executes in sandbox: "pip list | grep Flask"
└─ Returns: CmdOutputObservation(output="Flask not found", exit_code=1)

Step 5: Agent Thinks (Second Iteration)
├─ Prompt now includes:
│  Previous action: CmdRun "pip list | grep Flask"
│  Observation: "Flask not found"
│
├─ LLM responds:
   "Flask is not installed. I'll install it."
   Action: CmdRunAction(command="pip install flask")
│
└─ Execute → Observation: "Successfully installed Flask"

Step 6: Agent Thinks (Third Iteration)
├─ LLM responds:
   "Now I'll create the Flask app file."
   Action: FileWriteAction(
     path="app.py",
     content="""
from flask import Flask
app = Flask(__name__)

@app.route('/')
def home():
    return '<h1>Welcome to my Flask App!</h1>'

if __name__ == '__main__':
    app.run(debug=True)
"""
   )
│
└─ Execute → Observation: "File created successfully"

Step 7: Agent Thinks (Fourth Iteration)
├─ LLM responds:
   "Let me test the app."
   Action: CmdRunAction(command="python app.py &")
│
└─ Execute → Observation: "Server running on http://127.0.0.1:5000"

Step 8: Agent Finishes
├─ LLM responds:
   "Task complete! I've created a Flask web app with a homepage."
   Action: AgentFinishAction()
│
└─ Controller stops loop
```

---

## 🏗️ How to Build Your Own System

### Phase 1: Core Components

#### 1. **Backend API Server** (Python + FastAPI)
```python
# main.py
from fastapi import FastAPI, WebSocket
from pydantic import BaseModel

app = FastAPI()

class Message(BaseModel):
    content: str
    conversation_id: str

@app.post("/api/messages")
async def send_message(message: Message):
    # 1. Receive user message
    # 2. Pass to Agent Controller
    # 3. Return response
    pass

@app.websocket("/ws")
async def websocket_endpoint(websocket: WebSocket):
    # Real-time event streaming
    await websocket.accept()
    # Stream agent actions/observations
```

#### 2. **Agent Controller** (Orchestration)
```python
# controller.py
class AgentController:
    def __init__(self, agent, runtime):
        self.agent = agent
        self.runtime = runtime
        self.history = []

    async def run(self, user_message):
        self.history.append({"role": "user", "content": user_message})

        while True:
            # Get next action from agent
            action = await self.agent.step(self.history)

            if action.type == "finish":
                break

            # Execute action in runtime
            observation = await self.runtime.execute(action)

            # Add to history
            self.history.append({
                "role": "assistant",
                "action": action,
                "observation": observation
            })

        return self.history
```

#### 3. **Agent** (AI Decision Making)
```python
# agent.py
class CodeAgent:
    def __init__(self, llm):
        self.llm = llm
        self.system_prompt = """
You are an AI software engineer. You can:
- read_file(path) - Read file contents
- write_file(path, content) - Create/edit files
- run_command(cmd) - Execute shell commands
- finish(message) - Complete the task

Given a task, break it down and use these actions to complete it.
"""

    async def step(self, history):
        # Build prompt
        prompt = self.build_prompt(history)

        # Get LLM response
        response = await self.llm.complete(prompt)

        # Parse action from response
        action = self.parse_action(response)

        return action

    def build_prompt(self, history):
        messages = [{"role": "system", "content": self.system_prompt}]
        messages.extend(history)
        return messages

    def parse_action(self, response):
        # Parse LLM response to extract action
        # Example: "I'll run: pip install flask"
        # → CmdRunAction(command="pip install flask")
        pass
```

#### 4. **LLM Integration** (Ollama/OpenAI)
```python
# llm.py
import requests

class OllamaLLM:
    def __init__(self, model="qwen2.5-coder:7b"):
        self.model = model
        self.base_url = "http://localhost:11434"

    async def complete(self, messages):
        response = requests.post(
            f"{self.base_url}/api/chat",
            json={
                "model": self.model,
                "messages": messages,
                "stream": False
            }
        )
        return response.json()["message"]["content"]
```

#### 5. **Runtime / Sandbox** (Docker)
```python
# runtime.py
import docker

class DockerRuntime:
    def __init__(self):
        self.client = docker.from_env()
        self.container = self.create_container()

    def create_container(self):
        return self.client.containers.run(
            "python:3.11",
            command="sleep infinity",
            detach=True,
            volumes={'/workspace': {'bind': '/workspace', 'mode': 'rw'}}
        )

    async def execute(self, action):
        if action.type == "run_command":
            result = self.container.exec_run(action.command)
            return {
                "output": result.output.decode(),
                "exit_code": result.exit_code
            }

        elif action.type == "write_file":
            # Write file in container
            pass

        elif action.type == "read_file":
            # Read file from container
            pass
```

### Phase 2: Frontend (React + Monaco Editor)

#### 1. **Chat Interface**
```typescript
// Chat.tsx
import { useState } from 'react';

export function Chat() {
  const [messages, setMessages] = useState([]);
  const [input, setInput] = useState('');

  const sendMessage = async () => {
    const response = await fetch('/api/messages', {
      method: 'POST',
      body: JSON.stringify({ content: input })
    });

    const data = await response.json();
    setMessages([...messages, data]);
  };

  return (
    <div>
      <MessageList messages={messages} />
      <input value={input} onChange={e => setInput(e.target.value)} />
      <button onClick={sendMessage}>Send</button>
    </div>
  );
}
```

#### 2. **Code Editor** (Monaco - VS Code's editor)
```typescript
// CodeEditor.tsx
import Editor from '@monaco-editor/react';

export function CodeEditor({ file, onChange }) {
  return (
    <Editor
      height="90vh"
      language={file.language}
      value={file.content}
      onChange={onChange}
      theme="vs-dark"
      options={{
        minimap: { enabled: true },
        fontSize: 14,
        lineNumbers: 'on',
        automaticLayout: true
      }}
    />
  );
}
```

#### 3. **File Browser**
```typescript
// FileBrowser.tsx
export function FileBrowser({ files, onFileSelect }) {
  return (
    <div className="file-tree">
      {files.map(file => (
        <div key={file.path} onClick={() => onFileSelect(file)}>
          {file.name}
        </div>
      ))}
    </div>
  );
}
```

---

## 🎯 For SRS-Based Application Generation

### Enhanced Agent Prompt for SRS Processing

```python
SYSTEM_PROMPT = """
You are an AI software architect and developer.

When given an SRS (Software Requirements Specification) document, you will:

1. ANALYZE PHASE:
   - Read and understand all requirements
   - Identify functional and non-functional requirements
   - Determine technology stack
   - Plan project structure

2. DESIGN PHASE:
   - Create folder structure
   - Design database schema (if needed)
   - Plan API endpoints
   - Design UI components

3. IMPLEMENTATION PHASE:
   - Create configuration files (package.json, requirements.txt, etc.)
   - Implement backend (API, database, business logic)
   - Implement frontend (UI components, pages)
   - Add tests

4. VALIDATION PHASE:
   - Run tests
   - Check for errors
   - Verify requirements are met

Available actions:
- read_file(path)
- write_file(path, content)
- run_command(cmd)
- create_directory(path)
- finish(message)

Break down the SRS into tasks and complete them step by step.
"""
```

### Example SRS Processing Flow

```
User uploads SRS: "E-commerce website with user auth, product catalog, cart"

Agent Step 1: Analyze
├─ Action: AgentThink("I'll create an e-commerce site with:
│           - Backend: Node.js + Express + MongoDB
│           - Frontend: React
│           - Features: Auth, Products, Cart")

Agent Step 2: Create Structure
├─ Action: run_command("mkdir -p backend frontend")
├─ Action: run_command("cd backend && npm init -y")
├─ Action: run_command("cd frontend && npx create-react-app .")

Agent Step 3: Backend - Auth
├─ Action: write_file("backend/models/User.js", "...")
├─ Action: write_file("backend/routes/auth.js", "...")
├─ Action: write_file("backend/middleware/auth.js", "...")

Agent Step 4: Backend - Products
├─ Action: write_file("backend/models/Product.js", "...")
├─ Action: write_file("backend/routes/products.js", "...")

Agent Step 5: Backend - Cart
├─ Action: write_file("backend/models/Cart.js", "...")
├─ Action: write_file("backend/routes/cart.js", "...")

Agent Step 6: Frontend - Components
├─ Action: write_file("frontend/src/components/Login.jsx", "...")
├─ Action: write_file("frontend/src/components/ProductList.jsx", "...")
├─ Action: write_file("frontend/src/components/Cart.jsx", "...")

Agent Step 7: Test
├─ Action: run_command("cd backend && npm test")
├─ Action: run_command("cd frontend && npm test")

Agent Step 8: Finish
└─ Action: finish("E-commerce application created successfully!")
```

---

## 📚 Key Technologies You Need

### Backend
- **Python** - Main language
- **FastAPI** - Web framework
- **Docker SDK** - Container management
- **WebSockets** - Real-time communication
- **SQLite/PostgreSQL** - Database

### Frontend
- **React** - UI framework
- **Monaco Editor** - Code editor (VS Code's editor)
- **WebSocket** - Real-time updates
- **TanStack Query** - Data fetching
- **Tailwind CSS** - Styling

### AI/LLM
- **Ollama** - Local LLM (what you have)
- **LangChain** - LLM orchestration (optional)
- **OpenAI API** - Alternative LLM

### DevOps
- **Docker** - Containerization
- **Docker Compose** - Multi-container setup
- **Nginx** - Reverse proxy (optional)

---

## 🚀 Quick Start Template

```bash
# Project structure
my-ai-agent/
├── backend/
│   ├── main.py              # FastAPI server
│   ├── controller.py        # Agent controller
│   ├── agent.py             # AI agent logic
│   ├── llm.py               # LLM integration
│   ├── runtime.py           # Docker sandbox
│   └── requirements.txt
├── frontend/
│   ├── src/
│   │   ├── components/
│   │   │   ├── Chat.tsx
│   │   │   ├── CodeEditor.tsx
│   │   │   └── FileBrowser.tsx
│   │   └── App.tsx
│   └── package.json
└── docker-compose.yml
```

---

## 💡 Next Steps

1. **Study OpenHands Code**:
   - `openhands/controller/agent_controller.py` - Main loop
   - `openhands/agenthub/codeact_agent/` - Agent logic
   - `openhands/llm/llm.py` - LLM integration
   - `frontend/src/routes/app.tsx` - UI

2. **Build MVP**:
   - Simple chat interface
   - Basic agent that can run commands
   - File read/write operations
   - Docker sandbox

3. **Add Features**:
   - SRS document parsing
   - Project generation
   - Code editor integration
   - Testing automation

4. **Enhance**:
   - Multi-agent collaboration
   - Code review
   - Deployment automation
   - Version control integration

---

**Questions?** Let me know which part you want to dive deeper into!
