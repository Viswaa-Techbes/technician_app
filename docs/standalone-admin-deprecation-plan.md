Stand-alone Admin Deprecation Plan

Goal: Safely retire the old standalone admin app and consolidate features into the OG Admin Panel without disrupting production.

1. Inventory & Mapping
- Create a feature matrix mapping old admin routes -> OG Admin pages.
- Mark unique features in standalone admin that need migration or can be archived.

2. Migration Steps
- Phase 1 (Read-only parity): replicate read-only reports and dashboards in OG Admin.
- Phase 2 (Write parity): add management actions (create/update/delete) behind feature flags.
- Phase 3 (Switch-over): route users to OG Admin and disable new writes in standalone admin.

3. Safety & Rollback
- Keep standalone admin running in parallel in read-only mode for at least 7 days.
- Add telemetry + traffic routing to detect missing features or regressions.
- Provide a rollback plan to re-enable writes on standalone admin.

4. Cleanup
- After 30 days of stable operations, archive or remove standalone admin repository references.
- Decommission infra (DNS, CI/CD) after final confirmation.

5. Testing
- End-to-end tests covering admissions, payments, assignments, analytics.
- Performance baseline comparisons.

6. Timeline
- Estimate: 2-4 weeks depending on migration scope.

Notes:
- Do not delete code or routes until after the switch-over and monitoring window.
- Coordinate with stakeholders for data migrations (if any).