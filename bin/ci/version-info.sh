# Get latest version
PREVIOUS_VERSION=$(git describe HEAD^1 --abbrev=0 --tags)

# Get release notes
if [[ $PREVIOUS_VERSION == "" ]]; then
  GIT_HISTORY=$(git log --no-merges --format="- %s (%an)")
else
  GIT_HISTORY=$(git log --no-merges --format="- %s (%an)" $PREVIOUS_VERSION..HEAD)
fi;

# Count tag occurrences
MAJOR_CHANGES=$(grep -o '\[major\]' <<< "${GIT_HISTORY}" | wc -l)
FEATURE_CHANGES=$(grep -o '\[feature\]' <<< "${GIT_HISTORY}" | wc -l)
MINOR_CHANGES=$(grep -o '\[minor\]' <<< "${GIT_HISTORY}" | wc -l)

# Convert values to numbers (trims leading spaces)
MAJOR_CHANGES=$(expr $MAJOR_CHANGES + 0)
FEATURE_CHANGES=$(expr $FEATURE_CHANGES + 0)
MINOR_CHANGES=$(expr $MINOR_CHANGES + 0)

# Generate next version.
parts=( ${PREVIOUS_VERSION//./ } )
NEXT_MAJOR_VERSION=$(expr ${parts[0]} + ${MAJOR_CHANGES})

if [[ ${MAJOR_CHANGES} != "0" ]]; then
  NEXT_FEATURE_VERSION="0"
else
  NEXT_FEATURE_VERSION=$(expr ${parts[1]} + ${FEATURE_CHANGES})
fi;

if [[ ${MAJOR_CHANGES} != "0" || ${FEATURE_CHANGES} != "0" ]]; then
  NEXT_MINOR_VERSION="0"
else
  NEXT_MINOR_VERSION=$(expr ${parts[2]} + ${MINOR_CHANGES})
fi;

NEXT_VERSION="${NEXT_MAJOR_VERSION}.${NEXT_FEATURE_VERSION}.${NEXT_MINOR_VERSION}"

# Show version info
echo
echo "Version information: "
echo " - Previous version was ${PREVIOUS_VERSION}"
echo " - There was ${MAJOR_CHANGES} major, ${FEATURE_CHANGES} feature and ${MINOR_CHANGES} changes since then"
echo " - Next version will be ${NEXT_VERSION}"

if [[ "${MAJOR_CHANGES}" == "0" && "${FEATURE_CHANGES}" == "0" && "${MINOR_CHANGES}" == "0" ]]; then
  echo
  echo "[ERROR] No version changes was detected."
  exit 1
fi;

# Do not allow to build new versions in master when release is in maintenance mode
MAINTENANCE_BRANCH="v${parts[0]}.${parts[1]}"
BUILD_REQUIRES_MAINTENANCE=$(git branch --list | grep "${MAINTENANCE_BRANCH}" | wc -l)
BUILD_REQUIRES_MAINTENANCE=$(expr $BUILD_REQUIRES_MAINTENANCE + 0)

if [[ "${BUILD_REQUIRES_MAINTENANCE}" == "1" ]]; then
  echo " - This build changes version that is in maintenance mode"

  if [[ "${MAJOR_CHANGES}" != "0" || "${FEATURE_CHANGES}" != "0" ]]; then
    echo
    echo "[ERROR] You can not add features or breaking changes to the version that is in maintenance mode."
    exit 1
  fi;
fi;

export GIT_HISTORY=$GIT_HISTORY
export PREVIOUS_VERSION=$PREVIOUS_VERSION
export NEXT_VERSION=$NEXT_VERSION
export BUILD_REQUIRES_MAINTENANCE=$BUILD_REQUIRES_MAINTENANCE
export MAINTENANCE_BRANCH=$MAINTENANCE_BRANCH
