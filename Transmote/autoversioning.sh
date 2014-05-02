#!/bin/sh

# This rather shady little script picks up tags from git and sets long and short version numbers at compile time
# ... it could be a lot better

# Create (and push) ANNOTATED tags in git prefixed with "v" (eg "v0.1") to define the major version number for commits going forward

# in DEVELOPMENT builds
# -- the short version number is in the form 0.1.xx-dirty (where xx is the number of commits since the tag) -dirty indicates if there are unstaged commits
# -- the long version number is the current git hash

# in RELEASE builds
# -- the short (marketing) version number is in the form 0.1
# -- the long version number is in the form 0.1.xx (as above without the dirty)




cd "$PROJECT_DIR"

described=`git describe --tags --dirty`
described=`echo $described | sed 's/v//'`
taggedVersion=`echo $described | awk '{split($0,a,"-"); print a[1]}'`
gitHash=`echo $described | awk '{split($0,a,"-"); print a[3]}'`
bumps=`echo $described | awk '{split($0,a,"-"); print a[2]}'`
dirty=`echo $described | awk '{split($0,a,"-"); print a[4]}'`

if [[ -z "$taggedVersion" ]]; then
echo "No version number from git"
exit 0
fi


if [[ "$CONFIGURATION" == "Debug" ]]; then
  shortVersion="$taggedVersion.$bumps"
  if [[ -n "$dirty" ]]; then
    shortVersion="$shortVersion-$dirty"
  fi
  longVersion="$gitHash"
else
  shortVersion="$shortVersion"
  longVersion="$taggedVersion.$bumps"
fi

echo "VERSIONING*** Long $longVersion"
echo "VERSIONING*** Short $shortVersion"

cd "$PROJECT_TEMP_DIR"

echo "#define GIT_HASH $gitHash" > revision.prefix
echo "#define BUMPS $bumps" >> revision.prefix
echo "#define LONG_VERSION $longVersion" >> revision.prefix
echo "#define SHORT_VERSION $shortVersion" >> revision.prefix


cd "$PROJECT_DIR/$PROJECT_NAME"
touch "$PROJECT_NAME-Info.plist"

exit 0