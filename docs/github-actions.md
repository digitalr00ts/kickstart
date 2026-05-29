# GitHub Actions Workflows

This document describes the automated CI/CD workflows for building and testing Fedora images using **Kiwi NG** with
GitHub Actions.

## Overview

Three automated workflows are available:

1. **Build Kiwi NG Image** - Builds Fedora images with Kiwi NG
2. **Test Kiwi NG Image** - Tests built images
3. **Cleanup Old Artifacts** - Manages artifact storage

## Build Kiwi NG Image Workflow

### Purpose

Automatically builds Fedora images using Kiwi NG on Ubuntu runners. Images are compressed and stored as artifacts for
30 days.

### Triggers

**Automatic (Push):**

```yaml
Triggers on push to:
- main branch
- develop branch

Only when these paths change:
- kiwi/**
- ansible/**
- scripts/build-with-kiwi.sh
- .github/workflows/build-kiwi-image.yml
```

**Automatic (Pull Request):**

```yaml
Triggers on pull requests to main when:
- kiwi/**
- ansible/**
```

**Manual (Workflow Dispatch):**

```text
Go to: Actions → Build Kiwi NG Image → Run workflow
```

Options:

- **Fedora Version**: Choose 43 or 44 (default: 44)
- **Architecture**: Choose x86_64 or aarch64 (default: x86_64)
- **Debug Mode**: Enable Kiwi NG debug logging (default: false)

### What It Does

1. **Environment Setup**
   - Installs QEMU with KVM acceleration
   - Installs Kiwi NG and dependencies
   - Frees up ~10GB of disk space
   - Sets up build environment

2. **Caching**
   - Caches Kiwi package downloads
   - Saves 2-3 minutes on subsequent builds
   - Cache key based on run ID

3. **Build Process**
   - Builds image with Kiwi NG OEM format
   - Uses native Ubuntu runner (10-15 min build time)
   - Outputs QCOW2 format
   - Compresses image with zstd

4. **Artifact Upload**
   - Uploads compressed image as artifact
   - Naming: `fedora-{version}-{arch}-{short-sha}`
   - Retention: 30 days
   - Includes build metadata JSON

### Build Outputs

**Artifacts:**

```text
fedora-44-x86_64-a120d23f.tar.zst      # Compressed image + package list
build-metadata-a120d23f/               # Build information
  └── build-metadata.json              # Detailed metadata
```

**Build Metadata JSON:**

```json
{
  "fedora_version": "44",
  "architecture": "x86_64",
  "commit_sha": "a120d23f...",
  "short_sha": "a120d23f",
  "build_time": "2026-05-29T08:00:00-07:00",
  "builder": "kiwi-ng",
  "image_name": "fedora-minimal.x86_64-44.1.7.qcow2",
  "image_size": "2.1G",
  "image_size_bytes": 2147483648,
  "compressed_size": "847M",
  "compression_ratio": "2.5x",
  "artifact_name": "fedora-44-x86_64-a120d23f.tar.zst",
  "workflow_run_id": "123456789",
  "workflow_run_number": "42"
}
```

### Performance Metrics

The workflow tracks and reports:

- **Build duration**
- **Image sizes (compressed/uncompressed)**
- **Compression ratio**
- **Fedora version and architecture**

All metrics are displayed in the workflow summary.

### Build Architecture

**What Happens:**

```text
GitHub Runner (Ubuntu) → Kiwi NG → Package Assembly → QCOW2 Image
  ↓
Compress with zstd → Upload to GitHub Artifacts
```

**No VM needed!** Kiwi NG assembles packages directly, unlike Packer which requires running a full VM.

## Test Kiwi NG Image Workflow

### Purpose

Downloads and tests built Kiwi NG images with basic verification and optional Molecule tests.

### Triggers

**Manual Only:**

```text
Go to: Actions → Test Kiwi NG Image → Run workflow
```

Options:

