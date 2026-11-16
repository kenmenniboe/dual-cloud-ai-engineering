📘 DOCUMENT 1 — PERSONAL REFERENCE NOTE (FINAL VERSION)

Concise, technician‑style, with real steps, real commands, and real actions you performed

Sections + numbered steps

1. Create the Windows Server VM

Deploy a Windows Server VM (2019/2022).
Assign a static public IP.
Allow inbound ports:
80 (HTTP)
443 (HTTPS)
3389 (RDP)

2. Install IIS (PowerShell Method You Used)

✔ Install IIS
Open PowerShell as Administrator:
Code
Install-WindowsFeature -name Web-Server -IncludeManagementTools

✔ Verify IIS installed
Code
Get-WindowsFeature Web-Server

Should show:
Code
[X] Web Server (IIS)

✔ Navigate to IIS web root
Code
cd C:\inetpub\wwwroot

✔ Create a test webpage
Code
echo "<h1>Hello from my Windows VM!</h1>" > index.html

3. Configure DNS for the Domain

Log into your domain registrar.
Create an A record:
Host: @
Points to: your VM’s public IP
(Optional) Create CNAME:
Host: www
Points to: menniboefarm.com

4. Add IIS Host Binding (Critical Step)
Open IIS Manager.
Select Default Web Site.
Click Bindings… → Add…
Enter exactly:
Type: http
IP address: All Unassigned
Port: 80
Host name:
Code
menniboefarm.com


Click OK.

5. Install win‑acme (Let’s Encrypt Client)
✔ Create the win‑acme directory
Code
New-Item -ItemType Directory -Path C:\win-acme

✔ Download win‑acme (your exact working command)
Code
Invoke-WebRequest -Uri https://github.com/win-acme/win-acme/releases/download/v2.2.9.1701/win-acme.v2.2.9.1701.x64.pluggable.zip -OutFile C:\win-acme\win-acme.zip

✔ Extract the ZIP
Code
Expand-Archive C:\win-acme\win-acme.zip C:\win-acme -Force

✔ Navigate into the folder
Code
cd C:\win-acme

6. Request the SSL Certificate (Your Exact Steps)

✔ Run win‑acme
Code
.\wacs.exe

✔ Choose:
Code
N   (Create new certificate)

✔ Select the IIS site showing:
Code
Default Web Site (http, menniboefarm.com)

✔ Accept defaults for:
HTTP validation
Installation
HTTPS binding
Auto‑renewal task
Wait for the success message.

7. Verify HTTPS Binding

In IIS → your site → Bindings…
Confirm:
Type: https
Port: 443
Host name: menniboefarm.com
SSL certificate: Let’s Encrypt
Browse to:
Code
https://menniboefarm.com


8. Verify Certificate Installation

In IIS Manager → click server name.
Open Server Certificates.
Confirm certificate named:
Code
menniboefarm.com


Expiration ~90 days from today.

9. Auto‑Renewal

win‑acme created a scheduled task automatically.
Certificate renews every ~60 days.
No manual action required.

✅ Document 1 is now complete and accurate

This version includes:

The actual IIS PowerShell install command

The actual win‑acme download command

The actual extraction command

The actual steps you performed

The correct IIS binding values

The correct win‑acme workflow

If this is correct, say “Approved”, and I’ll move on to:

📘 Document 2 — Beginner‑Friendly Guide  

📘 Document 3 — Printable Checklist
approved
Great — Document 1 is officially locked in.
Now we move on to Document 2, the Beginner‑Friendly Guide.
This one is meant to teach, not just list steps — but still stay clean, clear, and practical.
Here it is.

📘 DOCUMENT 2 — BEGINNER‑FRIENDLY GUIDE

Explains what you’re doing and why, in simple language
Covers: VM → IIS → DNS → Bindings → win‑acme → SSL

1. Create Your Windows Server VM
This is the machine that will host your website.
What to do:
Deploy a Windows Server VM (2019 or 2022).
Assign a static public IP so your domain always points to the same address.
Open the VM’s firewall / NSG and allow:
80 → required for HTTP
443 → required for HTTPS
3389 → required for RDP access

Why this matters:
Let’s Encrypt must reach your server over port 80 to validate your domain.
If port 80 is blocked, SSL will fail.

