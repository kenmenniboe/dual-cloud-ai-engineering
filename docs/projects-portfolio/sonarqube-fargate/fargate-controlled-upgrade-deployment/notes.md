# Notes

## Why rolling deployments are unsafe for SonarQube specifically
- Default ECS rolling deployment (e.g. min 100% / max 200%) allows old
  and new tasks to run simultaneously for a brief window.
- SonarQube auto-migrates its database schema on startup and cannot be
  downgraded once migrated.
- If the new task starts migrating the schema while the old task is
  still serving live traffic against the same database, the old task's
  queries can fail or write data inconsistent with the new schema.
- Fix: force a single-version cutover by tightening min/max running
  task percentages so ECS can't run both versions at once.

## Min/Max running tasks % — constraints learned the hard way
- Min and max can't simply both be set to 100% — AWS requires max to be
  *strictly greater than* min.
- Max must be greater than 100% if Availability Zone rebalancing is
  turned on — so AZ rebalancing needs to be turned off if you want a
  tight max (like 100–101%) for a single-task service.
- Even a "technically valid" combination (e.g. min 100%, max 101%) can
  still leave ECS with **no actual room** to stop or start any task,
  if the numbers round down to zero extra capacity with only 1 desired
  task. ECS will report this directly in the service's Events tab:
  `"unable to stop or start tasks... because of the service deployment
  configuration"`.
- Working combination for a 1-task service needing a clean one-at-a-time
  cutover: **min 0%, max 101%**. This allows the service to briefly
  drop to zero running tasks (drain old, then start new) rather than
  trying to keep 1 running the whole time with no room to maneuver.
  Trade-off: a few seconds of real downtime during deployment, which is
  acceptable for this environment.

## Where to actually see what's happening during a deployment
- The **Deployments tab** shows progress bars/percentages, but can look
  static or stuck without explaining *why*.
- The **Events tab** on the ECS service is where the real diagnostic
  messages live — deployment errors, drain/start/register events, and
  "reached steady state" confirmations all show up there with
  timestamps. This was the key tool for diagnosing both the stalled
  deployment and confirming the successful one.

## Verify the deployment did what you think it did
- A deployment reporting "completed" or "steady state" doesn't
  guarantee it deployed the revision you intended — confirm explicitly:
  - Check the **task definition revision** shown in the Tasks tab.
  - Check the **task ID** matches the one mentioned in the Events tab's
    "has started 1 tasks" message.
- In this lab, an update was submitted while the task definition
  revision field was still on an old value (not the new revision just
  created) — the deployment "succeeded" but simply re-applied the
  already-running revision. No error was thrown; it just silently
  wasn't the change intended. Caught by comparing task definition
  revision numbers directly, not by trusting deployment status alone.

## What a pre-upgrade snapshot is actually for
- Insurance against the specific failure mode of a schema migration
  going wrong mid-upgrade (corrupted or partially-migrated schema).
- Restoring it means accepting loss of any writes made after the
  snapshot was taken — it's a rollback point, not a live sync.
- A successful deployment has no reason to touch the snapshot. Not
  using it isn't wasted effort — it's confirmation nothing went wrong.