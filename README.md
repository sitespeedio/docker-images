# Docker base images for sitespeed.io

The base images for [sitespeed.io](https://github.com/sitespeedio/sitespeed.io) and [Browsertime](https://github.com/sitespeedio/browsertime). Each image is built on top of the image before it:

| Directory | Image | Contents |
| --- | --- | --- |
| [node](node/) | `sitespeedio/node` | Ubuntu and NodeJS |
| [visualmetrics-deps](visualmetrics-deps/) | `sitespeedio/visualmetrics-deps` | The dependencies for [VisualMetrics](https://github.com/WPO-Foundation/visualmetrics): FFmpeg and Python |
| [browsers](browsers/) | `sitespeedio/webbrowsers` | Chrome, Firefox and Edge. For AMD64 you can choose versions. For ARM64 we use the latest supported version. |

All versions are in [docker-bake.hcl](docker-bake.hcl).

## Release
Every day the [Check for new versions workflow](../../actions/workflows/check-versions.yml) looks for new versions of Ubuntu, the NodeJS LTS, Chrome, Firefox and Edge. When it finds one, it opens an "Update versions" pull request that changes [docker-bake.hcl](docker-bake.hcl). The [Build workflow](../../actions/workflows/build.yml) builds the images and runs the sitespeed.io tests on it, and when they pass on both AMD64 and ARM64 it merges the pull request. If a test fails, the pull request stays open for you to look at. You can also change the versions or the Dockerfiles in your own pull request, which you merge yourself.

When a change to [docker-bake.hcl](docker-bake.hcl) or a Dockerfile is merged to main, the [Release workflow](../../actions/workflows/release.yml) starts. It builds the first image that changed and all the images after it, natively on AMD64 and ARM64 runners. Then it opens a "Use sitespeedio/webbrowsers:..." pull request in [sitespeed.io](https://github.com/sitespeedio/sitespeed.io) and [Browsertime](https://github.com/sitespeedio/browsertime) that changes the `FROM` line of the Dockerfile. The CI of each project tests the new image, and you merge the pull request.

### The GitHub App
Pushes and pull requests made with the `GITHUB_TOKEN` do not start other workflows, and the `GITHUB_TOKEN` cannot write to other repositories. The workflows therefore use a GitHub App in the sitespeedio organization:

* Repository permissions: **Contents** read and write, **Pull requests** read and write.
* Installed on docker-images, sitespeed.io and browsertime.
* The client ID in the organization or repository variable `RELEASE_APP_CLIENT_ID`, and a private key in the secret `RELEASE_APP_PRIVATE_KEY`.

To start a release by hand from the command line with the [GitHub CLI](https://cli.github.com/), select the first image to build, and follow the run:

```
gh workflow run release.yml -R sitespeedio/docker-images -f start_at=node
gh run watch -R sitespeedio/docker-images
```

The tags get the date of the release, for example `sitespeedio/webbrowsers:chrome-156.0-firefox-159.0-edge-156.0-20261031`. The workflow writes the new tags to the `*_PUBLISHED_TAG` variables in [docker-bake.hcl](docker-bake.hcl) and to the summary of the run. Use the `sitespeedio/webbrowsers` tag in the Browsertime and sitespeed.io Dockerfiles.

## Build locally
Build all images for your platform:

```
docker buildx bake --load
```

Build only the browsers image on top of the published `sitespeedio/visualmetrics-deps` image:

```
START_AT=browsers docker buildx bake --load from-browsers
```

Show the build configuration:

```
docker buildx bake --print
```
