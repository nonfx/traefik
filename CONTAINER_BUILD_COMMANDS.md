# CONTAINER BUILD COMMANDS

This document contains the commands used to build multiarch Traefik container images with security fixes and run Aikido security scans.

## Prerequisites

- Docker with buildx support
- Existing builder configured (multiarch, multiarch-builder, or traefik-builder)
- Aikido Local Scanner installed
- AWS CLI configured with appropriate credentials
- Environment variables:
  - `AIKIDO_APIKEY` - Aikido API key for security scans
  - `AWS_ACCOUNT_ID` - AWS account ID for ECR
  - `AWS_REGION` - AWS region (e.g., ap-southeast-1)

## Build Process for v3.6.6 with Security Fixes

### 1. Checkout to v3.6.6 Tag

```bash
git checkout v3.6.6
```

### 2. Verify Git Status

```bash
git status
```

This should show modified files: `Dockerfile`, `go.mod`, `go.sum` with security updates.

### 3. Build Binaries for Multiple Architectures

#### Build for linux/amd64

```bash
make binary-linux-amd64
```

#### Build for linux/arm64

```bash
make binary-linux-arm64
```

### 4. Build Docker Images

Docker buildx doesn't support `--load` with multiarch manifest lists, so build each platform separately.

#### Build for amd64

```bash
docker buildx build --load --platform linux/amd64 -t traefik:v3.6.6-amd64 -f Dockerfile .
```

#### Build for arm64

```bash
docker buildx build --load --platform linux/arm64 -t traefik:v3.6.6-arm64 -f Dockerfile .
```

### 5. Verify Built Images

```bash
docker images traefik
```

Expected output should include:
- `traefik:v3.6.6-amd64`
- `traefik:v3.6.6-arm64`

### 6. Run Aikido Security Scans

Source environment variables and run scans on both images:

#### Scan amd64 image

```bash
source ~/.zshrc && aikido-local-scanner image-scan traefik:v3.6.6-amd64 --apikey $AIKIDO_APIKEY
```

#### Scan arm64 image

```bash
source ~/.zshrc && aikido-local-scanner image-scan traefik:v3.6.6-arm64 --apikey $AIKIDO_APIKEY
```

### 7. Push to AWS ECR

Login to AWS ECR:

```bash
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com
```

Build and push multiarch image directly to ECR:

```bash
docker buildx build --push --platform linux/amd64,linux/arm64 \
  -t ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/traefik:v3.6.6 \
  -f Dockerfile .
```

## Git Workflow

### Create Branch and Commit Changes

```bash
# Create new branch from v3.6.6 tag
git checkout -b v3.6.6-container-fix

# Verify staged changes
git status
git diff --cached

# Commit with descriptive message
git commit -m "Security updates for container and dependencies

- Upgrade Go to v1.25.5 to fix stdlib vulnerabilities
- Bump github.com/valyala/fasthttp to v1.67.0 (CVE fixes)
- Bump github.com/andybalholm/brotli to v1.2.0
- Update Dockerfile to upgrade Alpine packages including OpenSSL 3.5.4-r0 (CVE-2025-9230)
- Add wget package for enhanced container utilities

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"

# Verify commit
git log -1 --stat
```

## Security Fixes Included

### Dockerfile Updates
- Added Alpine edge repository for latest security patches
- Upgraded all Alpine packages including OpenSSL to 3.5.4-r0 (fixes CVE-2025-9230)
- Added wget package for enhanced container utilities
- Applied security updates with `apk upgrade --no-cache`

### Go Dependencies
- **Go version**: Upgraded from 1.24.0 to 1.25.5 (stdlib vulnerability fixes)
- **fasthttp**: Upgraded from 1.58.0 to 1.67.0 (CVE fixes)
- **brotli**: Upgraded from 1.1.1 to 1.2.0

## Notes

- Both amd64 and arm64 architectures are supported
- All security scans should be performed before pushing to any registry
- The branch `v3.6.6-container-fix` contains all security updates
- Images can be built locally for testing or pushed directly to AWS ECR
- When pushing to ECR, buildx creates a multiarch manifest automatically
