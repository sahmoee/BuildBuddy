# Optional: a native Shortcut (in addition to the web remote)

The web remote (`remote/index.html`) is the main tool and needs no setup beyond
typing your Mac's address once. This file is **only** if you also want a Shortcut
on your Home Screen / in the Share Sheet / on the Action Button for one-tap actions
like "Pull Stocked" or "Commit & Push."

A `.shortcut` file is a signed binary Apple won't let anyone hand-author, so it
can't ship in the zip. Building it takes about two minutes. Do it once.

────────────────────────────────────────────────────────────────────────────
## Build "BuildBuddy: Pull" (then duplicate for other actions)
────────────────────────────────────────────────────────────────────────────

1. Open **Shortcuts** → **+** (new shortcut) → name it `BuildBuddy: Pull`.

2. Add action **Text**. Put your token in it:
       (paste the token line the agent printed)

3. Add action **URL**. Set it to:
       http://YOUR_MAC_IP:7842/run
   (use the address the agent printed, e.g. http://192.168.1.42:7842/run)

4. Add action **Get Contents of URL**. Tap **Show More** and set:
   • Method: **POST**
   • Request Body: **JSON**
   • Add field (Text)  key: `action`     value: `pull`
   • Add field (Text)  key: `project`    value: `Stocked`   ← your project name
   • Add field (Text)  key: `token`       value: select the **Text** from step 2
   Leave "URL" as the Provided Input (it chains from step 3 automatically).

5. Add action **Get Dictionary Value** → key `result`.

6. Add action **Show Notification** → Body: select the **Dictionary Value**.

7. Done. Run it once to confirm you get a "✅ Pulled" notification.

────────────────────────────────────────────────────────────────────────────
## Make the others (10 seconds each)
────────────────────────────────────────────────────────────────────────────
Long-press the shortcut → **Duplicate**, rename, and change only the `action`
field's value:

   Pull latest ........ action = pull
   Commit & Push ...... action = commit_push   (add a Text field `message` too)
   Status ............. action = status
   Build (sim) ........ action = build_sim
   Open in Xcode ...... action = open_xcode
   Deploy Worker ...... action = deploy_worker
   Doctor ............. action = doctor

For **Commit & Push**, add one more JSON field:
   key: `message`   value: an **Ask Each Time** Text  → it'll prompt you to type
   the commit message when you run it.

For **switching/creating branches**, add field `name` (Ask Each Time) and set
   action = switch_branch  or  new_branch  (new_branch also takes `base`).

────────────────────────────────────────────────────────────────────────────
## Where to put them
────────────────────────────────────────────────────────────────────────────
• Home Screen: shortcut → Share → Add to Home Screen.
• Action Button (iPhone 15 Pro+): Settings → Action Button → Shortcut → pick one.
• Back Tap: Settings → Accessibility → Touch → Back Tap → Double Tap → the shortcut.
• "Hey Siri, pull Stocked": just name the shortcut what you want to say.

Every Shortcut hits the exact same agent endpoint the web remote does, so they
stay in sync automatically — nothing else to maintain.
