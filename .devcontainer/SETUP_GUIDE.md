# DevContainer Setup Guide for macOS
**Complete Configuration for GitHub & Docker Desktop Access**

Last Updated: February 17, 2026

---

## 🎯 What This Enables

After completing this setup, you'll be able to:

✅ **GitHub Integration**:
- Use Git commands with your SSH keys
- Run `gh` CLI commands (PRs, Actions, Issues)
- View GitHub Actions results in Cursor IDE
- Manage pull requests from inside the container

✅ **Docker Desktop Access**:
- Run `docker` and `docker-compose` commands
- Start/stop containers for integration testing
- Run end-to-end tests using Docker
- Deploy and test full stack environments
- Access all Docker Desktop containers from inside devcontainer

---

## 📋 Prerequisites Checklist

Before starting, ensure you have:

- [ ] macOS with Docker Desktop installed
- [ ] Cursor IDE installed
- [ ] GitHub account with SSH keys configured
- [ ] GitHub CLI (`gh`) installed on your Mac: `brew install gh`

---

## 🔧 Part 1: macOS Host Setup (One-Time)

### Step 1: Configure Docker Desktop

1. Open **Docker Desktop** on your Mac
2. Go to **Settings** → **General**
   - ✅ Enable: "Use Docker Compose V2"
3. Go to **Settings** → **Advanced** (or **Resources** → **Advanced**)
   - ✅ Enable: "Allow the default Docker socket to be used (requires password)"
   - This allows containers to access `/var/run/docker.sock`
4. Click **Apply & Restart**

**Why?** This enables the Docker-outside-of-Docker pattern where your devcontainer can control Docker Desktop.

### Step 2: Authenticate GitHub CLI

```bash
# Install GitHub CLI (if not already installed)
brew install gh

# Authenticate with GitHub
gh auth login

# Select:
# - GitHub.com
# - SSH protocol
# - Upload your SSH public key (or use existing)
# - Authenticate via browser
```

**Verify:**
```bash
gh auth status
# Should show: ✓ Logged in to github.com as YOUR_USERNAME
```

### Step 3: Configure SSH Agent

```bash
# Add your SSH key to the macOS keychain
ssh-add --apple-use-keychain ~/.ssh/id_ed25519
# Or if you use RSA: ssh-add --apple-use-keychain ~/.ssh/id_rsa

# Verify key is loaded
ssh-add -l
# Should show your key fingerprint
```

**Make it permanent** - Add to `~/.ssh/config`:
```bash
cat >> ~/.ssh/config << 'EOF'
Host *
  UseKeychain yes
  AddKeysToAgent yes
  IdentityFile ~/.ssh/id_ed25519
EOF
```

### Step 4: Verify Git Configuration

```bash
# Check your git config
git config --global user.name
git config --global user.email

# If not set, configure:
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
```

---

## 🐳 Part 2: Rebuild DevContainer

### Step 1: Open Project in Cursor

```bash
# Navigate to your project
cd /Users/vn/Development/01_VN_Dev_Space/prevance_workspace/frappe_docker

# Open in Cursor
cursor .
```

### Step 2: Rebuild Container

1. Open Command Palette: `Cmd+Shift+P`
2. Type: **"Dev Containers: Rebuild Container"**
3. Press Enter and wait (first build takes 3-5 minutes)

**What happens:**
- Dev Container Features are installed (Git, GitHub CLI, Docker tools)
- Your SSH keys, Git config, and GitHub tokens are mounted
- Docker socket is connected to Docker Desktop
- VS Code extensions are installed automatically

### Step 3: Wait for Post-Create Command

The container runs a post-create command that:
- Sets correct permissions on SSH keys (700 for directory, 600 for files)
- Configures `gh` CLI for Git operations

You'll see output in the terminal like:
```
[postCreateCommand] Running...
[postCreateCommand] Done.
```

---

## ✅ Part 3: Verification Steps

After the container rebuilds, run these tests **inside the container terminal**:

### Test 1: Git Access

```bash
# Check Git is configured
git config --get user.name
git config --get user.email

# Test SSH connection to GitHub
ssh -T git@github.com
# Expected output: "Hi YOUR_USERNAME! You've successfully authenticated..."

# Try a git operation
cd /workspace/development/frappe-bench/apps/prevance_health
git status
git log --oneline -5
```

