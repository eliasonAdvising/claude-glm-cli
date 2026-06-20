# T1: API config transcription

Build a JSON file `endpoints.json` that transcribes the structured endpoint spec below into a normalized config. Pure transcription — no design choices.

## Input — five endpoints, three retry policies

**Endpoints** (transcribe verbatim into `endpoints[]`, in this exact order):

| name | method | path | retry_policy | timeout_ms |
|---|---|---|---|---|
| create_user | POST | /v1/users | aggressive | 5000 |
| get_user | GET | /v1/users/:id | gentle | 2000 |
| update_user | PATCH | /v1/users/:id | gentle | 3000 |
| delete_user | DELETE | /v1/users/:id | none | 5000 |
| list_users | GET | /v1/users | gentle | 8000 |

**Retry policies** (transcribe verbatim into `retry_policies` object):

- `aggressive`: max_attempts 5, backoff_ms 100, jitter 0.2
- `gentle`: max_attempts 3, backoff_ms 500, jitter 0.1
- `none`: max_attempts 1, backoff_ms 0, jitter 0

**Env vars** (transcribe verbatim into `env`, in this exact order):

- `API_BASE_URL` (type: string, default: "https://api.example.com", required: true)
- `API_TIMEOUT_MS` (type: number, default: 5000, required: false)
- `API_RETRY_ENABLED` (type: boolean, default: true, required: false)

## Required structure

```json
{
  "version": "1.0.0",
  "endpoints": [ { ... 5 entries ... } ],
  "retry_policies": { "aggressive": {...}, "gentle": {...}, "none": {...} },
  "env": [ { ... 3 entries ... } ]
}
```

Top-level fields in this exact order: `version`, `endpoints`, `retry_policies`, `env`.

Each endpoint entry: `name`, `method`, `path`, `retry_policy`, `timeout_ms` — exact key order.

Each env entry: `key`, `type`, `default`, `required` — exact key order.

## Build a validator

Build `validate.sh` (bash + jq, executable) that checks:
1. `endpoints.json` exists and parses as JSON
2. Top-level fields exactly: `version`, `endpoints`, `retry_policies`, `env`
3. `endpoints` array length = 5
4. Each endpoint has all 5 required fields
5. `retry_policies` has all 3 named policies with all 3 fields each
6. `env` array length = 3
7. Each env entry has all 4 required fields
8. `API_BASE_URL` is required: true
9. `aggressive` policy has max_attempts: 5
10. `delete_user` uses retry_policy: none

Print `PASS <n>` per check, exit 0 only if all 10 pass.

## Acceptance

```
jq empty endpoints.json
bash -n validate.sh
./validate.sh
```
