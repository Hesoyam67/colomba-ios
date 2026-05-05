# GPT-Only Agent Queue

## 1. Conductor
- owner: Papu + ChatGPT
- model: ChatGPT Pro / GPT-5.5
- job: planning, command writing, review
- writes code: no

## 2. Heso-Coder
- owner: OpenClaw main agent
- model: openai-codex/gpt-5.5
- reasoning_effort: xhigh
- fallback: openai-codex/gpt-5.4
- job: one branch, one PR, scoped code implementation
- writes code: yes
- active limit: one Swift coder during STABILIZE

## 3. Heso-Gatekeeper
- model: openai-codex/gpt-5.5 or script-only
- job: run gates, collect logs
- writes code: no
- active limit: one xcodebuild/simulator gate at a time

## 4. Heso-Statekeeper
- model: openai-codex/gpt-5.5
- reasoning_effort: xhigh
- fallback: openai-codex/gpt-5.4
- job: update state files
- allowed files: state/*.md only
- writes code: no

## 5. Backend Contract Agent
- model: openai-codex/gpt-5.5
- activate only when backend contract blocks iOS
- job: endpoint/payload/response/error mapping
- writes iOS code: no

## Safe parallelism
- 3 active agents maximum by default.
- Only one code-writing agent.
- Only one full simulator gate.
- Statekeeper can run parallel if touching only state files.
