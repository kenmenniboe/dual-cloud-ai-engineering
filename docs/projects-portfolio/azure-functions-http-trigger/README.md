# 📘 Azure Functions — HTTP Trigger, Test & Deploy

> Three-part reference: Technician Guide · Beginner Walkthrough · Printable Checklist


---

## Part 1 — Technician Reference

### 1. Create the Function App

- Azure Portal → **Function App** → **Create**
- Set:
  - Runtime: `Node.js`
  - Hosting: `Flex Consumption` (or your choice)
  - Region: preferred region
- **Review + Create → Create**

---

### 2. Create an HTTP Trigger Function

- Function App → **Functions** → **Create**
- Template: `HTTP trigger`
- Name: e.g. `HelloWorld`
- Authorization Level: `Function`
- Click **Create**

---

### 3. Key Code Line to Understand

```javascript
const name = (req.query.name || (req.body && req.body.name));
```

- Reads `name` from the query string (`?name=Kenneth`) or request body
- Falls back to default message if no name is provided

---

### 4. Test Inside Azure

- Function → **Code + Test** → **Test/Run**
- Add query parameter:
  - Key: `name`
  - Value: `Kenneth`
- Click **Run** → view output in the results panel

---

### 5. Find Your Function App Domain

- Function App → **Overview** → **Default Domain**

```
https://kids-function-demo-h2esb6brafevggbr.centralus-01.azurewebsites.net
```

---

### 6. Get Your Function Key

- Function → **Function Keys** → copy the `default` key

> ℹ️ Azure requires a key to protect your function from unauthorized access.

---

### 7. Build Your Full Function URL

Structure:

```
https://<domain>/api/<function>?name=<your-name>&code=<your-key>
```

Example:

```
https://kids-function-demo-h2esb6brafevggbr.centralus-01.azurewebsites.net/api/HelloWorld?name=Kenneth&code=YOUR_KEY
```

---

### 8. Test in the Browser

- Paste your full URL into a browser → press Enter
- Expected output:

```
Hello, Kenneth. This HTTP triggered function executed successfully.
```

---

### 9. Test with curl

```bash
curl "https://<domain>/api/HelloWorld?name=Kenneth&code=<your-key>"
```

- Expected: same output as the browser

---

## Part 2 — Beginner-Friendly Guide

### What Is a Function App?

A Function App is a container that holds mini-APIs called **functions**. An HTTP-triggered function is like a tiny web API — you can call it from a browser, terminal, script, or mobile app. You only pay when it runs.

---

### 1. Create Your Function App

- Portal → **Function App** → **Create** → fill in runtime and region
- Think of the Function App as the folder that holds all your functions

---

### 2. Create Your First Function

- **Functions → Create → HTTP trigger** → name it → Auth: `Function`
- This creates a real API endpoint in the cloud

---

### 3. Understand the Key Code Line

```javascript
const name = (req.query.name || (req.body && req.body.name));
```

- `?name=Kenneth` in the URL → function uses `Kenneth`
- No name provided → uses the default message

> ℹ️ This is how the function reads input — from the URL query string or the request body.

---

### 4. Test Inside Azure First

- **Code + Test → Test/Run** → add query param `name=Kenneth` → **Run**
- See your output in the results panel

> ℹ️ Always test inside Azure before calling from the outside world — it's the safest starting point.

---

### 5. Find Your Domain & Function Key

- **Domain:** Function App → Overview → Default Domain
- **Key:** Function → Function Keys → copy `default`

---

### 6. Build & Call Your URL

```
https://<domain>/api/HelloWorld?name=Kenneth&code=YOUR_KEY
```

- Paste into browser → see your response ✅

---

### 7. Call From the Terminal

```bash
curl "https://<domain>/api/HelloWorld?name=Kenneth&code=<your-key>"
```

> ℹ️ This is how real systems, scripts, and apps call your API in production.

---

### What You Achieved

- ✅ Created a Function App and HTTP-triggered function
- ✅ Tested inside Azure, in a browser, and from the terminal
- ✅ Built and called a real secured cloud API endpoint
- ✅ This is the foundation of serverless development

---

## Part 3 — Printable Checklist

### ☐ 1. Function App
- [ ] Create Function App (Node.js, Flex Consumption)

### ☐ 2. Create Function
- [ ] Functions → Create → HTTP trigger
- [ ] Name: `HelloWorld` | Auth: `Function`

### ☐ 3. Test Inside Azure
- [ ] Code + Test → Test/Run → `name=Kenneth` → Run
- [ ] Confirm output message appears

### ☐ 4. Find Domain & Key
- [ ] Default Domain: Function App → Overview
- [ ] Function Key: Function → Function Keys → copy

### ☐ 5. Build Full URL
- [ ] `https://<domain>/api/HelloWorld?name=Kenneth&code=<key>`

### ☐ 6. Test in Browser
- [ ] Paste URL → `Hello, Kenneth...` message appears

### ☐ 7. Test with curl
- [ ] `curl "https://<domain>/api/HelloWorld?name=Kenneth&code=<key>"`
- [ ] Same output as browser ✅