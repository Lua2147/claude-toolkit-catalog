Deploy an app to the specified server.

Servers:
- mundi-ralph (149.28.37.34): Agent runtime, Ralph Wiggum, 6 vCPU 24GB RAM
- developer-db (108.61.158.220): Monitoring (Grafana, Coolify, Uptime Kuma, n8n)

Steps:
1. Ask which app and which server (if not specified)
2. Ensure all changes are committed and pushed
3. SSH to the target server
4. Pull latest changes
5. Restart the relevant service (check app's CLAUDE.md or deploy.sh for specifics)
6. Verify the service is running
7. Report status