- **Artifact Name**: Specific artifact to test (optional)
- **Run ID**: Workflow run ID to download from (optional)

Leave both empty to test the latest build.

### What It Does

1. **Setup**
   - Installs QEMU with KVM
   - Sets up Python and uv
   - Installs project dependencies

2. **Download & Extract**
   - Downloads specified artifact (or latest)
   - Extracts compressed image
   - Verifies QCOW2 format

3. **Basic Tests**
   - Image format verification (`qemu-img info`)
   - Image integrity check (`qemu-img check`)
   - Quick boot test (verifies image boots)

4. **Advanced Tests (Optional)**
   - Molecule test scenarios (when available)
   - Full integration testing

### Test Report

The workflow generates a summary showing:

- Image information (name, size, format)
- Test results (format, integrity, boot)
- Status and next steps

### Current Status

✅ **Implemented:**

- Image extraction and verification
- QCOW2 format validation
- Quick boot test

⚠️ **Pending:**

- Full Molecule test suite (create `molecule/qemu-kiwi/`)

## Cleanup Old Artifacts Workflow

### Purpose

Automatically manages artifact storage by deleting old artifacts and reclaiming space.

### Triggers

**Automatic (Scheduled):**

```text
Runs every Sunday at 2 AM UTC
```

**Manual:**

```text
Go to: Actions → Cleanup Old Artifacts → Run workflow
```

Options:

- **Dry Run**: Preview deletions without deleting (default: true)
- **Retention Days**: Age threshold for deletion (default: 30)

### What It Does

1. **Scan**: Lists all repository artifacts
2. **Filter**: Identifies artifacts older than retention period
3. **Calculate**: Shows total space to reclaim
4. **Delete**: Removes old artifacts (unless dry run)
5. **Report**: Generates detailed summary

### Dry Run Mode

**Default behavior (safe):**

- Shows what would be deleted
- No actual deletions
- Useful for preview

**To actually delete:**

Set `dry_run` to `false` when running manually.

### Report Details

The workflow generates a summary showing:

- Total artifacts and size
- Number of old artifacts
- Space to reclaim
- List of artifacts to delete
- Deletion status for each

## Usage Examples

### Building an Image

**Automatic build on push:**

```bash
git add kiwi/
git commit -m "Update Kiwi description"
git push origin main
# Build workflow triggers automatically
```

**Manual build:**

1. Go to **Actions** tab
2. Select **Build Kiwi NG Image**
3. Click **Run workflow**
4. Select options or use defaults
5. Click **Run workflow** button

### Testing an Image

**Test latest build:**

1. Wait for build to complete
2. Go to **Actions** tab
3. Select **Test Kiwi NG Image**
4. Click **Run workflow**
5. Leave inputs empty for latest
6. Click **Run workflow** button

**Test specific artifact:**

1. Note artifact name from build run
2. Run test workflow
3. Enter artifact name
4. Click **Run workflow** button

### Cleaning Up Storage

**Preview cleanup (safe):**

1. Go to **Actions** tab
2. Select **Cleanup Old Artifacts**
3. Click **Run workflow**
4. Keep dry_run: true
5. Click **Run workflow** button

**Perform cleanup:**

1. Follow preview steps
2. Set dry_run: false
3. Adjust retention_days if needed
4. Click **Run workflow** button

## Downloading Artifacts

### Using GitHub CLI

```bash
# List recent runs
gh run list --workflow="Build Kiwi NG Image"

# Download artifact from specific run
gh run download <run-id> -n fedora-44-x86_64-a120d23f

# Extract image
tar -I zstd -xf fedora-44-x86_64-a120d23f.tar.zst
```

### Using Web UI

1. Go to **Actions** tab
2. Click on completed workflow run
3. Scroll to **Artifacts** section
4. Click artifact name to download

### Using in Local Development

