# Review Tool Reference

Agents: pick tools based on what the diff contains. ★ = default (always run). Others = conditional on file types or patterns in the diff.

## Code Review

| Tool | Type | When to use |
|------|------|------------|
| ★ `code-reviewer` | agent | Always — standard quality, patterns, maintainability |
| ★ `/grill` | command | Always — quick adversarial pass |
| ★ `ensemble-review` | skill | Always — multi-reviewer consensus |
| ★ `verification-loop` | skill | Always — comprehensive verification |
| `/simplify` | command | When diff > 100 lines — check complexity and reuse |
| `staff-reviewer` | agent | Escalation — when ensemble disagrees or finding recurs 3x |
| `code-simplifier` | agent | When diff introduces new abstractions or complexity |
| `/review-changes` | command | When reviewing staged/uncommitted changes |
| `/double-check:verify` | command | When claims need spot-checking against source |
| `testing-strategies` | skill | When diff adds new modules without tests |
| `tdd-mastery` | skill | When diff has tests — verify TDD patterns |
| `tob-coverage-analysis` | skill | When test files changed — measure coverage gaps |
| `tob-property-based-testing` | skill | When diff has complex logic with edge cases |
| `tob-spec-to-code-compliance` | skill | When a plan/spec exists — verify code matches it |
| `tob-guidelines-advisor` | skill | When project has CLAUDE.md or coding conventions |
| `tob-code-maturity-assessor` | skill | When reviewing new modules — assess quality score |
| `tob-differential-review` | skill | When reviewing a diff specifically (not full files) |
| `test-architect` | agent | When test strategy needs redesigning |
| `qa-automation` | agent | When test automation patterns are involved |
| `testing-infrastructure` | agent | When test infra (fixtures, mocks, CI) is modified |
| `accessibility-wcag` | skill | When diff touches HTML, JSX, TSX, or CSS |
| `/a11y-audit:run-audit` | command | When diff touches frontend — automated scan |
| `accessibility-specialist` | agent | When accessibility findings need deep analysis |
| `compliance-checker` | agent | When diff touches auth, payments, PII, or regulated data |
| `dependency-manager` | agent | When package.json, requirements.txt, or Cargo.toml changed |
| `tob-supply-chain-risk-auditor` | skill | When new dependencies added |
| `/security:dependency-audit` | command | When lockfiles changed |
| `tooling-engineer` | agent | When linter/formatter config changed |
| `typescript-specialist` | agent | When .ts/.tsx files have complex generics or type issues |
| `python-engineer` | agent | When .py files have typing, async, or pattern issues |
| `setup-pre-commit` | skill | When .pre-commit-config.yaml or hooks changed |
| `continuous-learning` | skill | When review finds recurring patterns worth learning |
| `refine` | skill | After fixes applied — iterative refinement pass |
| `/code-guardian:review` | command | Alternative code quality scan |
| `/code-review-assistant:review` | command | Alternative code review |
| `gstack-pr-review` | skill | PR review with scope drift detection + fix-first flow |
| `gstack-qa` | skill | When reviewing a web app — live QA with browser (3 tiers) |

## Architecture Review

| Tool | Type | When to use |
|------|------|------------|
| ★ `architect-review` | skill | Always — structural decisions and trade-offs |
| ★ `/architecture:design-review` | command | Always — quick architecture assessment |
| ★ `tob-guidelines-advisor` | skill | Always — check against conventions |
| `gsd-plan-checker` | agent | When a plan is being reviewed for feasibility |
| `gsd-codebase-mapper` | agent | When reviewing unfamiliar codebase — map structure first |
| `gsd-integration-checker` | agent | When diff crosses module/service boundaries |
| `database-architect` | agent | When diff touches schema, migrations, or data models |
| `microservices-architect` | agent | When diff touches service boundaries or inter-service comms |
| `api-designer` | agent | When diff modifies API endpoints or contracts |
| `monorepo-architect` | agent | When diff affects workspace deps or monorepo structure |
| `event-driven-architect` | agent | When diff involves events, queues, or pub/sub |
| `devops-engineer` | agent | When diff touches Dockerfile, CI config, or infra |
| `cloud-architect` | agent | When diff touches cloud resources or IaC |
| `technical-writer` | agent | When docs need quality review |
| `/deploy-pilot:ci-pipeline` | command | When CI/CD pipeline config changed |
| `ci-cd-pipelines` | skill | When CI pipeline patterns need review |
| `docker-best-practices` | skill | When Dockerfile or docker-compose changed |
| `monitoring-observability` | skill | When logging, metrics, or alerting changed |
| `improve-codebase-architecture` | skill | When architecture improvements are needed |
| `tob-audit-context-building` | skill | When deep contextual analysis needed |
| `doc-maintenance` | skill | When code changed but docs not updated |
| `gstack-design-review` | skill | When frontend changed — visual QA with screenshots |

## Security Review

