---
name: x-posting
description: Post tweets, read mentions, reply, like, retweet, and search on X/Twitter using the official v2 API.
---

# X/Twitter — Direct API

Post and engage on X/Twitter using the v2 API directly.

## API Credentials

From `~/Mundi Princeps/config/api_keys.json` under `deal_intent_signals_v1.x`:

```
Bearer Token: AAAAAAAAAAAAAAAAAAAAANV%2B7wEAAAAA7XROxzmNxNM4pHrpr%2Fvq3S3SiJ0%3D8NdUTuW7OFgA8tGxdYFP0pG7uVhPcDrG4a086MBoO2sSibSNko
API Key: QCTkjZP9iED3KRRZSHothm3Wz
API Secret: 46UQtxj4agbhEIX2CQv4kch1d0lAWX3HjhWp4p4XwwjFuGUsq6
```

## Read Operations (Bearer Token)

```bash
BEARER="AAAAAAAAAAAAAAAAAAAAANV%2B7wEAAAAA7XROxzmNxNM4pHrpr%2Fvq3S3SiJ0%3D8NdUTuW7OFgA8tGxdYFP0pG7uVhPcDrG4a086MBoO2sSibSNko"

# Search recent tweets
curl -s "https://api.twitter.com/2/tweets/search/recent?query=YOUR+QUERY&max_results=10" \
  -H "Authorization: Bearer $BEARER"

# Get user by username
curl -s "https://api.twitter.com/2/users/by/username/USERNAME" \
  -H "Authorization: Bearer $BEARER"

# Get user's tweets
curl -s "https://api.twitter.com/2/users/USER_ID/tweets?max_results=10" \
  -H "Authorization: Bearer $BEARER"
```

## Write Operations (OAuth 1.0a)

Posting requires OAuth 1.0a signature. Use the Typefully skill for scheduled posting, or implement OAuth signing:

```python
import requests
from requests_oauthlib import OAuth1

auth = OAuth1(
    'QCTkjZP9iED3KRRZSHothm3Wz',           # API Key
    '46UQtxj4agbhEIX2CQv4kch1d0lAWX3HjhWp4p4XwwjFuGUsq6',  # API Secret
    'ACCESS_TOKEN',                            # Need user access token
    'ACCESS_TOKEN_SECRET'                      # Need user access token secret
)

# Post tweet
resp = requests.post(
    'https://api.twitter.com/2/tweets',
    json={"text": "Your tweet here"},
    auth=auth
)
```

Note: User access tokens (OAuth 1.0a) require the OAuth flow. The bearer token only supports read operations.

## Alternative: Typefully Skill

For scheduling and posting, use the `typefully` skill which handles auth via its API:
- Schedule posts for optimal times
- Cross-post to LinkedIn, Threads, Bluesky
- Thread support

## Rate Limits
- Search recent: 300 requests/15min (bearer)
- User tweets: 900 requests/15min (bearer)
- Post tweet: 100/15min, 10,000/24hrs (OAuth)

## Use Cases for Kadenwood
- Monitor deal-related company mentions
- Track founder/CEO activity of target companies
- Research industry sentiment
- Brand presence for Kadenwood Group