```bash
# Extract downloaded artifact
tar -I zstd -xf fedora-44-x86_64-*.tar.zst

# Apply Ansible provisioning
uv run poe provision-image fedora-minimal.x86_64-*.qcow2

# Or test directly
qemu-system-x86_64 -m 2048 -drive file=fedora-minimal.x86_64-*.qcow2,format=qcow2
```

## Troubleshooting

### Build Failures

**Kiwi NG Installation Fails:**

- Check if `dnf` is available on runner
- Verify Kiwi NG packages exist in Fedora repos
- Try updating package names in workflow

**Repository Mirror Timeout:**

- Check Fedora mirror status
- Repository URLs in `kiwi/*.kiwi` may need updating
- Consider adding mirror fallbacks

**Disk Space Error:**

- Workflow frees up ~10GB automatically
- Large images may still fail
- Consider reducing `<size>` in Kiwi XML

**Package Installation Fails:**

- Check package names in `<packages>` section
- Package may have been renamed/removed in Fedora
- Review build logs for specific errors

### Test Failures

**Artifact Not Found:**

- Verify artifact name matches exactly
- Artifacts expire after 30 days
- Check if build workflow succeeded

**Boot Test Timeout:**

- Image may be corrupted
- Check build logs for errors
- Try rebuilding the image

**QEMU Errors:**

- Verify QCOW2 format with `qemu-img info`
- Check for disk corruption with `qemu-img check`
- Review QEMU logs in workflow output

### Artifact Issues

**Download Timeout:**

- Large artifacts (>1GB) may be slow
- Retry the download
- Check GitHub status page

**Storage Limit Reached:**

- GitHub limit: 2GB per artifact
- Run cleanup workflow
- Adjust retention days

## Performance Optimization

### Build Time

**Typical build times:**

- First build (no cache): 10-15 minutes
- Warm build (cache hit): 8-12 minutes
- With debug mode: +3-5 minutes

**Faster than Packer!**

- Packer: 15-40 minutes (full VM installation)
- Kiwi NG: 10-15 minutes (direct package assembly)

**Factors affecting speed:**

- Package download speed (variable)
- Cache hit/miss (2-3 min difference)
- Number of packages being installed
- Mirror performance

### Cache Efficiency

**What's cached:**

- Package downloads (`~/.cache/kiwi`)
- Repository metadata
- Previously downloaded RPMs

**Cache behavior:**

- Per-run caching (no cross-run persistence yet)
- Could be improved with better cache keys
- Consider implementing package cache restore

### Artifact Size

**Compression:**

- Uncompressed qcow2: ~2-3GB
- Compressed with zstd (level 19): ~800MB-1.2GB
- Compression ratio: 2-3x

**Storage:**

- 30-day retention
- GitHub limit: 2GB per artifact
- Total repository limit: varies by plan

## Best Practices

### When to Trigger Builds

**Good triggers:**

- Changes to Kiwi descriptions
- Ansible provisioning updates
- Configuration script changes
- Fedora point release updates

**Avoid triggers:**

- Documentation-only changes
- Test file updates (unless test workflow)
- README modifications

**Use path filters:**

The workflow already filters appropriately - only builds when relevant files change.

### Managing Artifacts

**Keep:**

- Latest successful build from main
- Tagged release builds
- Known good configurations

**Delete:**

- Failed builds
- Old development builds
- Superseded versions

**Use cleanup workflow:**

- Run dry-run first (preview)
- Adjust retention as needed
- Monitor storage usage regularly

### Testing Strategy

**Basic Tests (Current):**

- Format verification
- Integrity check
- Boot test

**Future Enhancements:**

- Full Molecule test suite
- SSH connectivity test
- Service verification
- Ansible provisioning test

## Advanced Configuration

### Custom Build Variables

Modify workflow to use different Kiwi descriptions:

```yaml
- name: Build image
  run: |
    sudo kiwi-ng --type oem system build \
      --description kiwi/custom/ \
      --target-dir output/
```

### Multi-Architecture Builds

Add matrix strategy for multiple architectures:

