Send emails as Ruben Schwagermann from Kadenwood inboxes — single or bulk.

Ruben has 140 inboxes (10 usernames × 14 domains). Daily capacity: 700 emails (5/inbox/day). All replies forward to ruben@kadenwoodgroup.com.

## How to use

The user will tell you who to email, what to say, and the scale. Use the appropriate script.

### Single send (one recipient):
```bash
python3 ~/Mundi\ Princeps/scripts/kw-send-email.py \
  --sender ruben \
  --from-domain kadenwoodcapitaladvisors.com \
  --to <recipient> \
  --subject "<subject>" \
  --body "<html body>"
```

### Bulk send (many recipients):

**Step 1** — Create a CSV at `/tmp/ruben_recipients.csv`:
```csv
email,first_name,company
ceo@acme.com,John,Acme Inc
cfo@beta.com,Sarah,Beta Corp
```

**Step 2** — Compose the subject and body with `{{template}}` variables:
- Available: `{{first_name}}`, `{{company}}`, `{{email}}`, and any CSV column name

**Step 3** — Dry run first to verify:
```bash
python3 ~/Mundi\ Princeps/scripts/kw-bulk-send.py \
  --sender ruben \
  --csv /tmp/ruben_recipients.csv \
  --subject "Introduction — Kadenwood Group" \
  --body "Hi {{first_name}},<br><br>Good to connect. We are a boutique advisory firm working with investors in the {{company}} space who are looking to back strong operators. Is a capital raise on the roadmap for 2026?<br><br>Best regards" \
  --dry-run
```

**Step 4** — Send for real:
```bash
python3 ~/Mundi\ Princeps/scripts/kw-bulk-send.py \
  --sender ruben \
  --csv /tmp/ruben_recipients.csv \
  --subject "Introduction — Kadenwood Group" \
  --body "Hi {{first_name}},<br><br>Good to connect..." \
  --shuffle
```

### Bulk send options:
- `--dry-run` — preview assignments without sending
- `--shuffle` — randomize inbox selection (recommended for deliverability)
- `--limit N` — cap sends at N emails for this run
- `--delay 1.5` — seconds between sends (default: 1.0)
- `--resume /tmp/state.json` — resume from a previous run, skipping already-sent
- `--capacity` — show inbox count and daily limits

### Check capacity:
```bash
python3 ~/Mundi\ Princeps/scripts/kw-bulk-send.py --sender ruben --capacity
```

### Signature
Auto-appended by the script (Kadenwood® text logo, gold divider, name/title/company). No URLs — kadenwoodgroup.com links trigger spam filters.
Use `--no-sig` to omit the signature (e.g. for replies).

### Tone
Professional, concise, investment banking style. Match the context of the deal.

### Workflow for the user
1. User provides: recipient list (or describes who to target), subject, and message intent
2. You compose the email copy with appropriate template variables
3. You create the CSV from the recipient data
4. You do a --dry-run and show the user the plan
5. On approval, you run the real send with --shuffle

$ARGUMENTS
