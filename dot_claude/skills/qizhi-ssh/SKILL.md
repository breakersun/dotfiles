---
name: qizhi-ssh
description: "SSH into servers behind Qizhi bastion host. Trigger: /qizhi <target_ip> [command]"
trigger: /qizhi
---

# /qizhi — SSH via Qizhi Bastion Host

SSH into any server behind 齐治堡垒机 using RSA key. No password or TOTP needed.

## Usage

Use the `qizhi` wrapper script (installed at `~/.local/bin/qizhi`):

```bash
qizhi <target_ip>              # SSH into target with interactive shell
qizhi <target_ip> <command>    # Run one-shot command on target
```

## Examples

```bash
qizhi 10.84.4.67                           # interactive shell
qizhi 10.84.4.67 uptime                    # check uptime
qizhi 10.84.4.67 "docker ps --format 'table {{.Names}}\t{{.Status}}'"
```

## File Transfer

`scp` does not work through Qizhi bastion — the `user@bastion:path` format breaks scp's path parsing. Use `qizhi` with pipe redirection instead.

**Upload (local → server):**
```bash
cat /local/file | qizhi <ip> "cat > /remote/path"
```

**Download (server → local):**
```bash
qizhi <ip> "cat /remote/path" > /local/file
```

Works for text and binary. No progress bar or resume — not suitable for large files (>100MB).

**Examples:**
```bash
# Upload script
cat ./deploy.sh | qizhi 10.84.4.67 "cat > /home/ubuntu/deploy.sh && chmod +x /home/ubuntu/deploy.sh"

# Download config
qizhi 10.84.4.67 "cat /etc/nginx/nginx.conf" > ./nginx.conf

# Upload binary
cat ./app.bin | qizhi 10.84.4.67 "cat > /opt/app/bin/app.bin"
```

## How It Works

1. Wrapper builds the bastion SSH target: `403283/<target_ip>/ubuntu@10.0.1.115`
2. Bastion parses slash-delimited username → proxies to target
3. RSA key auth (`~/.ssh/id_rsa_qizhi`) — no password or TOTP needed

## Connection Formula (for manual use)

```
ssh -i ~/.ssh/id_rsa_qizhi "403283/<target_ip>/ubuntu@10.0.1.115"
```

## Gotchas

- **Failed login lockout**: 3-5 failed attempts triggers PAM faillock. Wait 10-15 min.
- **ssh-rsa only**: 齐治 does NOT support ssh-ed25519 for user public keys
- **Key path**: `~/.ssh/id_rsa_qizhi` (RSA 4096-bit, no passphrase)
