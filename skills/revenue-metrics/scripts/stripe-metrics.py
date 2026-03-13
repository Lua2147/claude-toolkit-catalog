"""Stripe Metrics — pulls key numbers across your Stripe accounts.

Configure ACCOUNTS below with your own Stripe account IDs.
Store your Stripe API key at ~/.config/stripe/api_key
"""

import json, os, subprocess, sys
from datetime import datetime, timedelta, timezone

# --- CONFIGURE THESE ---
stripe_key_path = os.path.expanduser("~/.config/stripe/api_key")
if not os.path.exists(stripe_key_path):
    print(json.dumps({"error": f"Stripe key not found at {stripe_key_path}. Create it with your Stripe secret key."}))
    sys.exit(1)

stripe_key = open(stripe_key_path).read().strip()

# Add your Stripe account IDs here
ACCOUNTS = {
    # "product_name": "acct_XXXXXXXXXXXX",
    # "saas_name": "acct_YYYYYYYYYYYY",
}

if not ACCOUNTS:
    print(json.dumps({"error": "No Stripe accounts configured. Edit ACCOUNTS in this script."}))
    sys.exit(1)

# --- Period handling ---
period = "today"
for i, a in enumerate(sys.argv):
    if a == "--period" and i + 1 < len(sys.argv):
        period = sys.argv[i + 1]

now = datetime.now(timezone.utc)
today_start = now.replace(hour=0, minute=0, second=0, microsecond=0)

if period == "today":
    start = today_start
    end = now
    cmp_start = today_start - timedelta(days=1)
    cmp_end = today_start
elif period == "yesterday":
    start = today_start - timedelta(days=1)
    end = today_start
    cmp_start = today_start - timedelta(days=2)
    cmp_end = today_start - timedelta(days=1)
elif period == "week":
    start = now - timedelta(days=7)
    end = now
    cmp_start = now - timedelta(days=14)
    cmp_end = now - timedelta(days=7)
elif period == "month":
    start = now - timedelta(days=30)
    end = now
    cmp_start = now - timedelta(days=60)
    cmp_end = now - timedelta(days=30)
elif period == "all":
    start = datetime(2020, 1, 1, tzinfo=timezone.utc)
    end = now
    cmp_start = cmp_end = None
else:
    start = today_start
    end = now
    cmp_start = today_start - timedelta(days=1)
    cmp_end = today_start


def fetch_charges(acct_id, since, until):
    charges = []
    url = "https://api.stripe.com/v1/charges?limit=100"
    url += f"&created[gte]={int(since.timestamp())}&created[lt]={int(until.timestamp())}"
    while url:
        result = subprocess.run(
            ["curl", "-s", "-g", url, "-u", f"{stripe_key}:",
             "-H", f"Stripe-Account: {acct_id}",
             "-H", "Stripe-Version: 2025-01-27.acacia"],
            capture_output=True, text=True
        )
        data = json.loads(result.stdout)
        for ch in data.get("data", []):
            if ch.get("paid") and not ch.get("refunded"):
                charges.append(ch)
        if data.get("has_more"):
            url = f"https://api.stripe.com/v1/charges?limit=100&starting_after={data['data'][-1]['id']}"
            url += f"&created[gte]={int(since.timestamp())}&created[lt]={int(until.timestamp())}"
        else:
            url = None
    return charges


def fetch_refunds(acct_id, since, until):
    total = 0
    url = "https://api.stripe.com/v1/refunds?limit=100"
    url += f"&created[gte]={int(since.timestamp())}&created[lt]={int(until.timestamp())}"
    while url:
        result = subprocess.run(
            ["curl", "-s", "-g", url, "-u", f"{stripe_key}:",
             "-H", f"Stripe-Account: {acct_id}",
             "-H", "Stripe-Version: 2025-01-27.acacia"],
            capture_output=True, text=True
        )
        data = json.loads(result.stdout)
        for r in data.get("data", []):
            total += r.get("amount", 0)
        if data.get("has_more"):
            url = f"https://api.stripe.com/v1/refunds?limit=100&starting_after={data['data'][-1]['id']}"
            url += f"&created[gte]={int(since.timestamp())}&created[lt]={int(until.timestamp())}"
        else:
            url = None
    return total


results = {"period": period, "accounts": {}, "total": {}}
total_gross = total_refunds = total_count = 0
total_cmp_gross = 0

for name, acct_id in ACCOUNTS.items():
    charges = fetch_charges(acct_id, start, end)
    gross = sum(c["amount"] for c in charges)
    refunds = fetch_refunds(acct_id, start, end)
    net = gross - refunds
    count = len(charges)

    entry = {
        "gross": gross / 100,
        "refunds": refunds / 100,
        "net": net / 100,
        "transactions": count,
    }

    if cmp_start and cmp_end:
        cmp_charges = fetch_charges(acct_id, cmp_start, cmp_end)
        cmp_gross = sum(c["amount"] for c in cmp_charges)
        entry["prior_gross"] = cmp_gross / 100
        entry["growth_pct"] = round((gross - cmp_gross) / cmp_gross * 100, 1) if cmp_gross else None
        total_cmp_gross += cmp_gross

    results["accounts"][name] = entry
    total_gross += gross
    total_refunds += refunds
    total_count += count

results["total"] = {
    "gross": total_gross / 100,
    "refunds": total_refunds / 100,
    "net": (total_gross - total_refunds) / 100,
    "transactions": total_count,
}
if cmp_start and cmp_end:
    results["total"]["prior_gross"] = total_cmp_gross / 100
    results["total"]["growth_pct"] = round((total_gross - total_cmp_gross) / total_cmp_gross * 100, 1) if total_cmp_gross else None

print(json.dumps(results, indent=2))
