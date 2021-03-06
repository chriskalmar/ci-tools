#!/bin/bash

# skip pull requests by renovate bot
echo "TRAVIS_PULL_REQUEST_BRANCH: ${TRAVIS_PULL_REQUEST_BRANCH:-$TRAVIS_BRANCH}"
if [[ ${TRAVIS_PULL_REQUEST_BRANCH:-$TRAVIS_BRANCH} = renovate/* ]]; then
  echo 'skipping renovate bot PR'
  exit 0
fi

DOCKER_IMAGE=$TRAVIS_REPO_SLUG
DOCKER_DEV_TAG=$([ "$TRAVIS_BRANCH" == "master" ] || echo "-dev")
DOCKER_TAG=${TRAVIS_BUILD_NUMBER}-${TRAVIS_COMMIT:0:8}${DOCKER_DEV_TAG}
DOCKER_LATEST_TAG=latest${DOCKER_DEV_TAG}

AUTHOR="$(git log -1 $TRAVIS_COMMIT --pretty="%aN")"
COMMIT_HASH=${TRAVIS_COMMIT:0:8}
BUILD_URL=https://travis-ci.com/${TRAVIS_REPO_SLUG}/builds/${TRAVIS_BUILD_ID}
COMPARE_URL=https://github.com/${TRAVIS_REPO_SLUG}/compare/${TRAVIS_COMMIT_RANGE}
TRAVIS_COMMIT_MESSAGE="$(git log $TRAVIS_COMMIT_RANGE --pretty='- *%s*')"


POSITIVE_EMOJI=(":the_horns:" ":ok_hand:" ":raised_hands:" ":sunglasses:" ":slightly_smiling_face:" ":relieved:" ":rocket:" ":tada:" ":+1:" ":muscle:" ":balloon:")
NEGATIVE_EMOJI=(":scream:" ":hankey:" ":bomb:" ":cry:" ":sob:" ":tired_face:" ":face_with_head_bandage:" ":skull_and_crossbones:" ":see_no_evil:" ":biohazard_sign:" ":warning:" ":fire:" ":rain_cloud:" ":radioactive_sign:" ":hurtrealbad:")
RANDOM=$$$(date +%s)



if [ "$TRAVIS_TEST_RESULT" = "0" ]; then
  EMOJI=${POSITIVE_EMOJI[$RANDOM % ${#POSITIVE_EMOJI[@]} ]}

  read -r -d '' PAYLOAD << EndOfSuccess
  {
    "attachments": [
      {
        "text": ":white_check_mark: \nBuild <${BUILD_URL}|#${TRAVIS_BUILD_ID}> (<${COMPARE_URL}|${COMMIT_HASH}>) of *${TRAVIS_REPO_SLUG}@${TRAVIS_BRANCH}* \nby ${AUTHOR} passed $EMOJI \n${TRAVIS_COMMIT_MESSAGE}",
        "color": "good",
        "fields": [
          {
            "title": "Docker Latest Tag",
            "value": "${DOCKER_LATEST_TAG}",
            "short": true
          },
          {
            "title": "Docker Tag",
            "value": "${DOCKER_TAG}",
            "short": true
          }
        ],
      }
    ]
  }
EndOfSuccess
else
  EMOJI=${NEGATIVE_EMOJI[$RANDOM % ${#NEGATIVE_EMOJI[@]} ]}

  read -r -d '' PAYLOAD << EndOfFailure
  {
    "attachments": [
      {
        "text": ":no_entry: \nBuild <${BUILD_URL}|#${TRAVIS_BUILD_ID}> (<${COMPARE_URL}|${COMMIT_HASH}>) of *${TRAVIS_REPO_SLUG}@${TRAVIS_BRANCH}* \nby ${AUTHOR} failed $EMOJI \n${TRAVIS_COMMIT_MESSAGE}",
        "color": "danger",
      }
    ]
  }
EndOfFailure
fi

curl -X POST -H 'Content-type: application/json' --data "${PAYLOAD}" $SLACK_WEBHOOK_URL
