# Notes

## Floating tags vs pinned tags
- `sonarqube:community` = a moving tag; Docker Hub keeps repointing it at
  whatever the latest Community Build release is.
- `sonarqube:26.6.0.123539-community` = an immutable, version-specific
  tag; always resolves to exactly this build.
- ECS/Fargate can pull a fresh copy of an image tag any time the task
  restarts — including for reasons you don't control (capacity recycling,
  health-check-triggered restarts, unrelated service deployments).
- Combined with SonarQube's one-way database schema migration on
  startup, a floating tag means an upgrade (and a schema migration)
  could happen to you without warning, at a moment you didn't choose.

## SonarQube versioning scheme (Community Build)
- Since version 24.12.0.100206, Community Build versions follow calendar
  versioning: `YY.M.0.BuildNumber`.
- No "Long-Term Active" (LTA) concept for Community Build — a new
  version ships roughly monthly, and older versions stop getting
  bug/security fixes once a newer one exists.
- This differs from the old Enterprise LTS-to-LTS upgrade path rules —
  there's no strict "must upgrade one major version at a time"
  requirement for Community Build the way there used to be.

## Two kinds of "health check" (the actual bug this lab surfaced)
1. **ALB target group health check**
   - Lives in EC2 → Target Groups → (target group) → Health checks.
   - External: the load balancer makes an HTTP request to a path/port on
     a schedule and expects a success status code back.
   - This is what decides whether the ALB routes real user traffic to a
     task.
2. **ECS container health check**
   - Lives in the task definition's `healthCheck` block.
   - Internal: ECS runs a literal shell command *inside* the container
     (commonly `CMD-SHELL` + a curl command) on an interval, and expects
     exit code 0.
   - This is what populates the "Health status" column in the ECS
     console's Tasks list.
   - These two checks are independent. One can report healthy while the
     other reports unhealthy, especially if there's a malformed command
     in the container health check block — the app can be perfectly
     fine and still get flagged "Unhealthy" by ECS.

## Debugging approach used
1. Checked application logs first — confirmed the app itself booted
   cleanly with no errors ("SonarQube is operational").
2. Tested the ALB's health check endpoint directly
   (`/api/system/status`) via browser/curl — got a healthy `200` JSON
   response, ruling out the app and the ALB.
3. Since both the app and the externally-facing health check were fine,
   the remaining place a health signal could be wrong was the
   container-level health check definition — checked the task
   definition JSON directly and found the malformed `CMD-SHELL` command.

General lesson: when a platform-reported health status disagrees with
what the app itself and external checks say, look at the *health check
definition itself* as a suspect, not just the app.