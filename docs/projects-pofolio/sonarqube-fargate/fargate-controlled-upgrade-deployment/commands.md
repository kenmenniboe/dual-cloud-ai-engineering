# Commands / Console Steps

## 1. Pre-upgrade snapshot
Console: RDS → Databases → sonarqube-db → Actions → Take snapshot
```
Snapshot name: sonarqube-db-pre-upgrade-2026-07-01
```

## 2. Deployment configuration (final working values)
ECS → sonarqube-cluster → sonarqube-service → Update service →
Deployment options:
```
Deployment strategy: Rolling update
Min running tasks %: 0
Max running tasks %: 101
Availability Zone rebalancing: OFF
```

Errors encountered along the way (for reference):
- `The max running tasks value must be greater than 100 when
  Availability Zone rebalancing is turned on.`
  → Fix: turn off AZ rebalancing.
- `The max running tasks value must be greater than the min running
  tasks value.`
  → Fix: min=100/max=100 not allowed; moved to min=100/max=101.
- Deployment stalled with 0 movement; Events tab showed:
  `service sonarqube-service was unable to stop or start tasks during a
  deployment because of the service deployment configuration.`
  → Fix: lowered min to 0% (kept max at 101%), allowing the service to
  briefly reach 0 running tasks during cutover.

## 3. Create new task definition revision (rehearsal "upgrade")
ECS → Task Definitions → sonarqube-task → revision 4 → Create new
revision → left all fields unchanged (same image
`sonarqube:26.6.0.123539-community`, same secrets, same health check)
→ Create.
Result: `sonarqube-task:5`

## 4. Deploy the new revision
ECS → sonarqube-service → Update service
```
Task definition revision: 5   (explicitly selected, not "Latest")
Min running tasks %: 0
Max running tasks %: 101
Force new deployment: checked
```

## 5. Verify via Events tab
ECS → sonarqube-service → Events tab — watched for, in order:
```
"has begun draining connections on 1 tasks"
"has started 1 tasks: task <task-id>"
"registered 1 targets in target-group sonarqube-tg"
"has reached a steady state"
"deployment completed"
```

## 6. Verify via Tasks tab
ECS → sonarqube-service → Tasks tab
- Confirmed task ID matches the one from the "has started" event.
- Confirmed Task definition = `sonarqube-task:5`.
- Confirmed Last status / Desired status = Running.
- Confirmed Health status = Healthy.

## 7. Verify app
```
https://menniboefarm.com
```
Loaded and worked correctly.