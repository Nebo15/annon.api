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

