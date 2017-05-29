# Build changelog
GIT_HISTORY_CLEANED=$(echo "${GIT_HISTORY}" | grep -v 'ci skip' | grep -v 'changelog skip')
MAJOR_CHANGES=$(echo "${GIT_HISTORY_CLEANED}" | grep '\[major\]')
FEATURE_CHANGES=$(echo "${GIT_HISTORY_CLEANED}" | grep '\[feature\]')
MINOR_CHANGES=$(echo "${GIT_HISTORY_CLEANED}" | grep '\[minor\]')

OTHER_CHANGES=$(grep -vo '\[major\]' <<< "${GIT_HISTORY_CLEANED}" | grep -vo '\[feature\]' | grep -vo '\[minor\]' | wc -l)
OTHER_CHANGES=$(expr $OTHER_CHANGES + 0)

CHANGELOG=""
if [[ "${MAJOR_CHANGES}" != "" ]]; then
  CHANGELOG="${CHANGELOG}**Major changes**: \n${MAJOR_CHANGES}\n"
fi;

if [[ "${FEATURE_CHANGES}" != "" ]]; then
  CHANGELOG="${CHANGELOG}**Features**: \n${FEATURE_CHANGES}\n"
fi;

if [[ "${MINOR_CHANGES}" != "0" ]]; then
  CHANGELOG="${CHANGELOG}**Minor improvements and bug fixes**: \n${MINOR_CHANGES}\n"
fi;

if [[ "${OTHER_CHANGES}" != "0" ]]; then
  CHANGELOG="${CHANGELOG}\n **${OTHER_CHANGES} other** changes."
fi;

if [[ "${CHANGELOG}" == "" ]]; then
  CHANGELOG="${GIT_HISTORY_CLEANED}"
fi;

CHANGELOG="${CHANGELOG/\[major\]/}"
CHANGELOG="${CHANGELOG/\[feature\]/}"
CHANGELOG="${CHANGELOG/\[minor\]/}"

echo
echo "Changelog: "
echo -e "${CHANGELOG}"

export CHANGELOG=$CHANGELOG
