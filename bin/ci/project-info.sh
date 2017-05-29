export PROJECT_DIR=${TRAVIS_BUILD_DIR}
export PROJECT_NAME=$(sed -n 's/.*app: :\([^, ]*\).*/\1/pg' "${PROJECT_DIR}/mix.exs")
export PROJECT_VERSION=$(sed -n 's/.*@version "\([^"]*\)".*/\1/pg' "${PROJECT_DIR}/mix.exs")