2. Install IIS (Your Web Server)

IIS is the software that serves your website.
What to do:
Open PowerShell as Administrator and run:
Code
Install-WindowsFeature -name Web-Server -IncludeManagementTools

Verify IIS installed:
Code
Get-WindowsFeature Web-Server

You should see [X] Web Server (IIS).
Create a test webpage:
Code
cd C:\inetpub\wwwroot
echo "<h1>Hello from my Windows VM!</h1>" > index.html

Why this matters:
This confirms IIS is working and serving content.

3. Configure DNS for Your Domain
This connects your domain name to your VM.
What to do:
Log into your domain registrar.
Create an A record:
Host: @
Points to: your VM’s public IP
(Optional) Create a CNAME:
Host: www
Points to: menniboefarm.com
Why this matters:
Let’s Encrypt checks that your domain resolves to your server.
If DNS is wrong, validation fails.

4. Add the IIS Host Binding

This tells IIS which domain belongs to which website.
What to do:
Open IIS Manager.
Select Default Web Site.
Click Bindings… → Add…
Enter:
Type: http
Port: 80
Host name: menniboefarm.com
Click OK.
Why this matters:
Without this binding, win‑acme cannot match your domain to your IIS site.

5. Install win‑acme (Let’s Encrypt Client)

This tool automatically gets and installs your SSL certificate.
What to do:
Create the folder:
Code
New-Item -ItemType Directory -Path C:\win-acme

Download win‑acme:
Code
Invoke-WebRequest -Uri https://github.com/win-acme/win-acme/releases/download/v2.2.9.1701/win-acme.v2.2.9.1701.x64.pluggable.zip -OutFile C:\win-acme\win-acme.zip

Extract it:
Code
Expand-Archive C:\win-acme\win-acme.zip C:\win-acme -Force

Go into the folder:
Code
cd C:\win-acme

Why this matters:
win‑acme handles the entire SSL process automatically.

6. Request Your SSL Certificate

This is where Let’s Encrypt verifies your domain and installs HTTPS.
What to do:
Run:
Code
.\wacs.exe

Choose:
Code
N   (Create new certificate)

Then select the IIS site that shows:
Code
Default Web Site (http, menniboefarm.com)

Accept all defaults.
Why this matters:
win‑acme will:
Validate your domain
Generate the certificate
Install it
Bind HTTPS
Create the auto‑renew task
All automatically.

7. Verify HTTPS Binding

In IIS → your site → Bindings…
You should now see:
Type: https
Port: 443
Host name: menniboefarm.com
Certificate: Let’s Encrypt
Why this matters:
This confirms HTTPS is active and correctly bound.

8. Verify the Certificate

In IIS Manager → click server name → Server Certificates
You should see:
Code
menniboefarm.com

Expiration should be ~90 days from today.

9. Auto‑Renewal

win‑acme automatically created a scheduled task.
It will:
Renew the certificate every ~60 days
Update IIS
Replace the old certificate
No manual work needed.
🎉 Document 2 Complete
This guide explains the why behind each step so beginners can follow confidently.
If this looks good, say “Approved”, and I’ll create:

📘 Document 3 — Printable Checklist
approved

Awesome — Document 2 is locked in.
Now let’s finish strong with Document 3, your Printable Checklist.
This one is designed to be fast, clean, and perfect for taping to a monitor or saving as a quick‑reference sheet.
Here it is.

📘 DOCUMENT 3 — PRINTABLE CHECKLIST
Short, clean, fast — every step you need, nothing extra
Covers: VM → IIS → DNS → Bindings → win‑acme → SSL

✅ 1. VM Setup
[ ] Deploy Windows Server 2019/2022
[ ] Assign static public IP
[ ] Allow inbound ports:
[ ] 80 (HTTP)
[ ] 443 (HTTPS)
[ ] 3389 (RDP)

✅ 2. Install IIS (PowerShell)
[ ] Run:
Code
Install-WindowsFeature -name Web-Server -IncludeManagementTools


[ ] Verify:
Code
Get-WindowsFeature Web-Server


[ ] Create test page:
Code
cd C:\inetpub\wwwroot
echo "<h1>Hello from my Windows VM!</h1>" > index.html


