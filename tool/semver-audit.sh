#!/bin/bash
if env | grep -q ^GIT_MERGE_HEAD=
then
  echo "Running semver-audit..."
  pub run semver_audit report --base-branch $GIT_MERGE_BRANCH --base-commit $GIT_MERGE_HEAD --head-branch $GIT_BRANCH --head-commit $GIT_COMMIT --repo Workiva/w_module
else
  echo "Not a PR build, skipping semver-audit."
fi

