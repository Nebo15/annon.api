# Build changelog
GIT_HISTORY_CLEANED=$(echo "${GIT_HISTORY}" | grep -v 'ci skip' | grep -v 'changelog skip')
MAJOR_CHANGES=$(echo "${GIT_HISTORY_CLEANED}" | grep '\[major\]')
FEATURE_CHANGES=$(echo "${GIT_HISTORY_CLEANED}" | grep '\[feature\]')

OTHER_CHANGES=$(grep -vo '\[major\]' <<< "${GIT_HISTORY_CLEANED}" | grep -vo '\[feature\]' | wc -l)
OTHER_CHANGES=$(expr $MINOR_CHANGES + $OTHER_CHANGES)

CHANGELOG=""
if [[ "${MAJOR_CHANGES}" != "" ]]; then
  CHANGELOG="${CHANGELOG}**Major changes**: \n${MAJOR_CHANGES}\n"
fi;

if [[ "${FEATURE_CHANGES}" != "" ]]; then
  CHANGELOG="${CHANGELOG}**Features**: \n${FEATURE_CHANGES}\n"
fi;

if [[ "${OTHER_CHANGES}" != "0" && "${CHANGELOG}" != "" ]]; then
  CHANGELOG="${CHANGELOG}\n **${OTHER_CHANGES} other** changes."
elif [[ "${CHANGELOG}" == "" ]]; then
  CHANGELOG="${GIT_HISTORY_CLEANED}"
fi;

echo
echo "Changelog: "
echo -e "${CHANGELOG}"
