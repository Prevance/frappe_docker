# DevContainer Quick Reference

## 🚀 Quick Setup (5 Minutes)

### On macOS Host (One-Time Setup)

```bash
# 1. Install GitHub CLI
brew install gh

# 2. Authenticate
gh auth login

# 3. Add SSH key to agent
ssh-add --apple-use-keychain ~/.ssh/id_ed25519

# 4. Configure Docker Desktop
# Settings → General → "Use Docker Compose V2" ✓
# Settings → Advanced → "Allow default Docker socket" ✓
# Apply & Restart
```

### In Cursor IDE

1. Open project: `cursor /path/to/frappe_docker`
2. Press `Cmd+Shift+P`
3. Type: **"Dev Containers: Rebuild Container"**
4. Wait 3-5 minutes for rebuild

### Verify Setup

```bash
# Inside container terminal:
./.devcontainer/verify_setup.sh
```

---

## ✅ What You Can Do Now

### Git & GitHub

```bash
# Git operations (no credentials needed)
git status
git commit -m "message"
git push

# GitHub CLI
gh pr list
gh pr create
gh run list
gh run view --log

# SSH to GitHub
ssh -T git@github.com
```

### Docker

```bash
# Docker commands
docker ps                    # List all containers
docker images                # List images
docker pull nginx:latest     # Pull images

# Docker Compose
docker-compose up -d         # Start services
docker-compose down          # Stop services
docker-compose logs -f       # View logs

# Run containers (siblings, not nested)
docker run --rm alpine:latest echo "Hello"
```

### Integration Testing

```bash
# Start test environment
cd /workspace/development/frappe-bench/apps/prevance_health
docker-compose -f test-compose.yml up -d

# Run integration tests
pytest prevance_health/tests/integration/ -v

# Run smoke tests
pytest prevance_health/tests/smoke/ -v

# Cleanup
docker-compose -f test-compose.yml down -v
```

---

## 📁 What Was Added

### devcontainer.json

**Features:**
- ✅ Git client
- ✅ GitHub CLI
- ✅ Docker-outside-of-Docker

**Mounts:**
- ✅ `~/.ssh` → SSH keys
- ✅ `~/.config/gh` → GitHub tokens
- ✅ `~/.gitconfig` → Git config

**Extensions:**
- ✅ GitHub Pull Requests
- ✅ GitHub Actions
- ✅ Docker

### docker-compose.yml

**Volume:**
- ✅ `/var/run/docker.sock` → Docker socket

---

## 🐛 Quick Troubleshooting

### Git asks for credentials

```bash
# On Mac:
ssh-add -l                                    # Check if key loaded
ssh-add --apple-use-keychain ~/.ssh/id_ed25519  # Add key

# Rebuild container
```

### Docker permission denied

```bash
# Check Docker Desktop is running
# Verify socket mount:
ls -l /var/run/docker.sock

# Restart Docker Desktop
# Rebuild container
```

### gh not authenticated

```bash
# Inside container:
gh auth login
# OR
gh auth setup-git
```

---

## 📊 File Locations

| What | Where |
|------|-------|
| Configuration | `.devcontainer/devcontainer.json` |
| Compose File | `.devcontainer/docker-compose.yml` |
| Full Guide | `.devcontainer/SETUP_GUIDE.md` |
| This Reference | `.devcontainer/QUICK_REFERENCE.md` |
| Verification Script | `.devcontainer/verify_setup.sh` |

---

## 🔗 Common Commands

### GitHub Workflow

```bash
# Create feature branch
git checkout -b 002-feature-name

# Make changes, commit
git add .
git commit -m "feat: Add feature"

# Push and create PR
git push origin 002-feature-name
gh pr create --title "Feature" --body "Description"

# View PR status
gh pr status
gh pr checks

# Merge when ready
gh pr merge --squash
```

### Docker Development

```bash
# Check containers
docker ps -a

# View logs
docker logs -f <container_id>

# Execute command in container
docker exec -it <container_id> bash

# Clean up
docker system prune -a --volumes
```

### Frappe Development

```bash
# Navigate to app
cd /workspace/development/frappe-bench/apps/prevance_health

# Run tests
pytest prevance_health/tests/ -v

# Run specific test
pytest prevance_health/tests/unit/test_auth.py -v

# Check linting
ruff check prevance_health/

# Format code
ruff format prevance_health/
```

---

## 🆘 Need Help?

1. **Read full guide**: `.devcontainer/SETUP_GUIDE.md`
2. **Run verification**: `./.devcontainer/verify_setup.sh`
3. **Check status**:
   ```bash
   git config --list
   gh auth status
   docker info
   ```

---

**Last Updated**: February 17, 2026
