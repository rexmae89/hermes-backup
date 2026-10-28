---
name: custom-model-router-setup
description: Use when adding a custom model router to Hermes config.
---

# Adding a custom OpenAI-compatible router to Hermes

## Procedure

1. Verify the router and key before configuring anything:
   `curl -s <base>/v1/models -H "Authorization: Bearer <key>"` — save to a file and count/inspect IDs with Python (routers can list 500+ models; never paste the full list into chat).
2. Probe 3-5 representative models with a real chat completion (use raw `urllib` in Python; catch `urllib.error.HTTPError` specifically and read `e.read().decode('utf-8')` to parse the error JSON, as routers frequently return 402 `insufficient_tokens`, 403 forbidden model, or 410/503 upstream errors. Some routers also force SSE streaming even for non-stream requests, so parse defensively — read the raw body and handle both JSON and `data:` lines, and non-standard wrapper shapes like `{"data": {"choices": ...}}`). Report to the user which models actually respond and exact billing/balance error messages if present.
3. Put the key in `~/.hermes/.env` as a named env var, NEVER raw inside config.yaml.
4. Decide how models will be accessed:
   - **For direct switching only (`/model <alias>`):** Add as `model_aliases`:
     ```
     hermes config set --force 'model_aliases.<alias>' '{"model":"<id>","provider":"custom","base_url":"<base>/v1","key_env":"<KEY_VAR>"}'
     ```
   - **To expose models in the interactive `/model` picker list:** `model_aliases` will NOT appear in the UI picker. To make them visible in the list, register each model as an individual entry under `providers:` in `config.yaml`:
     ```yaml
     providers:
       <provider_name>:
         name: <provider_name>
         base_url: <base>/v1
         key_env: <KEY_VAR>
         api_mode: chat_completions
         model: "<model_id>"
         model_display_name: "<Display Name>"
     ```
5. Verify with `hermes config get model_aliases` or `yaml.safe_load` on config.yaml and confirm no raw key string appears (`grep -c <key-prefix>` = 0). Remind the user to run `/restart` to reload the gateway so newly registered providers appear in `/model`.

## Pitfalls

- **Model aliases do NOT appear in the `/model` picker menu:** Aliases under `model_aliases` only work when explicitly typed (`/model <alias>`). If the user asks why the model list does not show their router models, explain that only `providers:` entries are rendered in the picker, and configure them under `providers.` instead.
- **Gateway restart required:** After editing `config.yaml` to add `providers:` entries, the running gateway does not hot-reload them; the user must run `/restart`.
- **Diagnosing "Your request was not processed":** When switching to a custom router model in a messaging gateway (e.g. Telegram) and every message returns `"Your request was not processed. Send it again if you still want me to carry it out."`, check `~/.hermes/logs/errors.log` and `~/.hermes/logs/agent.log`. The gateway surfaces this generic transient message on:
  1. `429 quota_exceeded` / `402 insufficient_tokens`: token quota or balance exhausted.
  2. `403 Forbidden`: WAF / body size limits (e.g. nginx on host blocking huge tool schemas or headers).
  3. **Broken Tool Calling in vLLM / custom endpoints:** Many self-hosted endpoints accept `tools` in the request without throwing an error, but return `finish_reason: "tool_calls"` with `content: null` and NO `tool_calls` array (`completion_tokens: 0`). This trips dropped tool-call recovery in Hermes, exhausts 3 retries, and fails. Always probe with a sample tool call before registering.
- **Environment and Gateway process caching:** Editing `~/.hermes/.env` updates the disk file, but the running gateway service process retains its boot environment variables in `os.environ`. After replacing or adding an API key in `.env` (or modifying provider configs), the user must send `/restart` in Telegram to reload the process environment.
- **Resetting exhausted credential pools:** When a provider hits a quota limit, Hermes may track the credential cooldown in `~/.hermes/auth.json`. After updating a key, run `hermes auth reset <provider>` to immediately clear any exhaustion flag.
- `model_aliases.<x>` is refused without `--force` — the CLI suggests `model_overrides.<x>` instead, which is the WRONG key. Use `--force` and set the exact `model_aliases` path.
- After the key is already stored, a later set of the same alias may echo the key redacted into the value if you passed it as `api_key`; always prefer `key_env` referencing the `.env` var.
- Aliases only resolve in NEW sessions — tell the user to start a fresh session or use `/model <alias>` per-session.
