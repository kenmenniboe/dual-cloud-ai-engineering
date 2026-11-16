# Commands / Console Steps

## 1. Check running SonarQube version
Console: SonarQube UI (menniboefarm.com) → log in as admin →
Administration → System → Version field.

Found: `26.6.0.123539`

## 2. Confirm matching Docker Hub tag exists
Docker Hub → sonarqube (Official Image) → Tags
Found exact match: `sonarqube:26.6.0.123539-community`

## 3. Pin the image (task definition revision 3)
ECS → Task Definitions → sonarqube-task → Create new revision
Container → Image URI:
```
sonarqube:26.6.0.123539-community
```
(changed from `sonarqube:community`; nothing else touched)

Deployed via: ECS → sonarqube-cluster → sonarqube-service → Update
service → task definition revision 3 → Force new deployment.

## 4. Diagnose the "Unhealthy" status
Checked app logs (ECS → service → Logs tab): app booted cleanly, no
errors, "SonarQube is operational".

Checked ALB target group health check config:
EC2 → Target Groups → (sonarqube target group) → Health checks tab
```
Protocol: HTTP
Path: /api/system/status
Port: traffic port
Healthy threshold: 2
Unhealthy threshold: 3
Timeout: 5s
Interval: 30s
Success codes: 200
```

Tested that endpoint directly:
```
curl https://menniboefarm.com/api/system/status
```
Result:
```json
{"id":"9F752459-AZ8N1Wl2E2Sv1_8izsdX","version":"26.6.0.123539","status":"UP"}
```
App and ALB check both healthy — ruled out.

## 5. Find the real bug
ECS → Task Definitions → sonarqube-task:3 → JSON tab → inspected
`healthCheck` block inside the container definition. Found:

```json
"healthCheck": {
    "command": [
        "`CMD-SHELL",
        "curl -f http://localhost:9000/api/system/status"
    ],
    "interval": 30,
    "timeout": 5,
    "retries": 3,
    "startPeriod": 120
}
```

Bug: stray leading backtick on `` `CMD-SHELL `` — invalid command mode,
causes the container health check to fail every run regardless of app
state.

## 6. Fix and redeploy (task definition revision 4)
Corrected JSON:
```json
"healthCheck": {
    "command": [
        "CMD-SHELL",
        "curl -f http://localhost:9000/api/system/status"
    ],
    "interval": 30,
    "timeout": 5,
    "retries": 3,
    "startPeriod": 120
}
```

Deployed via: ECS → sonarqube-service → Update service → task
definition revision 4 → Force new deployment.

## 7. Verify
- ECS → service → Tasks tab: `sonarqube-task:4`, Last status = Running,
  **Health status = Healthy**
- Browser: https://menniboefarm.com loads and works correctly