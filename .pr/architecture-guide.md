# OpenHands Architecture Guide

This guide explains the structure and purpose of each major component in the OpenHands repository.

## 🏗️ High-Level Architecture

OpenHands is an **AI-powered software engineering assistant** with:
- **Python Backend** (`openhands/`) - Core agent logic, LLM integration, runtime management
- **React Frontend** (`frontend/`) - Web UI for interacting with the agent
- **Enterprise Extensions** (`enterprise/`) - Authentication, billing, integrations (Slack, GitHub, etc.)
- **VSCode Extension** (`openhands/app_server/integrations/vscode/`) - IDE integration

---

## 📁 Root Directory Structure

### Configuration Files
- **`pyproject.toml`** - Python project dependencies and build configuration (Poetry)
- **`Makefile`** - Build, test, and run commands (`make build`, `make run`, etc.)
- **`config.template.toml`** - Template for user configuration settings
- **`.gitignore`** - Files to exclude from version control
- **`.editorconfig`** - Code formatting rules across editors

### Documentation
- **`README.md`** - Project overview and quick start
- **`CONTRIBUTING.md`** - How to contribute to the project
- **`Development.md`** - Development setup and guidelines
- **`AGENTS.md`** - **⭐ KEY FILE** - Detailed development rules and patterns (you're reading from this!)
- **`COMMUNITY.md`** - Community resources and links
- **`CODE_OF_CONDUCT.md`** - Community behavior guidelines

### Build & Deployment
- **`build.sh`** - Build script for Docker images
- **`containers/`** - Docker configurations for different environments
  - `app/` - Main application container
  - `runtime/` - Sandbox runtime environments

---

## 🐍 Backend: `openhands/` Directory

The Python backend is the **core of OpenHands**. Here's what each subdirectory does:

### Core Agent Logic
- **`openhands/agenthub/`** - Different agent implementations
  - `codeact_agent/` - Main coding agent that writes and executes code
  - `browsing_agent/` - Agent for web browsing tasks
  - Each agent has its own prompts and action handling

- **`openhands/controller/`** - Orchestrates agent execution
  - Manages conversation state
  - Handles action/observation loops
  - Controls agent lifecycle

- **`openhands/events/`** - Event system for agent actions
  - `action.py` - Actions the agent can take (run command, edit file, etc.)
  - `observation.py` - Observations from the environment (command output, file contents, etc.)
  - `stream.py` - Event streaming to frontend

### LLM Integration
- **`openhands/llm/`** - Language model integration
  - `llm.py` - Main LLM interface (supports OpenAI, Anthropic, etc.)
  - Model configuration and feature support
  - Prompt caching and function calling

### Runtime & Sandbox
- **`openhands/runtime/`** - Execution environments
  - `client/` - Runtime client interface
  - `plugins/` - Runtime plugins (JupyterPlugin, AgentSkillsPlugin, etc.)
  - Manages isolated sandboxes for code execution

### Storage & Persistence
- **`openhands/storage/`** - Data persistence layer
  - `data_models/` - Database models (conversations, settings, etc.)
  - `files.py` - File storage management
  - `conversation/` - Conversation history storage

### API Server
- **`openhands/app_server/`** - Web API server (FastAPI)
  - `routes/` - API endpoints
  - `session/` - Session management
  - `integrations/vscode/` - VSCode extension backend
  - **V1 API** - Current production API

### Utilities
- **`openhands/utils/`** - Shared utilities
  - `async_utils.py` - Async helpers
  - `microagent.py` - Microagent loading
  - `llm.py` - LLM utility functions

### CLI
- **`openhands/cli/`** - Command-line interface
  - Interactive mode for running OpenHands from terminal

---

## ⚛️ Frontend: `frontend/` Directory

The React-based web UI for OpenHands.

### Key Directories
- **`frontend/src/`** - Main source code
  - **`components/`** - Reusable UI components
    - `chat/` - Chat interface components
    - `features/` - Feature-specific components (file explorer, terminal, etc.)

  - **`routes/`** - Page-level components (React Router)
    - `app.tsx` - Main conversation interface
    - `app-settings.tsx` - Settings page

  - **`hooks/`** - Custom React hooks
    - `query/` - Data fetching hooks (TanStack Query)
    - `mutation/` - Data mutation hooks
    - `use-agent-state.ts` - Agent state management

  - **`api/`** - API client methods (never call directly from components!)
    - Always wrap with TanStack Query hooks

  - **`state/`** - Global state management
    - `chat-slice.ts` - Chat state (messages, actions)
    - `settings-slice.ts` - User settings

  - **`types/`** - TypeScript type definitions
    - `action-type.ts` - Agent action types
    - `settings.ts` - Settings types

  - **`i18n/`** - Internationalization
    - `translation.json` - Translation strings
    - `declaration.ts` - i18n type declarations

### Build & Config
- **`package.json`** - Node dependencies and scripts
- **`vite.config.ts`** - Vite build configuration
- **`tsconfig.json`** - TypeScript configuration

---

## 🏢 Enterprise: `enterprise/` Directory

**Commercial features** extending the open-source core.

### Key Components
- **`enterprise/auth/`** - Authentication (Keycloak integration)
- **`enterprise/billing/`** - Stripe integration for subscriptions
- **`enterprise/integrations/`** - External service integrations
  - `github/` - GitHub app integration
  - `gitlab/` - GitLab integration
  - `slack/` - Slack notifications
  - `jira/` - Jira issue tracking
  - `linear/` - Linear issue tracking

- **`enterprise/storage/`** - Enterprise data models
- **`enterprise/migrations/`** - Database migrations (Alembic)
- **`enterprise/telemetry/`** - Analytics and metrics

### Testing
- **`enterprise/tests/`** - Enterprise test suite
  - Use SQLite in-memory for unit tests
  - Mock external services

---

## 🔧 VSCode Extension: `openhands/app_server/integrations/vscode/`

IDE integration for OpenHands.

### Structure
- **`src/`** - Extension source code
  - `extension.ts` - Main extension entry point
  - `panels/` - Webview panels
  - `commands/` - VSCode commands

- **`package.json`** - Extension manifest and dependencies
- **`tsconfig.json`** - TypeScript configuration

---

## 🧪 Testing: `tests/` Directory

### Structure
- **`tests/unit/`** - Unit tests (pytest)
  - Mirror the `openhands/` structure
  - Test individual components in isolation

- **`tests/integration/`** - Integration tests
  - Test component interactions
  - May require running services

### Running Tests
```bash
# Backend unit tests
poetry run pytest tests/unit/test_xxx.py

# Frontend tests
cd frontend && npm run test

# Enterprise tests
cd enterprise && poetry run pytest tests/unit/
```

---

## 🐳 Containers: `containers/` Directory

Docker configurations for different environments.

- **`containers/app/`** - Main application container
  - `Dockerfile` - Application image
  - `entrypoint.sh` - Container startup script

- **`containers/runtime/`** - Sandbox runtime containers
  - Different base images for code execution

---

## 🤖 GitHub Workflows: `.github/workflows/`

CI/CD automation.

### Key Workflows
- **`py-tests.yml`** - Python test suite
- **`fe-unit-tests.yml`** - Frontend unit tests
- **`fe-e2e-tests.yml`** - Frontend E2E tests
- **`lint.yml`** - Code linting
- **`ghcr-build.yml`** - Docker image builds
- **`pr-artifacts.yml`** - PR artifact cleanup (`.pr/` directory)

---

## 🎯 Microagents: `.openhands/microagents/`

**Specialized prompts** for domain-specific tasks.

### Structure
- Markdown files with optional YAML frontmatter
- Can have trigger keywords for conditional loading
- Repository-specific knowledge

Example:
```yaml
---
triggers:
- documentation
- docs
---
# Documentation Microagent
Instructions for documentation tasks...
```

---

## 📊 Data Flow Architecture

```
User Request (Frontend)
    ↓
API Server (FastAPI)
    ↓
Controller (Orchestration)
    ↓
Agent (Decision Making)
    ↓
LLM (OpenAI/Anthropic/etc.)
    ↓
Actions (Run, Edit, Browse)
    ↓
Runtime/Sandbox (Execution)
    ↓
Observations (Results)
    ↓
Controller (Process Results)
    ↓
Frontend (Display to User)
```

---

## 🔑 Key Concepts

### 1. **Agent Loop**
- Agent receives task → Thinks → Takes action → Observes result → Repeats

### 2. **Events System**
- Actions: What the agent wants to do
- Observations: What happened after the action
- Streamed to frontend in real-time

### 3. **Runtime Isolation**
- Code executes in isolated Docker containers
- Prevents damage to host system
- Multiple runtime types (local, remote, etc.)

### 4. **Microagents**
- Specialized knowledge injected into agent context
- Triggered by keywords or always loaded
- Repository-specific or global

### 5. **Settings Patterns**
- **Immediate Save**: Entity-based (API keys, MCP servers)
- **Manual Save**: Form-based (LLM config, app settings)

---

## 🚀 Getting Started Workflow

1. **Setup**: `make build` (installs dependencies, builds frontend)
2. **Run**: `make run` (starts backend + frontend)
3. **Develop Backend**: Edit `openhands/`, run tests with `pytest`
4. **Develop Frontend**: Edit `frontend/src/`, run `npm run dev`
5. **Lint**: Pre-commit hooks ensure code quality
6. **Test**: Run relevant test suites before pushing

---

## 📚 Further Reading

- **AGENTS.md** - Detailed development guidelines (this file!)
- **Development.md** - Development environment setup
- **CONTRIBUTING.md** - Contribution process
- **API Documentation** - Check `openhands/app_server/routes/`

---

## 🎓 Learning Path

1. **Start with**: `README.md` → `AGENTS.md` → `Development.md`
2. **Explore**: Run `make build && make run` to see it in action
3. **Backend**: Read `openhands/controller/` and `openhands/agenthub/`
4. **Frontend**: Read `frontend/src/routes/app.tsx` and `frontend/src/components/chat/`
5. **Make Changes**: Follow pre-commit hooks and testing guidelines

---

**Questions?** Check the documentation files or ask in the community!