✅ 3. Configure DNS
[ ] Create A record
Host: @
Points to: VM public IP
[ ] (Optional) Create CNAME
Host: www
Points to: menniboefarm.com

✅ 4. Add IIS Host Binding
[ ] Open IIS Manager
[ ] Select Default Web Site
[ ] Bindings → Add
Type: http
Port: 80
Host name: menniboefarm.com
[ ] Save

✅ 5. Install win‑acme
[ ] Create folder:
Code
New-Item -ItemType Directory -Path C:\win-acme


[ ] Download:
Code
Invoke-WebRequest -Uri https://github.com/win-acme/win-acme/releases/download/v2.2.9.1701/win-acme.v2.2.9.1701.x64.pluggable.zip -OutFile C:\win-acme\win-acme.zip


[ ] Extract:
Code
Expand-Archive C:\win-acme\win-acme.zip C:\win-acme -Force


[ ] Navigate:
Code
cd C:\win-acme


✅ 6. Request SSL Certificate
[ ] Run:
Code
.\wacs.exe


[ ] Choose: N (new certificate)
[ ] Select site: Default Web Site (http, menniboefarm.com)
[ ] Accept all defaults
HTTP validation
Install cert
Bind HTTPS
Create auto‑renew task

✅ 7. Verify HTTPS Binding
[ ] IIS → Site → Bindings
[ ] Confirm:
Type: https
Port: 443
Host: menniboefarm.com
Cert: Let’s Encrypt

✅ 8. Verify Certificate
[ ] IIS → Server Certificates
[ ] Confirm cert: menniboefarm.com
[ ] Expiration ~90 days

✅ 9. Auto‑Renewal
[ ] Confirm scheduled task created by win‑acme
[ ] Renewal every ~60 days
[ ] No manual action needed





🌱 BEGINNER‑FRIENDLY GUIDE

⭐ Hosting a Website on Azure App Service
From Creating the App Service → Launching It → Adding Your Domain → Enabling HTTPS
(Explained in simple, friendly language)

🌟 Section 1 — What You’re Trying to Do (In Plain English)
You want to put a website on the internet using Azure.
Azure gives you a “home” for your website called an App Service.
Your domain name (menniboefarm.com) is like the street address people type to reach your home.

This guide shows you how to:
Create the App Service (the home)
Launch it so it shows a webpage
Connect your domain name to it
Turn on HTTPS so it’s secure
That’s the whole journey.

🌟 Section 2 — What You Need Before You Start
You only need two things:
✔ An Azure account
✔ A domain name (yours is menniboefarm.com)
That’s it.

🌟 Section 3 — Create Your App Service (The Home for Your Website)
This is where your website will live.

🟦 Step 1 — Go to Azure Portal
Open: https://portal.azure.com

🟦 Step 2 — Create a New App Service
Click Create a resource
Search for App Service
Click Create

🟦 Step 3 — Fill Out the Basics
Azure will ask for a few simple things:
Subscription: Your subscription
Resource Group: Create a new one or use an existing one
Name: This becomes your temporary website URL
Example:
Code
menniboe-demo.azurewebsites.net


Runtime stack: Choose what you want (HTML, .NET, Node, etc.)
Region: Choose a region close to you

🟦 Step 4 — Choose a Pricing Plan
For simple sites, the Basic or Free tier works.
(Free tier does NOT support custom domains — Basic or higher does.)

🟦 Step 5 — Click Review + Create
Then click Create.
Azure will build your App Service in about 30–60 seconds.

🌟 Section 4 — Launch Your App Service (Make Sure It Works)
Once Azure finishes creating it:
Click Go to resource
On the Overview page, click the URL that ends in:
Code
azurewebsites.net


You should see a default Azure “Welcome” page.
This means your App Service is alive and working.

🌟 Section 5 — Add Your Website Files (Optional)
If you want to upload your own HTML:
In your App Service, go to Advanced Tools
Click Go →
Click Debug Console → CMD
Navigate to:
Code
site/wwwroot


Drag and drop your HTML files
Your website is now live on the default Azure URL.

🌟 Section 6 — Connect Your Custom Domain (menniboefarm.com)
Now you want people to reach your site using:
Code
www.menniboefarm.com

🟦 Step 1 — Go to Custom Domains
In your App Service, click:
Custom domains

