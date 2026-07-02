# Day - Jul 02 - Controlled-Downtime Upgrade Deployment (Dress Rehearsal)

## Goal
Rehearse the full safe upgrade procedure for SonarQube on ECS Fargate —
pre-upgrade snapshot, single-version cutover deployment config, deploy,
verify — so the process is ready to run for real the moment a new
SonarQube Community Build version ships.

## Context
Checked available Community Build tags and confirmed `26.6.0.123539`
(currently running) is the latest published version — no newer version
exists yet to do a real upgrade against. Rather than building throwaway
infrastructure to simulate a fake old-to-new migration, ran the entire
real procedure against the actual environment using the same image
(acts as a stand-in "new version" for rehearsal purposes). The exact
same steps apply directly the next time a real version bump is
available — just swap the image tag.

## Why not run old + new versions side by side?
SonarQube auto-migrates its database schema on startup and cannot be
downgraded. If two versions ran against the same database at once, the
new task could begin migrating the schema while the old task is still
serving traffic against it — causing failed queries or inconsistent
writes. The deployment must guarantee only one version touches the
database at any moment.

## Steps taken
1. **Snapshot**: took a fresh RDS snapshot,
   `sonarqube-db-pre-upgrade-2026-07-01`, as the rollback safety net
   (in case a migration corrupts the schema mid-upgrade).
2. **Deployment config — first attempt**: set Min/Max running tasks % to
   100%/100% to force ECS to fully stop the old task before starting the
   new one (no overlap).
   - Hit AWS validation error: max must be > 100% if Availability Zone
     rebalancing is on → turned AZ rebalancing off.
   - Hit a second AWS validation error: max must be strictly greater
     than min → raised max to 101% (smallest valid gap).
3. **First deployment attempt stalled**: Events tab showed
   `"unable to stop or start tasks... because of the service deployment
   configuration"`. With only 1 desired task, min=100%/max=101% left ECS
   with no real room to stop the old task or start a new one — it was
   boxed in with zero valid moves.
4. **Fix**: lowered Min running tasks % to 0% (keeping max at 101%),
   allowing ECS to briefly go to 0 running tasks — old task drains
   fully, then new task starts. Accepts a few seconds of real downtime,
   which is expected and fine for a lab environment.
5. **Redeploy attempt found a process mistake, not a technical one**:
   confirmed via Events that a task started and became healthy, but its
   task definition showed revision 4, not the intended revision 5.
   Investigated and found revision 5 had never actually been created —
   the "create new revision" step was interrupted earlier by the
   min/max validation errors and never reached "Create."
6. Created revision 5 properly (identical config to revision 4 — image,
   secrets, health check all unchanged).
7. Redeployed, this time explicitly selecting revision 5 (not "Latest")
   in the task definition revision field.
8. Verified via Events: old task drained → new task started → new task
   registered with target group → service reached steady state.
9. Verified via Tasks tab: running task ID matched the "has started"
   event's task ID, task definition = revision 5, status Running,
   health Healthy.
10. Verified `menniboefarm.com` loads and works correctly.

## Result
Clean, single-version cutover deployment procedure fully rehearsed and
verified end-to-end, with two real deployment-configuration errors
diagnosed and fixed rather than just following steps blindly. Snapshot
was not needed — deployment succeeded — but existed correctly as
insurance for a "migration fails mid-upgrade" scenario, which is exactly
what it's for.

## Key takeaway
A pre-upgrade snapshot is insurance for the specific failure mode of
"the migration itself goes wrong or corrupts the schema" — it is not
something a successful deployment needs to use. Not touching the
snapshot after a clean deploy isn't wasted effort; it's the sign the
deployment worked as intended.

Separately: "the deployment succeeded" and "it deployed the revision I
intended" are two different things worth verifying independently —
always confirm task ID and task definition revision explicitly, don't
assume the console defaulted to what you meant.

## Follow-up
Repeat this exact procedure with a real new image tag the next time
SonarQube Community Build ships a new monthly version.