**Expected:** Git commands work without asking for credentials.

### Test 2: GitHub CLI

```bash
# Check gh authentication
gh auth status
# Should show: ✓ Logged in to github.com

# List your repositories
gh repo list

# View GitHub Actions runs (if in a repo with Actions)
cd /workspace/development/frappe-bench/apps/prevance_health
gh run list --limit 5

# View pull requests
gh pr list
```

**Expected:** All `gh` commands work without re-authenticating.

### Test 3: Docker Access

```bash
# Check Docker is accessible
docker --version
docker-compose --version

# List running containers (should see your host's containers)
docker ps

# Test Docker Compose
docker-compose --version

# Check Docker socket permissions
ls -l /var/run/docker.sock
# Should show: srw-rw---- ... docker ... docker.sock

# Verify you can pull images
docker pull hello-world
docker run --rm hello-world
```

**Expected:**
- Docker commands work without "permission denied" errors
- You can see containers running on your Mac
- You can pull images and run containers

### Test 4: Container Creation (Advanced)

```bash
# Test creating a sibling container
docker run --rm alpine:latest echo "Hello from sibling container"

# Test docker-compose (example)
cd /workspace/development
cat > test-compose.yml << 'EOF'
version: '3.8'
services:
  test:
    image: alpine:latest
    command: echo "Docker Compose works!"
EOF

docker-compose -f test-compose.yml up
docker-compose -f test-compose.yml down
rm test-compose.yml
```

**Expected:** Containers are created as "siblings" on Docker Desktop, not nested inside the devcontainer.

---

## 🛠️ Part 4: Using in Daily Development

### GitHub Workflow Inside Container

```bash
# Check out a new branch
git checkout -b 002-new-feature

# Make changes, commit
git add .
git commit -m "feat: Add new feature"

# Push to GitHub
git push origin 002-new-feature

# Create a pull request
gh pr create --title "New Feature" --body "Description here"

# View PR checks (GitHub Actions)
gh pr checks

# View workflow runs
gh run list

# View workflow logs
gh run view <run-id> --log
```

### Docker Development Workflow

```bash
# Run integration tests using Docker
cd /workspace/development/frappe-bench/apps/prevance_health
pytest prevance_health/tests/integration/ -v

# Start test containers
docker-compose -f test-docker-compose.yml up -d

# Run smoke tests
pytest prevance_health/tests/smoke/ -v

# Clean up
docker-compose -f test-docker-compose.yml down -v

# Deploy full stack for E2E testing
cd /workspace/development
docker-compose -f docker-compose.test.yml up -d
# Run E2E tests
pytest e2e/tests/ -v
# Teardown
docker-compose -f docker-compose.test.yml down -v
```

### GitHub Actions Results in Cursor

1. Install the **GitHub Actions** extension (already in config)
2. Open the **GitHub** sidebar (icon on left)
3. Navigate to **Actions** tab
4. View workflow runs, logs, and status in real-time

---

## 🐛 Troubleshooting

### Issue: "Permission denied" on /var/run/docker.sock

**Solution:**
1. Check Docker Desktop settings (Step 1.2 above)
2. Restart Docker Desktop completely
3. Rebuild devcontainer: `Cmd+Shift+P` → "Rebuild Container"
4. Verify socket exists: `ls -l /var/run/docker.sock`

### Issue: Git asks for credentials

**Solution:**
```bash
# On macOS host, verify SSH agent
ssh-add -l

# Re-add key if needed
ssh-add --apple-use-keychain ~/.ssh/id_ed25519

# Rebuild container
```

### Issue: `gh` commands fail with "not logged in"

**Solution:**
```bash
# Inside container:
gh auth login
# OR
gh auth setup-git

# If persistent, check on host:
cat ~/.config/gh/hosts.yml
# Should show your GitHub token

# Rebuild container to remount config
```

### Issue: Docker commands work but images don't build

**Possible causes:**
1. **BuildKit issues**: Set `DOCKER_BUILDKIT=0` if needed
2. **Network**: Check Docker Desktop network settings
3. **Resources**: Increase Docker Desktop memory/CPU limits

**Debug:**
```bash
# Check Docker daemon
docker info

# Check network
docker network ls

# Try with verbose output
docker build --no-cache --progress=plain .
```