🟦 Step 2 — Add Your Domain
Click Add custom domain  
Enter:
Code
www.menniboefarm.com

Azure will now ask you to add DNS records in Namecheap.

🟦 Step 3 — Add DNS Records in Namecheap
Go to Namecheap → Domain List → Manage → Advanced DNS
Add:
✔ CNAME Record
Host: www
Value: your-app-name.azurewebsites.net
✔ TXT Record
Host: asuid.www
Value: the verification code Azure gave you
Save the records.

🟦 Step 4 — Go Back to Azure and Click Add
Azure will say:
Validation passed
Click Add.
Your domain is now connected.

🌟 Section 7 — Turn On HTTPS (Secure Your Site)
Now you want the padlock icon to show in the browser.

🟦 Step 1 — Create the Free Certificate
Go to:
TLS/SSL settings → App Service Managed Certificates
Click:
Create
Choose:
Code
www.menniboefarm.com

Azure will generate a free certificate.

🟦 Step 2 — Bind the Certificate
Go to:
TLS/SSL Bindings
Click:
Add TLS/SSL Binding
Choose:
Hostname: www.menniboefarm.com
Certificate: the one Azure created
Type: SNI SSL
Click Add.
Azure restarts your site.

🌟 Section 8 — Test Your Website
Open:
Code
https://www.menniboefarm.com

You should now see:
A padlock
Your website
No warnings
If your browser still shows “Not Secure,” it’s just cached.
Clearing the cache fixes it.

🌟 Section 9 — You’re Done!
You now have:
A running Azure App Service
Your website deployed
Your custom domain connected
A free HTTPS certificate
A secure, professional website
This is the full beginner‑friendly journey from zero → live website.







🛠️ TECHNICIAN REFERENCE GUIDE
Azure App Service → Deploy Site → Add Custom Domain → Enable HTTPS

🔵 1. Create the App Service
Azure Portal → Create a Resource → App Service → Create
Basics tab
Subscription: your subscription
Resource Group: create or select
Name: menniboe-demo (or any name)
Publish: Code
Runtime stack: HTML / .NET / Node — your choice
Region: closest region
App Service Plan
Choose Basic (B1) or higher
(Free tier does NOT support custom domains)
Review + Create → Create
Deployment takes ~30–60 seconds.

🔵 2. Verify the App Service Works
App Service → Overview → URL
Example:
Code
https://menniboe-demo.azurewebsites.net

Load it in a browser.
You should see the Azure default page.

🔵 3. Deploy Your Website Files (Optional)
App Service → Advanced Tools → Go → Debug Console → CMD
Navigate to:
Code
site/wwwroot

Upload your files:
Drag & drop HTML/CSS/JS
Overwrite existing files
Refresh the Azure URL to confirm deployment.

🔵 4. Add the Custom Domain (www.menniboefarm.com)
App Service → Custom domains → Add custom domain
Enter:
Code
www.menniboefarm.com

Azure displays required DNS records.

🔵 5. Add DNS Records in Namecheap
Namecheap → Domain List → Manage → Advanced DNS
Add the following:
CNAME Record
Type: CNAME
Host: www
Value: menniboe-demo.azurewebsites.net
TTL: Automatic
TXT Record
Type: TXT
Host: asuid.www
Value: (Azure verification code)
TTL: Automatic
Save both records.
Propagation usually takes 1–5 minutes.

🔵 6. Validate and Add the Domain in Azure
Return to:
App Service → Custom domains → Add
Azure should show:
Code
Validation passed

Click Add.
Domain is now attached to the App Service.

🔵 7. Create the Free HTTPS Certificate
App Service → TLS/SSL settings → App Service Managed Certificates
Click:
Create
Select:
Code
www.menniboefarm.com

Azure generates the certificate (10–20 seconds).

🔵 8. Bind the Certificate to the Domain
App Service → TLS/SSL settings → TLS/SSL Bindings → Add TLS/SSL Binding
Set:
Hostname: www.menniboefarm.com
Certificate: (the managed certificate you created)
TLS/SSL Type: SNI SSL
Click Add.
Azure restarts the site and applies HTTPS.

🔵 9. Test HTTPS
Open:
Code
https://www.menniboefarm.com

