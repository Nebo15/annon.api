#!/bin/bash
# This setup works with Travis-CI.
# You need to specify $DOCKER_HUB_ACCOUNT, $DOCKER_USERNAME and $DOCKER_PASSWORD before using this script.

echo "Logging in into Docker Hub";
docker login -u=$DOCKER_USERNAME -p=$DOCKER_PASSWORD;

echo "Setting Gih user/password";
git config --global user.email "travis@travis-ci.com";
git config --global user.name "Travis-CI";
git config --global push.default upstream;

# When you use Travis-CI with public repos, you need to add user token so Travis will be able to push tags bag to repo.
# After enabling this, dont forget to set $GITHUB_TOKEN and replace `origin` to `upstream` on lines 27-28.
REPO_URL="https://$GITHUB_TOKEN@github.com/$TRAVIS_REPO_SLUG.git";
git remote add upstream $REPO_URL &> /dev/null

if [ "$TRAVIS_PULL_REQUEST" == "false" ]; then
  # Commit incremented version
  git add mix.exs;
  git commit -m "Increment version [ci skip]";

  if [ "$TRAVIS_BRANCH" == "$RELEASE_BRANCH" ]; then
    ./bin/ci/release.sh -a $DOCKER_HUB_ACCOUNT -t $TRAVIS_BRANCH -l;
  fi;

  if [[ "$MAIN_BRANCHES" =~ "$TRAVIS_BRANCH" ]]; then
    echo "Done. Pushing changes back to repo.";
    git push upstream HEAD:$TRAVIS_BRANCH;
    git push upstream HEAD:$TRAVIS_BRANCH --tags;
  fi;
fi;
