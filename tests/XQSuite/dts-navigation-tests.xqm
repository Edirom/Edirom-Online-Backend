xquery version "3.1";

module namespace dnt = "http://www.edirom.de/xquery/xqsuite/dts-navigation-tests";

import module namespace dts-navigation = "http://www.edirom.de/api/dts-navigation" at "xmldb:exist:///db/apps/Edirom-Online-Backend/data/xqm/dts-navigation.xqm";

declare namespace errors = "http://www.edirom.de/xquery/errors";
declare namespace json = "http://www.json.org";
declare namespace test = "http://exist-db.org/xquery/xqsuite";


declare
    %test:assertEquals("musicStructure", "paginationStructure")
    function dnt:test-getCitationTrees-returns-standard-mei-trees() as xs:string* {
        let $document := document {
            <mei xmlns="http://www.music-encoding.org/ns/mei">
                <music>
                    <facsimile>
                        <surface/>
                    </facsimile>
                    <body>
                        <mdiv/>
                    </body>
                </music>
            </mei>
        }
        return dts-navigation:getCitationTrees($document)/string(@xml:id)
};

declare
    %test:assertEquals("musicStructure", "paginationStructure")
    function dnt:test-getCitationTrees-returns-all-mei-trees-with-partial-content() as xs:string* {
        let $document := document {
            <mei xmlns="http://www.music-encoding.org/ns/mei">
                <music>
                    <body>
                        <mdiv/>
                    </body>
                </music>
            </mei>
        }
        return dts-navigation:getCitationTrees($document)/string(@xml:id)
};

declare
    %test:assertEquals("basicStructure", "paginationStructure")
    function dnt:test-getCitationTrees-returns-standard-tei-trees() as xs:string* {
        let $document := document {
            <TEI xmlns="http://www.tei-c.org/ns/1.0">
                <text>
                    <body>
                        <div/>
                        <pb/>
                    </body>
                </text>
            </TEI>
        }
        return dts-navigation:getCitationTrees($document)/string(@xml:id)
};

declare
    %test:assertEquals("musicStructure", "paginationStructure")
    function dnt:test-getCitationTrees-returns-all-mei-trees-without-matching-content() as xs:string* {
        let $document := document {
            <mei xmlns="http://www.music-encoding.org/ns/mei">
                <meiHead/>
            </mei>
        }
        return dts-navigation:getCitationTrees($document)/string(@xml:id)
};

declare
    %test:assertTrue
    function dnt:test-buildCitationTreesObjects-converts-nested-structures() as xs:boolean {
        let $citationTrees :=
            <citeStructure xml:id="journalStructure" unit="Chapter">
                <citeStructure unit="Journal Entry">
                    <citeStructure unit="Paragraph"/>
                </citeStructure>
            </citeStructure>
        let $result := dts-navigation:buildCitationTreesObjects($citationTrees)
        let $citationTree := $result[1]
        let $chapter := $citationTree/citeStructure[1]
        let $journalEntry := $chapter/citeStructure[1]
        let $paragraph := $journalEntry/citeStructure[1]
        return
            count($result) eq 1
            and $citationTree/type[@json:name = "@type"] eq "CitationTree"
            and $citationTree/identifier eq "journalStructure"
            and $chapter/type[@json:name = "@type"] eq "CiteStructure"
            and $chapter/citeType eq "Chapter"
            and $journalEntry/citeType eq "Journal Entry"
            and $paragraph/citeType eq "Paragraph"
            and empty($paragraph/citeStructure)
};

declare
    %test:assertEquals("Movement", "Surface")
    function dnt:test-buildCitationTreesObjects-preserves-multiple-trees() as xs:string* {
        let $citationTrees := (
            <citeStructure unit="Movement"/>,
            <citeStructure unit="Surface"/>
        )
        let $result := dts-navigation:buildCitationTreesObjects($citationTrees)
        for $citationTree in $result
        return $citationTree/citeStructure[1]/citeType/string()
};

declare
    %test:assertFalse
    function dnt:test-buildCitationTreesObjects-omits-missing-identifier() as xs:boolean {
        let $result := dts-navigation:buildCitationTreesObjects(
            <citeStructure unit="Movement"/>
        )
        return exists($result[1]/identifier)
};

declare
    %test:assertTrue
    function dnt:test-buildResourceObject-builds-dts-links() as xs:boolean {
        let $resource := "xmldb:exist:///db/apps/Edirom-Online-Backend/tests/XQSuite/data/mei-score.xml"
        let $document := doc($resource)
        let $result := dts-navigation:buildResourceObject($document, $resource)
        return
            $result/id[@json:name = "@id"] eq $resource
            and $result/type[@json:name = "@type"] eq "Resource"
            and contains($result/collection, "/api/collection/?id=" || $resource)
            and contains($result/navigation, "/api/navigation/?resource=" || $resource)
            and contains($result/document, "/api/document/?resource=" || $resource)
            and $result/citationTrees[1]/type[@json:name = "@type"] eq "CitationTree"
            and $result/citationTrees[1]/citeStructure[1]/citeType eq "Movement"
};

