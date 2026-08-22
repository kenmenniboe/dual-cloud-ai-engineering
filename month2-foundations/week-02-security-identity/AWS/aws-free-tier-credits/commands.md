# Commands — AWS Free Tier Credit Challenge

This session was almost entirely console-driven. The two pieces of copy-paste code/commands are below, grouped by module.

## Lambda — function code

Runtime: Python 3.13. Pasted into the inline code editor (**Code** tab), then **Deploy**.

```python
import json

def lambda_handler(event, context):
    return {
        'statusCode': 200,
        'headers': {'Content-Type': 'text/html'},
        'body': '<h1>Hello from Lambda!</h1><p>AWS Free Tier credit demo.</p>'
    }
```

## Aurora — connectivity test

Run from **CloudShell**, launched via the Aurora cluster's **Connectivity & security** tab (`psql` command pre-filled by the console):

```sql
SELECT version();
```