### Issue: Container can't resolve DNS

**Solution:**
```bash
# Check DNS inside container
cat /etc/resolv.conf

# Test DNS resolution
nslookup google.com

# If fails, add to docker-compose.yml:
dns:
  - 8.8.8.8
  - 8.8.4.4
```

### Issue: SSH_AUTH_SOCK not set

**Solution:**
```bash
# On macOS host, check SSH agent is running
echo $SSH_AUTH_SOCK
# Should show path like: /private/tmp/com.apple.launchd.xxx/Listeners

# If empty, start agent
eval "$(ssh-agent -s)"
ssh-add --apple-use-keychain ~/.ssh/id_ed25519

# Rebuild container
```

---

## 📊 What Changed

### devcontainer.json

**Added Features:**
- `git:1` - Latest Git client
- `github-cli:1` - GitHub CLI (`gh` command)
- `docker-outside-of-docker:1` - Access to Docker Desktop

**Added Mounts:**
- `~/.config/gh` - GitHub CLI configuration and tokens
- `~/.gitconfig` - Git user configuration
- `~/.ssh` - SSH keys for Git authentication (already existed)

**Added Environment:**
- `SSH_AUTH_SOCK` - Forward SSH agent for keychain authentication

**Added Extensions:**
- `GitHub.vscode-pull-request-github` - PR management
- `GitHub.vscode-github-actions` - Actions viewer
- `ms-azuretools.vscode-docker` - Docker management

**Added Post-Create Command:**
- Sets correct SSH key permissions (700/600)
- Configures `gh` for Git operations

### docker-compose.yml

**Added Volume Mount:**
- `/var/run/docker.sock:/var/run/docker.sock` - Docker socket access

---

## 🎓 Technical Explanation

### Docker-outside-of-Docker Pattern

Your devcontainer doesn't run Docker **inside** itself (Docker-in-Docker). Instead, it connects to Docker Desktop on your Mac via the Docker socket.

**Architecture:**
```
┌─────────────────────────────────────────┐
│ macOS Host (Docker Desktop)             │
│                                          │
│  /var/run/docker.sock ←─────────┐       │
│         ↑                        │       │
│         │                        │       │
│  ┌──────┴──────────────────┐    │       │
│  │  DevContainer (frappe)  │    │       │
│  │                          │    │       │
│  │  docker commands ────────┘    │       │
│  │  → create sibling containers  │       │
│  └────────────────────────────────┘      │
└─────────────────────────────────────────┘
```

**Benefits:**
- No nested Docker overhead
- Direct access to Docker Desktop daemon
- Containers created are siblings, not children
- Same Docker network as host containers
- No image layer duplication

### SSH Agent Forwarding

Your SSH keys stay on macOS (secure). The devcontainer forwards authentication requests to your Mac's SSH agent via `SSH_AUTH_SOCK`.

**Flow:**
```
Git command in container
  → Needs SSH key for github.com
    → Checks SSH_AUTH_SOCK
      → Forwards to macOS SSH agent
        → Mac unlocks key from Keychain
          → Returns signature to container
            → Git authenticates to GitHub
```

**Security:** Private keys never enter the container.

---

## 🚀 Next Steps

Now that your devcontainer has full GitHub and Docker access, you can:

1. **Set up CI/CD locally:**
   ```bash
   # Test GitHub Actions workflow locally
   gh workflow run ci.yml
   gh run watch
   ```

2. **Run full integration tests:**
   ```bash
   ./scripts/run_integration_tests.sh
   ```

3. **Deploy and test in containers:**
   ```bash
   docker-compose -f docker-compose.test.yml up -d
   pytest prevance_health/tests/smoke/
   ```

4. **Manage PRs from terminal:**
   ```bash
   gh pr create
   gh pr review
   gh pr merge
   ```

---

## 📚 References

- [Dev Containers Documentation](https://containers.dev/)
- [Docker-outside-of-Docker Feature](https://github.com/devcontainers/features/tree/main/src/docker-outside-of-docker)
- [GitHub CLI Documentation](https://cli.github.com/manual/)
- [Docker Desktop for Mac](https://docs.docker.com/desktop/mac/)

---

**Setup Complete!** 🎉

Your devcontainer now has full access to GitHub and Docker Desktop. You can develop, test, and deploy entirely from within Cursor IDE.