declare
    (: Valid request using down. :)
    %test:arg("resource", "xmldb:exist:///db/apps/Edirom-Online-Backend/tests/XQSuite/data/mei-score.xml")
    %test:arg("ref") %test:arg("start") %test:arg("end")
    %test:arg("down", "1")
    %test:arg("tree", "musicStructure")
    %test:arg("page")
    %test:assertTrue
    (: Valid request using ref and down=0. :)
    %test:arg("resource", "xmldb:exist:///db/apps/Edirom-Online-Backend/tests/XQSuite/data/mei-score.xml")
    %test:arg("ref", "test-mdiv-1") %test:arg("start") %test:arg("end")
    %test:arg("down", "0")
    %test:arg("tree", "musicStructure")
    %test:arg("page")
    %test:assertTrue
    function dnt:test-navigation-returns-navigation-object(
        $resource as xs:string,
        $ref as xs:string?,
        $start as xs:string?,
        $end as xs:string?,
        $down as xs:integer?,
        $tree as xs:string?,
        $page as xs:integer?
    ) as xs:boolean {
        let $result := dts-navigation:navigation($resource, $ref, $start, $end, $down, $tree, $page)
        return
            $result/context[@json:name = "@context"] eq "https://dtsapi.org/context/v1.0.json"
            and $result/dtsVersion eq "1.0"
            and $result/type[@json:name = "@type"] eq "Navigation"
            and $result/resource/id[@json:name = "@id"] eq $resource
            and $result/resource/type[@json:name = "@type"] eq "Resource"
};

declare
    (: Ref cannot be combined with start/end. :)
    %test:arg("resource", "xmldb:exist:///db/apps/Edirom-Online-Backend/tests/XQSuite/data/mei-score.xml")
    %test:arg("ref", "test-mdiv-1")
    %test:arg("start", "test-mdiv-1")
    %test:arg("end", "test-mdiv-2")
    %test:arg("down") %test:arg("tree") %test:arg("page")
    %test:assertError("errors:InvalidParametersError")
    (: Start requires end. :)
    %test:arg("resource", "xmldb:exist:///db/apps/Edirom-Online-Backend/tests/XQSuite/data/mei-score.xml")
    %test:arg("ref")
    %test:arg("start", "test-mdiv-1")
    %test:arg("end")
    %test:arg("down") %test:arg("tree") %test:arg("page")
    %test:assertError("errors:InvalidParametersError")
    (: End requires start. :)
    %test:arg("resource", "xmldb:exist:///db/apps/Edirom-Online-Backend/tests/XQSuite/data/mei-score.xml")
    %test:arg("ref") %test:arg("start")
    %test:arg("end", "test-mdiv-2")
    %test:arg("down") %test:arg("tree") %test:arg("page")
    %test:assertError("errors:InvalidParametersError")
    (: At least one navigation selector is required. :)
    %test:arg("resource", "xmldb:exist:///db/apps/Edirom-Online-Backend/tests/XQSuite/data/mei-score.xml")
    %test:arg("ref") %test:arg("start") %test:arg("end")
    %test:arg("down") %test:arg("tree") %test:arg("page")
    %test:assertError("errors:InvalidParametersError")
    (: Down=0 requires ref. :)
    %test:arg("resource", "xmldb:exist:///db/apps/Edirom-Online-Backend/tests/XQSuite/data/mei-score.xml")
    %test:arg("ref") %test:arg("start") %test:arg("end")
    %test:arg("down", "0")
    %test:arg("tree") %test:arg("page")
    %test:assertError("errors:InvalidParametersError")
    function dnt:test-navigation-validates-parameters(
        $resource as xs:string,
        $ref as xs:string?,
        $start as xs:string?,
        $end as xs:string?,
        $down as xs:integer?,
        $tree as xs:string?,
        $page as xs:integer?
    ) as element(json:value) {
        dts-navigation:navigation($resource, $ref, $start, $end, $down, $tree, $page)
};

declare
    %test:assertError("errors:NotFoundError")
    function dnt:test-navigation-errors-for-missing-resource() as element(json:value) {
        dts-navigation:navigation(
            "xmldb:exist:///db/apps/Edirom-Online-Backend/tests/XQSuite/data/missing.xml",
            "ref",
            "",
            "",
            (),
            "",
            ()
        )
};
