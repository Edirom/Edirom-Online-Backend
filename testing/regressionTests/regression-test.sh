#!/bin/bash -e

#REFERENCE_BASE=https://klarinettenquintett.weber-gesamtausgabe.de
REFERENCE_BASE=http://localhost:8090/exist/apps/Edirom-Online-Backend
TEST_BASE=http://localhost:8080/exist/apps/Edirom-Online-Backend

TEMP_FILES=()

cleanup_temp_files() {
  if ((${#TEMP_FILES[@]})); then
    rm -f "${TEMP_FILES[@]}"
  fi
}

# make sure to always remove temp files
# even if script exits due to an error
trap cleanup_temp_files EXIT

SED_OPTION=
if [[ "$OSTYPE" == "darwin"* ]]; then
  SED_OPTION=(-E -i '')
else
  SED_OPTION=(-E -i);
fi

# the list of endpoints is based on https://edirom.github.io/Edirom-Online-API/
# with some manual additions
# Please feel free to add more here!
declare -a ENDPOINTS=(
"/data/xql/getAnnotation.xql?edition=xmldb%3Aexist%3A%2F%2F%2Fdb%2Fapps%2Fweber-klarinettenquintett-eol-emeritus%2Fedition.xml&uri=xmldb%3Aexist%3A%2F%2F%2Fdb%2Fapps%2Fweber-klarinettenquintett-eol-emeritus%2Fsources%2Fsource-4-MEI.xml%23annotation-2&target=tip&lang=de"
"/data/xql/getAnnotationInfos.xql?uri=xmldb%3Aexist%3A%2F%2F%2Fdb%2Fapps%2Fweber-klarinettenquintett-eol-emeritus%2Fsources%2Fsource-1.xml&lang=de&edition=xmldb%3Aexist%3A%2F%2F%2Fdb%2Fapps%2Fweber-klarinettenquintett-eol-emeritus%2Fedition.xml"
"/data/xql/getAnnotationInfos.xql?uri=xmldb%3Aexist%3A%2F%2F%2Fdb%2Fapps%2Fweber-klarinettenquintett-eol-emeritus%2Ftexts%2Ftext-1.xml&lang=de&edition=xmldb%3Aexist%3A%2F%2F%2Fdb%2Fapps%2Fweber-klarinettenquintett-eol-emeritus%2Fedition.xml"
"/data/xql/getAnnotationPreviews.xql?uri=xmldb%3Aexist%3A%2F%2F%2Fdb%2Fapps%2Fweber-klarinettenquintett-eol-emeritus%2Fsources%2Fsource-4-MEI.xml%23annotation-8&edition=xmldb%3Aexist%3A%2F%2F%2Fdb%2Fapps%2Fweber-klarinettenquintett-eol-emeritus%2Fedition.xml&lang=de"
"/data/xql/getAnnotations.xql?edition=xmldb%3Aexist%3A%2F%2F%2Fdb%2Fapps%2Fweber-klarinettenquintett-eol-emeritus%2Fedition.xml&uri=xmldb%3Aexist%3A%2F%2F%2Fdb%2Fapps%2Fweber-klarinettenquintett-eol-emeritus%2Fsources%2Fsource-4-MEI.xml"
"/data/xql/getAnnotationMeta.xql?edition=xmldb%3Aexist%3A%2F%2F%2Fdb%2Fapps%2Fweber-klarinettenquintett-eol-emeritus%2Fedition.xml&uri=xmldb%3Aexist%3A%2F%2F%2Fdb%2Fapps%2Fweber-klarinettenquintett-eol-emeritus%2Fsources%2Fsource-4-MEI.xml%23annotation-2&lang=de"
"/data/xql/getAnnotationsOnPage.xql?uri=xmldb%3Aexist%3A%2F%2F%2Fdb%2Fapps%2Fweber-klarinettenquintett-eol-emeritus%2Fsources%2Fsource-1.xml&pageId=facsimile-2001002&edition=xmldb%3Aexist%3A%2F%2F%2Fdb%2Fapps%2Fweber-klarinettenquintett-eol-emeritus%2Fedition.xml&lang=de"
"/data/xql/getAnnotationOpenAllUris.xql?uri=xmldb%3Aexist%3A%2F%2F%2Fdb%2Fapps%2Fweber-klarinettenquintett-eol-emeritus%2Fsources%2Fsource-4-MEI.xml&annotId=annotation-9"
"/data/xql/getAnnotationPreviews.xql?edition=xmldb%3Aexist%3A%2F%2F%2Fdb%2Fapps%2Fweber-klarinettenquintett-eol-emeritus%2Fedition.xml&uri=xmldb%3Aexist%3A%2F%2F%2Fdb%2Fapps%2Fweber-klarinettenquintett-eol-emeritus%2Fsources%2Fsource-4-MEI.xml%23annotation-8&lang=de"
"/data/xql/getConcordances.xql?id=xmldb%3Aexist%3A%2F%2F%2Fdb%2Fapps%2Fweber-klarinettenquintett-eol-emeritus%2Fedition.xml&workId=edition-27830471_work-1&lang=de&edition=xmldb%3Aexist%3A%2F%2F%2Fdb%2Fapps%2Fweber-klarinettenquintett-eol-emeritus%2Fedition.xml"
"/data/xql/getEdition.xql?id=xmldb%3Aexist%3A%2F%2F%2Fdb%2Fapps%2Fweber-klarinettenquintett-eol-emeritus%2Fedition.xml&page=1&start=0&limit=25"
"/data/xql/getEditions.xql"
"/data/xql/getEditionURI.xql?uri=xmldb%3Aexist%3A%2F%2F%2Fdb%2Fapps%2Fweber-klarinettenquintett-eol-emeritus"
"/data/xql/getHelp.xql?lang=de&idPrefix=helpWindow-1187&edition=xmldb%3Aexist%3A%2F%2F%2Fdb%2Fapps%2Fweber-klarinettenquintett-eol-emeritus%2Fedition.xml"
"/data/xql/getiFrameURL.xql?uri=xmldb%3Aexist%3A%2F%2F%2Fdb%2Fapps%2Fweber-klarinettenquintett-eol-emeritus%2Ftexts%2Ftext-7.xml%3Fterm%3Dnull%26path%3Dnull%23searchTarget&edition=xmldb%3Aexist%3A%2F%2F%2Fdb%2Fapps%2Fweber-klarinettenquintett-eol-emeritus%2Fedition.xml&lang=de"
"/data/xql/getInternalIdType.xql?uri=xmldb%3Aexist%3A%2F%2F%2Fdb%2Fapps%2Fweber-klarinettenquintett-eol-emeritus%2Fsources%2Fsource-1.xml%23bar-2002&edition=xmldb%3Aexist%3A%2F%2F%2Fdb%2Fapps%2Fweber-klarinettenquintett-eol-emeritus%2Fedition.xml&lang=de"
"/data/xql/getLanguageFile.xql?lang=de&mode=json&edition=xmldb%3Aexist%3A%2F%2F%2Fdb%2Fapps%2Fweber-klarinettenquintett-eol-emeritus%2Fedition.xml"
"/data/xql/getMeasure.xql?id=xmldb%3Aexist%3A%2F%2F%2Fdb%2Fapps%2Fweber-klarinettenquintett-eol-emeritus%2Fsources%2Fsource-1.xml&measureId=bar-20016%3Ftstamp2%3D2m%2B0"
"/data/xql/getMeasurePage.xql?id=xmldb%3Aexist%3A%2F%2F%2Fdb%2Fapps%2Fweber-klarinettenquintett-eol-emeritus%2Fsources%2Fsource-1.xml&measure=bar-2001&measureCount=1&edition=xmldb%3Aexist%3A%2F%2F%2Fdb%2Fapps%2Fweber-klarinettenquintett-eol-emeritus%2Fedition.xml&lang=de"
"/data/xql/getMeasures.xql?uri=xmldb%3Aexist%3A%2F%2F%2Fdb%2Fapps%2Fweber-klarinettenquintett-eol-emeritus%2Fsources%2Fsource-1.xml&mdiv=part-1&edition=xmldb%3Aexist%3A%2F%2F%2Fdb%2Fapps%2Fweber-klarinettenquintett-eol-emeritus%2Fedition.xml&lang=de"
"/data/xql/getMeasuresOnPage.xql?uri=xmldb%3Aexist%3A%2F%2F%2Fdb%2Fapps%2Fweber-klarinettenquintett-eol-emeritus%2Fsources%2Fsource-1.xml&pageId=facsimile-2001002&edition=xmldb%3Aexist%3A%2F%2F%2Fdb%2Fapps%2Fweber-klarinettenquintett-eol-emeritus%2Fedition.xml&lang=de"
"/data/xql/getMovements.xql?uri=xmldb%3Aexist%3A%2F%2F%2Fdb%2Fapps%2Fweber-klarinettenquintett-eol-emeritus%2Fsources%2Fsource-4-MEI.xml&edition=xmldb%3Aexist%3A%2F%2F%2Fdb%2Fapps%2Fweber-klarinettenquintett-eol-emeritus%2Fedition.xml&lang=de"
"/data/xql/getMovements.xql?uri=xmldb%3Aexist%3A%2F%2F%2Fdb%2Fapps%2Fweber-klarinettenquintett-eol-emeritus%2Fsources%2Fsource-8.xml&edition=xmldb%3Aexist%3A%2F%2F%2Fdb%2Fapps%2Fweber-klarinettenquintett-eol-emeritus%2Fedition.xml&lang=de"
"/data/xql/getMovementsFirstPage.xql?uri=xmldb%3Aexist%3A%2F%2F%2Fdb%2Fapps%2Fweber-klarinettenquintett-eol-emeritus%2Fsources%2Fsource-1.xml&movementId=part-3"
"/data/xql/getMusicInMdiv.xql?uri=xmldb:exist:///db/apps/weber-klarinettenquintett-eol-emeritus/sources/source-4-MEI.xml&edition=xmldb:exist:///db/apps/weber-klarinettenquintett-eol-emeritus/edition.xml&movementId=tf280fcd0-c18e-42b4-8ec3-8166ac51f7cf"
"/data/xql/getNavigatorConfig.xql?editionId=xmldb%3Aexist%3A%2F%2F%2Fdb%2Fapps%2Fweber-klarinettenquintett-eol-emeritus%2Fedition.xml&workId=edition-27830471_work-1&lang=de&edition=xmldb%3Aexist%3A%2F%2F%2Fdb%2Fapps%2Fweber-klarinettenquintett-eol-emeritus%2Fedition.xml"
"/data/xql/getOverlays.xql?uri=xmldb%3Aexist%3A%2F%2F%2Fdb%2Fapps%2Fweber-klarinettenquintett-eol-emeritus%2Fsources%2Fsource-3.xml"
"/data/xql/getOverlayOnPage.xql?uri=xmldb%3Aexist%3A%2F%2F%2Fdb%2Fapps%2Fweber-klarinettenquintett-eol-emeritus%2Fsources%2Fsource-3.xml&pageId=facsimile-2002001&overlayId=layer-1&edition=xmldb%3Aexist%3A%2F%2F%2Fdb%2Fapps%2Fweber-klarinettenquintett-eol-emeritus%2Fedition.xml&lang=de"
"/data/xql/getPages.xql?uri=xmldb%3Aexist%3A%2F%2F%2Fdb%2Fapps%2Fweber-klarinettenquintett-eol-emeritus%2Fsources%2Fsource-1.xml&edition=xmldb%3Aexist%3A%2F%2F%2Fdb%2Fapps%2Fweber-klarinettenquintett-eol-emeritus%2Fedition.xml&lang=de"
"/data/xql/getParts.xql?uri=xmldb%3Aexist%3A%2F%2F%2Fdb%2Fapps%2Fweber-klarinettenquintett-eol-emeritus%2Fsources%2Fsource-5.xml"
"/data/xql/getPreferences.xql?mode=json&edition=xmldb%3Aexist%3A%2F%2F%2Fdb%2Fapps%2Fweber-klarinettenquintett-eol-emeritus%2Fedition.xml&lang=de"
"/data/xql/getPreferences.xql?mode=json&edition=xmldb%3Aexist%3A%2F%2F%2Fdb%2Fapps%2Fweber-klarinettenquintett-eol-emeritus%2Fedition.xml&lang=en"
"/data/xql/getText.xql?uri=xmldb%3Aexist%3A%2F%2F%2Fdb%2Fapps%2Fweber-klarinettenquintett-eol-emeritus%2Ftexts%2FsourceDesc-1.xml&idPrefix=textView-1093_&term=&path=&edition=xmldb%3Aexist%3A%2F%2F%2Fdb%2Fapps%2Fweber-klarinettenquintett-eol-emeritus%2Fedition.xml&lang=de"
"/data/xql/getText.xql?uri=xmldb%3Aexist%3A%2F%2F%2Fdb%2Fapps%2Fweber-klarinettenquintett-eol-emeritus%2Ftexts%2Ftext-1.xml&idPrefix=textView-1063_&term=&path=&edition=xmldb%3Aexist%3A%2F%2F%2Fdb%2Fapps%2Fweber-klarinettenquintett-eol-emeritus%2Fedition.xml&lang=de"
"/data/xql/getText.xql?uri=xmldb%3Aexist%3A%2F%2F%2Fdb%2Fapps%2Fweber-klarinettenquintett-eol-emeritus%2Ftexts%2Ftext-5.xml&idPrefix=textView-1254_&term=&path=&edition=xmldb%3Aexist%3A%2F%2F%2Fdb%2Fapps%2Fweber-klarinettenquintett-eol-emeritus%2Fedition.xml&lang=de"
"/data/xql/getWorkID.xql?uri=xmldb%3Aexist%3A%2F%2F%2Fdb%2Fapps%2Fweber-klarinettenquintett-eol-emeritus%2Fedition.xml&workId=edirom_work_291f7ad8-9bb8-45eb-9186-801dec2f80d9"
"/data/xql/getWorks.xql?editionId=xmldb%3Aexist%3A%2F%2F%2Fdb%2Fapps%2Fweber-klarinettenquintett-eol-emeritus%2Fedition.xml&lang=de&page=1&start=0&limit=25"
"/data/xql/getXml.xql?uri=xmldb%3Aexist%3A%2F%2F%2Fdb%2Fapps%2Fweber-klarinettenquintett-eol-emeritus%2Fsources%2Fsource-1.xml&internalId=&edition=xmldb%3Aexist%3A%2F%2F%2Fdb%2Fapps%2Fweber-klarinettenquintett-eol-emeritus%2Fedition.xml&lang=de"
"/data/xql/getZone.xql?uri=xmldb%3Aexist%3A%2F%2F%2Fdb%2Fapps%2Fweber-klarinettenquintett-eol-emeritus%2Fsources%2Fsource-8.xml&zoneId=zone_4d395284-88a3-4269-adc8-8ecabc1d434d"
"/data/xql/search.xql?term=hilfe&lang=de&edition=xmldb%3Aexist%3A%2F%2F%2Fdb%2Fapps%2Fweber-klarinettenquintett-eol-emeritus%2Fedition.xml"
)

# Helper function to compute filenames from endpoint via `md5`.
# The filename will be given as absolute path to the `expected-results` directory,
# which should be located in the same directory as this script.
compute_filename_from_endpoint() {
  local endpoint="$1"
  local filename
  filename=$(echo "$endpoint" | md5sum)
  echo "$(pwd)"/expected-results/"$filename"
}

# Helper function to normalize file content by removing host and port information to avoid false positives in the diff.
normalize_file() {
  local file="$1"
  # replace host and port number with xxxx to avoid false positives
  sed "${SED_OPTION[@]}" 's/localhost:[0-9]+/xxxx/g' "$file"
}

# Main function to check the endpoints against the expected results.
# This assumes your container is available at `$TEST_BASE`.
check() {
  for i in "${ENDPOINTS[@]}"
  do
      REF_FILE=$(compute_filename_from_endpoint "$i")
      TEST_FILE=$(mktemp)
      # create array of temp files for later removal by `cleanup_temp_files`
      TEMP_FILES=("$TEST_FILE")
      echo "testing $i"
      curl -LsS --fail "$TEST_BASE$i" -o "$TEST_FILE"
      # replace host and port number with xxxx to avoid false positives
      normalize_file "$TEST_FILE"
      diff "$REF_FILE" "$TEST_FILE"
      cleanup_temp_files
      TEMP_FILES=()
  done
}

# Helper function to update the expected results in the `expected-results` directory
# by downloading the current responses from the development backend.
# This assumes your container is available at `$REFERENCE_BASE`.
reset() {
  for i in "${ENDPOINTS[@]}"
  do
      FILE_NAME=$(compute_filename_from_endpoint "$i")
      echo "downloading $FILE_NAME"
      curl -LsS --fail "$REFERENCE_BASE$i" -o "$FILE_NAME"
      # replace host and port number with xxxx to avoid false positives
      normalize_file "$FILE_NAME"
  done
}

show_help() {
  cat << EOF
Usage: $(basename "$0") [COMMAND]

Commands:
  check       Run regression tests and compare results (development backend should be running on port 8090 and your test backend on port 8080)
  reset       Download and reset expected results (development backend should be running on port 8090)
  help        Show this help message

Examples:
  ./regression-test.sh check
  ./regression-test.sh reset
  ./regression-test.sh help
EOF
}

main() {
  case "${1:-}" in
    check)
      check
      ;;
    reset)
      reset
      ;;
    help|--help|-h|"")
      show_help
      ;;
    *)
      echo "Error: Unknown command '$1'"
      echo ""
      show_help
      exit 1
      ;;
  esac
}

main "$@"
