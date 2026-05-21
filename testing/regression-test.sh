#!/bin/bash -e

#REFERENCE_BASE=https://klarinettenquintett.weber-gesamtausgabe.de
REFERENCE_BASE=http://localhost:8090/exist/apps/Edirom-Online-Backend
TEST_BASE=http://localhost:8080/exist/apps/Edirom-Online-Backend

declare -a ENDPOINTS=(
"/data/xql/getAnnotationInfos.xql?_dc=1777988007718&uri=xmldb%3Aexist%3A%2F%2F%2Fdb%2Fapps%2Fweber-klarinettenquintett-eol-emeritus%2Fsources%2Fsource-1.xml&lang=de&edition=xmldb%3Aexist%3A%2F%2F%2Fdb%2Fapps%2Fweber-klarinettenquintett-eol-emeritus%2Fedition.xml"
"/data/xql/getAnnotationInfos.xql?_dc=1777986769347&uri=xmldb%3Aexist%3A%2F%2F%2Fdb%2Fapps%2Fweber-klarinettenquintett-eol-emeritus%2Ftexts%2Ftext-1.xml&lang=de&edition=xmldb%3Aexist%3A%2F%2F%2Fdb%2Fapps%2Fweber-klarinettenquintett-eol-emeritus%2Fedition.xml"
"/data/xql/getAnnotationsOnPage.xql?_dc=1777988049541&uri=xmldb%3Aexist%3A%2F%2F%2Fdb%2Fapps%2Fweber-klarinettenquintett-eol-emeritus%2Fsources%2Fsource-1.xml&pageId=facsimile-2001002&edition=xmldb%3Aexist%3A%2F%2F%2Fdb%2Fapps%2Fweber-klarinettenquintett-eol-emeritus%2Fedition.xml&lang=de"
"/data/xql/getConcordances.xql?_dc=1779270755357&id=xmldb%3Aexist%3A%2F%2F%2Fdb%2Fapps%2Fweber-klarinettenquintett-eol-emeritus%2Fedition.xml&workId=edition-27830471_work-1&lang=de&edition=xmldb%3Aexist%3A%2F%2F%2Fdb%2Fapps%2Fweber-klarinettenquintett-eol-emeritus%2Fedition.xml"
"/data/xql/getEdition.xql?_dc=1777986768657&id=xmldb%3Aexist%3A%2F%2F%2Fdb%2Fapps%2Fweber-klarinettenquintett-eol-emeritus%2Fedition.xml&page=1&start=0&limit=25"
"/data/xql/getHelp.xql?_dc=1779273169250&lang=de&idPrefix=helpWindow-1187&edition=xmldb%3Aexist%3A%2F%2F%2Fdb%2Fapps%2Fweber-klarinettenquintett-eol-emeritus%2Fedition.xml"
"/data/xql/getiFrameURL.xql?_dc=1779273324221&uri=xmldb%3Aexist%3A%2F%2F%2Fdb%2Fapps%2Fweber-klarinettenquintett-eol-emeritus%2Ftexts%2Ftext-7.xml%3Fterm%3Dnull%26path%3Dnull%23searchTarget&edition=xmldb%3Aexist%3A%2F%2F%2Fdb%2Fapps%2Fweber-klarinettenquintett-eol-emeritus%2Fedition.xml&lang=de"
"/data/xql/getInternalIdType.xql?_dc=1779270763809&uri=xmldb%3Aexist%3A%2F%2F%2Fdb%2Fapps%2Fweber-klarinettenquintett-eol-emeritus%2Fsources%2Fsource-1.xml%23bar-2002&edition=xmldb%3Aexist%3A%2F%2F%2Fdb%2Fapps%2Fweber-klarinettenquintett-eol-emeritus%2Fedition.xml&lang=de"
"/data/xql/getLanguageFile.xql?_dc=1777986768641&lang=de&mode=json&edition=xmldb%3Aexist%3A%2F%2F%2Fdb%2Fapps%2Fweber-klarinettenquintett-eol-emeritus%2Fedition.xml"
"/data/xql/getMeasurePage.xql?_dc=1779270763858&id=xmldb%3Aexist%3A%2F%2F%2Fdb%2Fapps%2Fweber-klarinettenquintett-eol-emeritus%2Fsources%2Fsource-1.xml&measure=bar-2001&measureCount=1&edition=xmldb%3Aexist%3A%2F%2F%2Fdb%2Fapps%2Fweber-klarinettenquintett-eol-emeritus%2Fedition.xml&lang=de"
"/data/xql/getMeasures.xql?_dc=1779270763829&uri=xmldb%3Aexist%3A%2F%2F%2Fdb%2Fapps%2Fweber-klarinettenquintett-eol-emeritus%2Fsources%2Fsource-1.xml&mdiv=part-1&edition=xmldb%3Aexist%3A%2F%2F%2Fdb%2Fapps%2Fweber-klarinettenquintett-eol-emeritus%2Fedition.xml&lang=de"
"/data/xql/getMeasuresOnPage.xql?_dc=1779270763881&uri=xmldb%3Aexist%3A%2F%2F%2Fdb%2Fapps%2Fweber-klarinettenquintett-eol-emeritus%2Fsources%2Fsource-1.xml&pageId=facsimile-2001002&edition=xmldb%3Aexist%3A%2F%2F%2Fdb%2Fapps%2Fweber-klarinettenquintett-eol-emeritus%2Fedition.xml&lang=de"
"/data/xql/getMovements.xql?_dc=1777987923059&uri=xmldb%3Aexist%3A%2F%2F%2Fdb%2Fapps%2Fweber-klarinettenquintett-eol-emeritus%2Fsources%2Fsource-4-MEI.xml&edition=xmldb%3Aexist%3A%2F%2F%2Fdb%2Fapps%2Fweber-klarinettenquintett-eol-emeritus%2Fedition.xml&lang=de"
"/data/xql/getMovements.xql?_dc=1777987885724&uri=xmldb%3Aexist%3A%2F%2F%2Fdb%2Fapps%2Fweber-klarinettenquintett-eol-emeritus%2Fsources%2Fsource-8.xml&edition=xmldb%3Aexist%3A%2F%2F%2Fdb%2Fapps%2Fweber-klarinettenquintett-eol-emeritus%2Fedition.xml&lang=de"
"/data/xql/getMusicInMdiv.xql?uri=xmldb:exist:///db/apps/weber-klarinettenquintett-eol-emeritus/sources/source-4-MEI.xml&edition=xmldb:exist:///db/apps/weber-klarinettenquintett-eol-emeritus/edition.xml&movementId=tf280fcd0-c18e-42b4-8ec3-8166ac51f7cf"
"/data/xql/getNavigatorConfig.xql?_dc=1777986768685&editionId=xmldb%3Aexist%3A%2F%2F%2Fdb%2Fapps%2Fweber-klarinettenquintett-eol-emeritus%2Fedition.xml&workId=edition-27830471_work-1&lang=de&edition=xmldb%3Aexist%3A%2F%2F%2Fdb%2Fapps%2Fweber-klarinettenquintett-eol-emeritus%2Fedition.xml"
"/data/xql/getOverlayOnPage.xql?_dc=1779273378656&uri=xmldb%3Aexist%3A%2F%2F%2Fdb%2Fapps%2Fweber-klarinettenquintett-eol-emeritus%2Fsources%2Fsource-3.xml&pageId=facsimile-2002001&overlayId=layer-1&edition=xmldb%3Aexist%3A%2F%2F%2Fdb%2Fapps%2Fweber-klarinettenquintett-eol-emeritus%2Fedition.xml&lang=de"
"/data/xql/getPages.xql?_dc=1777986349264&uri=xmldb%3Aexist%3A%2F%2F%2Fdb%2Fapps%2Fweber-klarinettenquintett-eol-emeritus%2Fsources%2Fsource-1.xml&edition=xmldb%3Aexist%3A%2F%2F%2Fdb%2Fapps%2Fweber-klarinettenquintett-eol-emeritus%2Fedition.xml&lang=de"
"/data/xql/getPreferences.xql?_dc=1777986768638&mode=json&edition=xmldb%3Aexist%3A%2F%2F%2Fdb%2Fapps%2Fweber-klarinettenquintett-eol-emeritus%2Fedition.xml&lang=de"
"/data/xql/getPreferences.xql?_dc=1777986768638&mode=json&edition=xmldb%3Aexist%3A%2F%2F%2Fdb%2Fapps%2Fweber-klarinettenquintett-eol-emeritus%2Fedition.xml&lang=en"
"/data/xql/getText.xql?_dc=1779273262622&uri=xmldb%3Aexist%3A%2F%2F%2Fdb%2Fapps%2Fweber-klarinettenquintett-eol-emeritus%2Ftexts%2FsourceDesc-1.xml&idPrefix=textView-1093_&term=&path=&edition=xmldb%3Aexist%3A%2F%2F%2Fdb%2Fapps%2Fweber-klarinettenquintett-eol-emeritus%2Fedition.xml&lang=de"
"/data/xql/getText.xql?_dc=1777986769008&uri=xmldb%3Aexist%3A%2F%2F%2Fdb%2Fapps%2Fweber-klarinettenquintett-eol-emeritus%2Ftexts%2Ftext-1.xml&idPrefix=textView-1063_&term=&path=&edition=xmldb%3Aexist%3A%2F%2F%2Fdb%2Fapps%2Fweber-klarinettenquintett-eol-emeritus%2Fedition.xml&lang=de"
"/data/xql/getText.xql?_dc=1777986672408&uri=xmldb%3Aexist%3A%2F%2F%2Fdb%2Fapps%2Fweber-klarinettenquintett-eol-emeritus%2Ftexts%2Ftext-5.xml&idPrefix=textView-1254_&term=&path=&edition=xmldb%3Aexist%3A%2F%2F%2Fdb%2Fapps%2Fweber-klarinettenquintett-eol-emeritus%2Fedition.xml&lang=de"
"/data/xql/getWorks.xql?_dc=1777986768658&editionId=xmldb%3Aexist%3A%2F%2F%2Fdb%2Fapps%2Fweber-klarinettenquintett-eol-emeritus%2Fedition.xml&lang=de&page=1&start=0&limit=25"
"/data/xql/getXml.xql?_dc=1779273223101&uri=xmldb%3Aexist%3A%2F%2F%2Fdb%2Fapps%2Fweber-klarinettenquintett-eol-emeritus%2Fsources%2Fsource-1.xml&internalId=&edition=xmldb%3Aexist%3A%2F%2F%2Fdb%2Fapps%2Fweber-klarinettenquintett-eol-emeritus%2Fedition.xml&lang=de"
"/data/xql/search.xql?_dc=1779273768232&term=hilfe&lang=de&edition=xmldb%3Aexist%3A%2F%2F%2Fdb%2Fapps%2Fweber-klarinettenquintett-eol-emeritus%2Fedition.xml"
)

for i in "${ENDPOINTS[@]}"
do
    REF_FILE=$(mktemp)
    TEST_FILE=$(mktemp)
    echo "testing $i"
    curl -Ls "$REFERENCE_BASE$i" -o "$REF_FILE"
    # replace host and port number with xxxx to avoid false positives
    sed -i '' 's/localhost:8090/xxxx/g' "$REF_FILE"
    curl -Ls "$TEST_BASE$i" -o "$TEST_FILE"
    # replace host and port number with xxxx to avoid false positives
    sed -i '' 's/localhost:8080/xxxx/g' "$TEST_FILE"
    diff "$REF_FILE" "$TEST_FILE"
    rm "$REF_FILE" "$TEST_FILE"
done
