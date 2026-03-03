# GitHub Artifacts Automation for fMoney

## Overview

This document describes the implementation of automated GitHub artifact downloads for the fMoney desktop applications, replacing the static download URLs with dynamic GitHub artifact URLs.

## Implementation Details

### 1. GitHub Artifacts Service (`lib/services/github_artifacts_service.dart`)

A service that fetches the latest download URLs from GitHub releases and workflow artifacts.

**Features:**

- Prioritizes GitHub releases (permanent) over workflow artifacts (temporary)
- Falls back to original money.vteam.com URLs if GitHub API fails
- Supports Windows, Linux, and macOS platforms
- Handles API errors gracefully with fallback URLs

**Key Methods:**

- `getLatestArtifactUrls()` - Main method to fetch all platform URLs
- `getDownloadUrl(platform)` - Get URL for specific platform
- `getReleasesPageUrl()` - Returns GitHub releases page URL
- `getActionsPageUrl()` - Returns GitHub Actions page URL

### 2. Updated Platforms Page (`lib/views/panels/platforms/platforms_page.dart`)

Converted from StatelessWidget to StatefulWidget to handle async URL fetching.

**Changes:**

- Added `FutureBuilder` to handle async URL loading
- Shows loading indicator while fetching URLs
- Uses dynamic URLs from GitHub artifacts service
- Falls back to original URLs if service fails

### 3. Enhanced GitHub Actions Workflow (`.github/workflows/builds.yml`)

**New Features:**

- Creates proper ZIP/TAR.GZ archives for each platform
- Automatically creates GitHub releases on main branch pushes
- Includes release notes with installation instructions
- Better artifact naming and retention policies
- **Automatic cleanup**: Keeps only latest 2 releases to manage storage
- **Workflow cleanup**: Removes old workflow runs to prevent bloat

**Workflow Steps:**

1. Build applications for Windows, Linux, and macOS
2. Create compressed archives (ZIP for Windows/macOS, TAR.GZ for Linux)
3. Upload artifacts (no time limit - quantity controlled by cleanup)
4. Create GitHub release with all platform binaries (permanent)
5. **Cleanup**: Delete releases older than the latest 2
6. **Cleanup**: Remove old artifacts (keep latest 2 per platform)
7. **Cleanup**: Remove old workflow runs (keep latest 10)

**Storage Management Strategy:**

- **Releases**: Permanent, but only keep latest 2 releases
- **Artifacts**: Quantity-based cleanup (keep latest 2 per platform)
- **Workflow Runs**: Keep only latest 10 successful runs
- **No time-based limits**: Pure quantity control for predictable storage

## How It Works

### For Users

1. User opens the platforms page in the app
2. App automatically fetches latest download URLs from GitHub
3. Download buttons point to the latest stable releases
4. If GitHub is unavailable, falls back to money.vteam.com URLs

### For Developers

1. Push to main branch triggers automated build
2. GitHub Actions builds all desktop platforms
3. New release is automatically created with proper binaries
4. Users get access to latest builds immediately

## Benefits

1. **Always Latest**: Users always download the most recent version
2. **Automated**: No manual upload required
3. **Reliable**: Multiple fallback mechanisms
4. **Professional**: Proper GitHub releases with versioning
5. **Cross-Platform**: Consistent experience across all platforms

## Testing

Unit tests are included in `test/services/github_artifacts_service_test.dart`:

- URL validation
- Platform handling
- Fallback mechanisms
- Service integration

## Storage Management

### GitHub Limits and Considerations

GitHub has storage limits for artifacts and releases that can impact repository maintenance:

- **Artifact Storage**: Limited per repository, artifacts expire after retention period
- **Release Storage**: Counted against repository storage limits
- **Workflow Run Storage**: Logs and artifacts from workflow runs consume storage

### Automated Cleanup Strategy

To avoid reaching GitHub storage limits, the workflow implements **quantity-based** cleanup instead of time-based retention:

#### Why Quantity-Based Control is Better

- **Predictable**: You always know exactly how many items are stored
- **Immediate**: Old items are removed as soon as the limit is exceeded
- **No Confusion**: No need to calculate "7 days from now" or worry about time zones
- **Efficient**: Storage usage scales with development activity, not time
- **Clear**: Easy to understand "keep latest 2" vs "keep for 7 days"

#### Release Cleanup

- **Keeps**: Latest 2 releases only
- **Deletes**: Older releases and their assets automatically
- **Preserves**: Recent versions for rollback options
- **Frequency**: Runs after each new release creation

#### Workflow Run Cleanup

- **Keeps**: Latest 10 successful workflow runs
- **Deletes**: Older successful runs and all failed runs
- **Preserves**: Recent build history for debugging
- **Benefit**: Reduces log storage and improves workflow performance

#### Artifact Retention

- **Quantity Control**: Keep latest 2 artifacts per platform (Windows, Linux, macOS)
- **No Time Limits**: Artifacts persist until quantity limit is exceeded
- **Automatic Cleanup**: Old artifacts deleted when new ones are created
- **Predictable Storage**: Maximum 6 artifacts total (2 × 3 platforms)
- **Permanent Storage**: Release assets serve as permanent backup

### Storage Benefits

1. **Predictable Storage**: Maximum 2 releases + 6 artifacts = 8 files total
2. **Quantity-Based Control**: No confusing time-based calculations
3. **Immediate Cleanup**: Old artifacts removed as soon as limit exceeded
4. **Log Management**: Workflow runs limited to prevent bloat
5. **Cost Control**: Stays well within GitHub free tier limits

### Manual Override

If needed, you can manually:

- Delete specific releases through GitHub web interface
- Adjust release limit in workflow (modify `releases_to_keep = releases[:2]`)
- Change artifact limit in workflow (modify `toKeep = sortedArtifacts.slice(0, 2)`)
- Change workflow run limit (modify `successfulRuns.slice(10)`)
- Clear artifacts/runs manually in Actions tab

## Future Enhancements

1. **Version Checking**: Display current vs latest version
2. **Auto-Update**: Implement in-app update mechanism
3. **Beta Releases**: Support for pre-release channels
4. **Statistics**: Track download counts and platform usage

## Troubleshooting

### Common Issues

1. **API Rate Limits**: GitHub API has rate limits for unauthenticated requests
   - Solution: Service falls back to original URLs automatically

2. **Missing Artifacts**: If workflow fails or artifacts are missing
   - Solution: Service gracefully handles missing platforms

3. **Network Issues**: If GitHub is unreachable
   - Solution: Fallback URLs ensure users can still download

### Debug Information

The service includes comprehensive error handling and logging. Check console output for:

- API response status codes
- Fallback URL usage
- Network error details

## Security Considerations

- No authentication tokens required (uses public API)
- All URLs are HTTPS
- Fallback URLs are trusted (money.vteam.com)
- No sensitive data is stored or transmitted
