#!/bin/bash

DOCKER_IMAGE=$TRAVIS_REPO_SLUG
DOCKER_DEV_TAG=$([ "$TRAVIS_BRANCH" == "master" ] || echo "-dev")
DOCKER_TAG=${TRAVIS_BUILD_NUMBER}-${TRAVIS_COMMIT:0:8}${DOCKER_DEV_TAG}
DOCKER_LATEST_TAG=latest${DOCKER_DEV_TAG}

AUTHOR="$(git log -1 $TRAVIS_COMMIT --pretty="%aN")"
COMMIT_HASH=${TRAVIS_COMMIT:0:8}
BUILD_URL=https://travis-ci.com/${TRAVIS_REPO_SLUG}/builds/${TRAVIS_BUILD_ID}
COMPARE_URL=https://github.com/${TRAVIS_REPO_SLUG}/compare/${TRAVIS_COMMIT_RANGE}

if [ "$TRAVIS_TEST_RESULT" = "0" ]; then
  echo
  echo "Commit message: ${TRAVIS_COMMIT_MESSAGE}"

  read -r -d '' PAYLOAD << EndOfMessage
  {
    "attachments": [
      {
        "text": "Build <${BUILD_URL}|#${TRAVIS_BUILD_ID}> (<${COMPARE_URL}|${COMMIT_HASH}>) of <b>${TRAVIS_REPO_SLUG}@${TRAVIS_BRANCH}</b> by ${AUTHOR} passed :the_horns:",
        "color": "good",
      }
    ]
  }
  EndOfMessage
else
  read -r -d '' PAYLOAD << EndOfMessage
  {
    "attachments": [
      {
        "text": "Build <${BUILD_URL}|#${TRAVIS_BUILD_ID}> (<${COMPARE_URL}|${COMMIT_HASH}>) of <b>${TRAVIS_REPO_SLUG}@${TRAVIS_BRANCH}</b> by ${AUTHOR} failed :sob:",
        "color": "danger",
      }
    ]
  }
  EndOfMessage
fi

curl -X POST -H 'Content-type: application/json' --data "${PAYLOAD}" $SLACK_WEBHOOK_URL
