# 🔧 Fixing "No Space Left on Device" Error

## Problem Summary

Your system has **two issues**:

1. ❌ **Disk is 100% full** (only 29MB free out of 62GB)
2. ❌ **Path contains spaces** causing bash export errors

---

## 🚨 URGENT: Free Up Disk Space First

### Step 1: Clean Docker Build Cache (Recommended - Safe)

Docker is using 4.2GB of build cache that can be freed:

```bash
# Clean up Docker build cache (safe - won't affect running containers)
docker builder prune -a -f

# This will free up approximately 4.2GB
```

### Step 2: Clean Docker System (More Aggressive)

If you need more space:

```bash
# Remove all unused Docker data (images, containers, volumes, networks)
docker system prune -a --volumes -f

# This will free up approximately 5GB total
```

⚠️ **Warning**: This will remove:
- All stopped containers
- All unused images
- All unused volumes
- All build cache

### Step 3: Find Large Files on Your System

```bash
# Find the 20 largest directories in your home folder
du -h ~ --max-depth=2 2>/dev/null | sort -hr | head -20

# Find large files (over 1GB)
find ~ -type f -size +1G 2>/dev/null -exec ls -lh {} \;
```

Common culprits:
- `~/.cache/` - Application caches
- `~/.local/share/` - Application data
- `~/Downloads/` - Old downloads
- `~/.npm/` - Node.js cache
- `~/.cache/pip/` - Python package cache

### Step 4: Clean Common Cache Directories

```bash
# Clean npm cache
npm cache clean --force

# Clean pip cache
pip cache purge

# Clean apt cache (if using Ubuntu/Debian)
sudo apt clean
sudo apt autoremove

# Clean thumbnail cache
rm -rf ~/.cache/thumbnails/*

# Clean browser caches (example for Chrome)
rm -rf ~/.cache/google-chrome/
rm -rf ~/.cache/chromium/
```

---

## 🔧 Fix 2: Handle Path with Spaces

Your path `/media/aashikant/GAME Volume/aicode/OpenHands` has spaces, which causes issues.

### Option A: Use Proper Quoting (Recommended)

```bash
cd "/media/aashikant/GAME Volume/aicode/OpenHands"
WORKSPACE_BASE="$PWD/workspace" make docker-run
```

### Option B: Create a Symlink (Easier)

```bash
# Create a symlink without spaces
ln -s "/media/aashikant/GAME Volume/aicode/OpenHands" ~/openhands

# Now use the symlink
cd ~/openhands
make docker-run
```

### Option C: Move to a Path Without Spaces

```bash
# Move the project to your home directory
mv "/media/aashikant/GAME Volume/aicode/OpenHands" ~/OpenHands
cd ~/OpenHands
make docker-run
```

---

## ✅ Complete Fix Procedure

Follow these steps in order:

### 1. Free Up Space

```bash
# Clean Docker (this alone should give you 4-5GB)
docker system prune -a --volumes -f

# Verify you have space now
df -h /
```

You should see at least 5GB free after this.

### 2. Navigate to Project with Proper Quoting

```bash
cd "/media/aashikant/GAME Volume/aicode/OpenHands"
```

### 3. Run Docker with Explicit Workspace Path

```bash
# Set workspace to a path without spaces
mkdir -p ~/openhands-workspace
WORKSPACE_BASE=~/openhands-workspace make docker-run
```

Or use the symlink approach:

```bash
# Create symlink
ln -s "/media/aashikant/GAME Volume/aicode/OpenHands" ~/openhands

# Use it
cd ~/openhands
make docker-run
```

---

## 🎯 Quick Commands (Copy-Paste Ready)

```bash
# 1. Clean Docker to free space
docker system prune -a --volumes -f

# 2. Verify space is available
df -h /

# 3. Create symlink for easier access
ln -s "/media/aashikant/GAME Volume/aicode/OpenHands" ~/openhands

# 4. Navigate and run
cd ~/openhands
make docker-run
```

---

## 📊 Monitoring Disk Space

### Check Current Usage

```bash
# Overall disk usage
df -h

# Docker usage
docker system df

# Largest directories in home
du -h ~ --max-depth=1 | sort -hr | head -10
```

### Set Up Alerts (Optional)

Add this to your `~/.bashrc` to get warnings:

```bash
# Warn if disk is over 90% full
DISK_USAGE=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')
if [ "$DISK_USAGE" -gt 90 ]; then
    echo "⚠️  WARNING: Disk is ${DISK_USAGE}% full!"
fi
```

---

## 🔍 Troubleshooting

### Still Getting "No Space" Error?

1. **Check if Docker is using a different partition:**
   ```bash
   docker info | grep "Docker Root Dir"
   df -h $(docker info | grep "Docker Root Dir" | cut -d: -f2)
   ```

2. **Check inode usage** (sometimes you run out of inodes, not space):
   ```bash
   df -i /
   ```

3. **Find what's using space:**
   ```bash
   sudo du -h / --max-depth=1 2>/dev/null | sort -hr | head -20
   ```

### Docker Build Still Fails?

Try building with a different temp directory:

```bash
# Use a different temp directory with more space
export TMPDIR=/media/aashikant/GAME\ Volume/tmp
mkdir -p "$TMPDIR"
make docker-run
```

---

## 💡 Prevention Tips

1. **Regular Cleanup**: Run `docker system prune` weekly
2. **Monitor Space**: Check `df -h` regularly
3. **Use .dockerignore**: Ensure large files aren't copied into builds
4. **Limit Build Cache**: Set Docker to use less cache:
   ```bash
   # In ~/.docker/daemon.json
   {
     "max-concurrent-downloads": 3,
     "max-concurrent-uploads": 5,
     "builder": {
       "gc": {
         "enabled": true,
         "defaultKeepStorage": "10GB"
       }
     }
   }
   ```

---

## 📝 Summary

**Immediate Actions:**
1. ✅ Run `docker system prune -a --volumes -f` to free 4-5GB
2. ✅ Create symlink: `ln -s "/media/aashikant/GAME Volume/aicode/OpenHands" ~/openhands`
3. ✅ Run from symlink: `cd ~/openhands && make docker-run`

**Long-term:**
- Clean Docker cache regularly
- Monitor disk usage
- Keep at least 10GB free for Docker builds

---

Need help? The error messages will be much clearer once you have free space!