```yaml
strategy:
  matrix:
    arch: [x86_64, aarch64]

steps:
  - name: Build
    run: |
      sudo kiwi-ng --type oem system build \
        --description kiwi/fedora-44-${{ matrix.arch }}.kiwi \
        --target-dir output/
```

**Note:** aarch64 builds require ARM64 runners (not available on free tier) or QEMU emulation (slow).

### External Storage

For production, consider uploading to external storage:

```yaml
- name: Upload to S3
  run: |
    aws s3 cp artifact.tar.zst s3://bucket/images/
  env:
    AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
    AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
```

### Notifications

Add notification steps for build status:

```yaml
- name: Notify on failure
  if: failure()
  uses: slack/action@v1
  with:
    webhook-url: ${{ secrets.SLACK_WEBHOOK }}
    message: "Kiwi NG build failed for ${{ github.sha }}"
```

## Workflow Permissions

The workflows require these permissions:

**Build workflow:**

- `contents: read` - Checkout code
- `actions: write` - Upload artifacts

**Test workflow:**

- `contents: read` - Checkout code
- `actions: read` - Download artifacts

**Cleanup workflow:**

- `contents: read` - Checkout code
- `actions: write` - Delete artifacts

These are configured in each workflow file with the `permissions:` key.

## GitHub Actions Limits

**Free tier (public repos):**

- Unlimited build minutes
- 2GB artifact storage per run
- 10GB cache storage per repository

**Free tier (private repos):**

- 2,000 minutes/month
- Same storage limits

**Our usage (typical):**

- ~10-15 minutes per build
- ~800MB-1.2GB per artifact
- Minimal cache usage

**Public repo benefits:**

- Unlimited builds
- Great for open source projects
- No minute restrictions

## Comparison: Kiwi NG vs Packer Workflows

### Build Speed

| Metric      | Packer (Old) | Kiwi NG (New) | Improvement     |
| ----------- | ------------ | ------------- | --------------- |
| Cold build  | 20-30 min    | 10-15 min     | **50% faster**  |
| Warm build  | 15-20 min    | 8-12 min      | **40% faster**  |
| Debug build | 25-35 min    | 13-18 min     | **48% faster**  |

### Resource Usage

| Resource   | Packer     | Kiwi NG | Benefit        |
| ---------- | ---------- | ------- | -------------- |
| Disk space | ~15GB      | ~8GB    | Less storage   |
| Memory     | ~4GB       | ~2GB    | Lower overhead |
| CPU        | High (KVM) | Medium  | More efficient |

### Complexity

- **Packer**: Multiple steps (ISO download → VM boot → Installation → Configuration)
- **Kiwi NG**: Single step (Package assembly)
- **Winner**: Kiwi NG (simpler, fewer moving parts)

### Reliability

- **Packer**: Depends on network (ISO), VM stability, SSH connectivity
- **Kiwi NG**: Depends on package repos only
- **Winner**: Kiwi NG (fewer failure points)

## Migration from Packer

If you had Packer workflows:

1. ✅ Replace `build-packer-image.yml` with `build-kiwi-image.yml`
2. ✅ Update test workflow to handle Kiwi artifacts
3. ✅ Update artifact naming conventions
4. ✅ Remove ISO caching (not needed)
5. ✅ Update documentation

See [DEPRECATION.md](../DEPRECATION.md) for detailed migration guide.

## Next Steps

1. **Add Build Badges**: Display build status in README
2. **Enable Full Testing**: Create Molecule scenario for Kiwi images
3. **Add Release Workflow**: Attach images to GitHub releases
4. **Multi-Architecture**: Add ARM64 builds (requires ARM runners)
5. **Improve Caching**: Better cache strategy for packages

## References

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Kiwi NG Documentation](https://osinside.github.io/kiwi/)
- [Building with Kiwi NG](../kiwi/README.md)
- [Testing Infrastructure](testing.md)
- [Deprecation Notice](../DEPRECATION.md)
