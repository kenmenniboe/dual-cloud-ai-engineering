# Day - Jul 01 - Pinning SonarQube Image Version + Health Check Bug Fix

## Goal
Stop the SonarQube ECS task from silently drifting to a new version on
every restart, by pinning the container image to an exact version tag
instead of the floating `community` tag.

## Problem
The task definition used `sonarqube:community`, a moving Docker tag that
always resolves to the newest Community Build image. Since ECS/Fargate
can restart a task at any time for reasons outside your control (capacity
recycling, crashes, unrelated deployments), the running SonarQube version
could change without warning — and because SonarQube auto-migrates its
database schema on startup and cannot be downgraded, an unplanned version
change is a real risk to the database.

Checked the running version via Administration → System in the SonarQube
UI: `v26.6.0.123539`. Confirmed via Docker Hub that an exact matching tag
exists: `sonarqube:26.6.0.123539-community`.

## Solution
1. Created task definition revision 3: changed the image field from
   `sonarqube:community` to `sonarqube:26.6.0.123539-community`.
   Zero functional change — same version, just no longer a moving target.
2. Deployed revision 3. App logs showed a clean boot ("SonarQube is
   operational"), but ECS reported the task **Unhealthy**, and one task
   was later stopped for failing container health checks.
3. Investigated: the ALB target group health check
   (`/api/system/status`, port traffic-port, 200 expected) worked fine
   when tested directly (`curl`/browser returned `{"status":"UP"}`).
   This ruled out the ALB and the app itself.
4. Found the real cause in the task definition JSON: the container-level
   Docker health check command had a stray leading backtick:
   `` "`CMD-SHELL" `` instead of `"CMD-SHELL"`. This invalid command mode
   caused the container health check to fail every time, regardless of
   the app's actual state.
5. Created task definition revision 4 with the corrected command:
   `["CMD-SHELL", "curl -f http://localhost:9000/api/system/status"]`.
6. Deployed revision 4. Task came up **Running / Healthy**. Verified
   `menniboefarm.com` loads correctly.

## Result
- Image pinned to `sonarqube:26.6.0.123539-community` — no more silent
  version drift on task restart.
- Found and fixed a pre-existing, unrelated bug in the container health
  check definition (stray backtick) that had been masked until a
  fresh/rolling deployment actually exercised it.

## Key takeaway
Two different "health check" concepts exist and can disagree:
- **ALB target group health check** — external, HTTP-based, what the
  load balancer uses to route traffic.
- **ECS container health check** — internal, runs a shell command inside
  the container, reported in the ECS console's "Health status" column.

An app can be fully healthy by the ALB's check and still show
"Unhealthy" in ECS if the container health check command itself is
malformed. When they disagree, check both, and don't assume the app is
broken just because ECS says "unhealthy."

