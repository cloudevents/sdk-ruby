# Releasing

Releases can be performed only by users with write access to the repository.

To perform a release:

 1. Go to the GitHub Actions tab, and launch the "Request Release" workflow.
    You can leave the input field blank.

 2. The workflow will analyze the commit messages since the last release, and
    open a pull request with a new version and a changelog entry. You can
    optionally edit this pull request to modify the changelog or change the
    version released.

 3. Merge the pull request (keeping the `release: pending` label set.) Once the
    CI tests have run successfully, a job will run automatically to perform the
    release, including tagging the commit in git, building and releasing a gem,
    and building and pushing documentation.

These tasks can also be performed manually by running the appropriate scripts
locally. See `toys release request --help` and `toys release perform --help`
for more information.

If a release fails, you may need to delete the release tag before retrying.