| Tool | Type | When to use |
|------|------|------------|
| ★ `tob-semgrep` | skill | Always — SAST primary scanner |
| ★ `/security:audit` | command | Always — quick security assessment |
| ★ `security-auditor` | agent | Always — deep security audit |
| `penetration-tester` | agent | When diff exposes new attack surface |
| `security-engineer` | agent | When auth, crypto, or security architecture changed |
| `security-researcher` | agent | When vulnerability research needed |
| `tob-codeql` | skill | When deep dataflow analysis needed (heavier than semgrep) |
| ★ `/security:secrets-scan` | command | Always — detect hardcoded secrets |
| `/security:dependency-audit` | command | When dependencies changed |
| `/code-guardian:security-scan` | command | Alternative security scan |
| `tob-supply-chain-risk-auditor` | skill | When new dependencies added |
| `tob-insecure-defaults` | skill | When config files or defaults changed |
| `tob-entry-point-analyzer` | skill | When new endpoints or entry points added |
| `tob-variant-analysis` | skill | When a vulnerability found — search for variants |
| `tob-sharp-edges` | skill | When using dangerous APIs (eval, exec, innerHTML) |
| `tob-agentic-actions-auditor` | skill | When agent tool definitions changed |
| `tob-fp-check` | skill | When finding recurs 3x — escalate false positive check |
| `tob-second-opinion` | skill | When ensemble disagrees — independent assessment |
| `tob-zeroize-audit` | skill | When diff handles secrets, keys, or tokens |
| `tob-token-integration-analyzer` | skill | When auth token flow changed |
| `tob-audit-prep-assistant` | skill | Before a formal security audit |
| `tob-testing-handbook-generator` | skill | When security test plan needed |
| `tob-constant-time-analysis` | skill | When crypto or password comparison code changed |
| `tob-constant-time-testing` | skill | When timing-sensitive code needs testing |
| `tob-wycheproof` | skill | When crypto implementation changed |
| `tob-yara-rule-authoring` | skill | When pattern detection rules needed |
| `gstack-guard` | skill | When reviewing commands that could be destructive |
| `gstack-careful` | skill | When diff includes rm, DROP, force-push, or reset |

## Plan Review

| Tool | Type | When to use |
|------|------|------------|
| ★ `/double-check:verify` | command | Always — spot-check claims against reality |
| ★ `verification-loop` | skill | Always — comprehensive plan verification |
| ★ `gsd-plan-checker` | agent | Always — feasibility and task decomposition |
| `gsd-verifier` | agent | When verifying plan achieved its stated goal |
| `technical-writer` | agent | When plan clarity or completeness is questionable |
| `confidence-calibration` | skill | When plan has uncertain estimates |
| `context-reliability` | skill | When plan references prior context that may be stale |
| `tob-spec-to-code-compliance` | skill | When checking if implementation matches plan |
| `doc-maintenance` | skill | When plan references docs that may be outdated |

## Prompt Review

| Tool | Type | When to use |
|------|------|------------|
| ★ `prompt-engineering` | skill | Always — structure, progressive disclosure, XML |
| ★ `prompt-engineer` | agent | Always — prompt optimization |
| `confidence-calibration` | skill | When prompt has confidence scoring |
| `context-reliability` | skill | When prompt manages large context windows |
| `information-provenance` | skill | When prompt makes claims that need sourcing |
| `/ai-prompt-lab:improve-prompt` | command | When prompt needs automated improvement |
| `/prompt-optimizer:analyze-prompt` | command | When prompt needs analysis |

## Performance Review

| Tool | Type | When to use |
|------|------|------------|
| ★ `performance-engineer` | agent | Always — general performance review |
| ★ `/perf-profiler:profile` | command | Always — quick profiling |
| `benchmarking-specialist` | agent | When benchmarks needed for comparison |
| `sre-engineer` | agent | When SLOs, error budgets, or reliability affected |
| `database-architect` | agent | When queries or schema changed |
| `database-optimizer` | agent | When query performance is the concern |
| `etl-specialist` | agent | When data pipeline changed |
| `/lighthouse-runner:run-audit` | command | When web frontend changed — Core Web Vitals |
| `/database-optimizer:analyze-query` | command | When specific query needs analysis |
| `/query-optimizer:optimize-query` | command | When query optimization needed |
| `postgres-optimization` | skill | When PostgreSQL queries or config changed |
| `supabase-postgres-best-practices` | skill | When Supabase/PostgreSQL patterns involved |
| `data-engineering` | skill | When data pipeline architecture changed |
| `performance-optimization` | skill | When general performance patterns needed |

## Cross-Mode (available to ALL modes)

| Tool | Type | When to use |
|------|------|------------|
| `tob-fp-check` | skill | When a finding recurs 3x — escalate-after-N |
| `tob-second-opinion` | skill | When ensemble disagrees — tie-breaking |
| `ensemble-review` | skill | Multi-reviewer consensus on any finding |
| `staff-reviewer` | agent | Escalation tier for unresolved findings |
| `verification-loop` | skill | Comprehensive verification of any claim |
| `/double-check:verify` | command | Spot-check any specific claim |

## Full Review

Dispatches ★ tools from ALL mode sections in parallel. Cap at 12 agents max. Conditional tools from each mode still apply based on diff content. Full = union of all mode defaults + applicable conditionals.

> **Note:** tob-* skills are from the Trail of Bits security skill pack.