Expected:
Padlock icon
No warnings
Site loads normally
If “Not Secure” appears:
Clear browser cache
Test in private/incognito
Test on mobile data

🔵 10. (Optional) Force HTTPS Redirect
App Service → Configuration → General settings
Set:
Code
HTTPS Only: On

This forces all traffic to HTTPS.

✅ Technician Workflow Complete
You now have:
App Service created
Website deployed
Custom domain connected
Free HTTPS certificate installed
Secure binding applied
HTTPS enforced





Beginner-Friendly Walkthrough: Everything We Did
A simple, friendly, step-by-step guide that explains what you did, why you did it, and how to do each step.

⭐ 1. Create Your Function App
What You Did
You created a new Azure Function App in the Azure Portal.
Why This Matters
A Function App is the container that holds all your functions. Think of it like a folder that contains multiple mini‑APIs.
How To Do It
Go to the Azure Portal.
Search for Function App.
Click Create.
Choose:
Runtime: Node.js
Hosting: Flex Consumption (or your choice)
Region: Your preferred region
Click Review + Create.
Click Create.

⭐ 2. Create Your First Function (HTTP Trigger)
What You Did
You added a new function using the HTTP trigger template.
Why This Matters
An HTTP-triggered function acts like a tiny web API. You can call it from:
A browser
A terminal
A script
A mobile app
Anything that can send an HTTP request
How To Do It
Open your Function App.
Click Functions.
Click Create.
Choose HTTP trigger.
Name it (example: HelloWorld).
Set Authorization Level to Function.
Click Create.

⭐ 3. Understand the Function Code
What You Did
You looked at the default code that Azure created.
Why This Matters
This code decides what message your function returns.
How It Works
The key line is:
const name = (req.query.name || (req.body && req.body.name));
This means:
If you pass ?name=Kenneth → it uses that
If you don’t pass a name → it uses the default message

⭐ 4. Test the Function Inside Azure
What You Did
You used the Test/Run feature.
Why This Matters
This is the safest place to test your function before calling it from the outside world.
How To Do It
Open your function.
Click Code + Test.
Click Test/Run.
Add a query parameter:
Key: name
Value: Kenneth
Click Run.
See the output.

⭐ 5. Find Your Function App’s Default Domain
What You Did
You found your Function App’s default domain:
https://kids-function-demo-h2esb6brafevggbr.centralus-01.azurewebsites.net
Why This Matters
This is the base URL for all your functions.
How To Find It
Open your Function App.
Look at the Overview page.
Find Default Domain.

⭐ 6. Get Your Function Key
What You Did
You opened Function Keys and copied the default key.
Why This Matters
Azure requires a key to protect your function from unauthorized access.
How To Do It
Open your function.
Click Function Keys.
Copy the default key.

⭐ 7. Build Your Full Function URL
What You Did
You combined the domain, function name, query parameter, and key.
Why This Matters
This creates a real API endpoint you can call from anywhere.
How To Build It
Use this structure:
https://<domain>/api/<function>?name=<your-name>&code=<your-key>
Example:
https://kids-function-demo-h2esb6brafevggbr.centralus-01.azurewebsites.net/api/HelloWorld?name=Kenneth&code=YOUR_KEY

⭐ 8. Test Your Function in the Browser
What You Did
You pasted the full URL into your browser.
Why This Matters
This proves your function works outside Azure.
How To Do It
Paste your full URL into the browser.
Press Enter.
See your message.
Expected output:
Hello, Kenneth. This HTTP triggered function executed successfully.

⭐ 9. Test Your Function Using curl
What You Did
You ran a curl command in your terminal.
Why This Matters
This is how real systems and scripts call your API.
How To Do It
Open your terminal.
Run:
curl "https://<domain>/api/HelloWorld?name=Kenneth&code=<your-key>"
Press Enter.
See the same output as the browser.

⭐ 10. What You Achieved
You now know how to:
Create a Function App
Create an HTTP-triggered function
Understand query parameters
Test inside Azure
Test from a browser
Test from a terminal
Use function keys
Build and call a real API endpoint
This is the foundation of serverless development.
You successfully built, deployed, secured, and executed a real cloud API.

End of walkthrough.

https://www.transip.eu/knowledgebase/installing-and-configuring-an-nginx-webserver-in-centos-stream-almalinux-or-rocky-linux

