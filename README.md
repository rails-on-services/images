
## Building Images

### CLI Image

The CLI image is built when there is a commit to the master branch of the cli repoistory
This is invoked from the circle config in the cli repo which uses the circleci api to trigger a build on the image repository

The CLI Dockerfile clones the setup reposistory and runs ansible playbooks from teh setup repo
to install it's tools

So whenever a CLI image is built the Dockerfile will check if there is a newer commit on the setup
repository and if there is it will bust the cache and trigger a new clone of the repo
and re-run the ansible playbooks

test
