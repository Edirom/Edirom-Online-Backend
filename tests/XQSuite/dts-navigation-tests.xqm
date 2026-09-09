xquery version "3.1";

module namespace dnt = "http://www.edirom.de/xquery/xqsuite/dts-navigation-tests";

import module namespace dts-navigation = "http://www.edirom.de/api/dts-navigation" at "xmldb:exist:///db/apps/Edirom-Online-Backend/data/xqm/dts-navigation.xqm";
import module namespace dts-common = "http://www.edirom.de/api/dts-common" at "xmldb:exist:///db/apps/Edirom-Online-Backend/data/xqm/dts-common.xqm";
import module namespace eutil = "http://www.edirom.de/xquery/eutil" at "xmldb:exist:///db/apps/Edirom-Online-Backend/data/xqm/eutil.xqm";

declare namespace errors = "http://www.edirom.de/xquery/errors";
declare namespace json = "http://www.json.org";
declare namespace test = "http://exist-db.org/xquery/xqsuite";

declare function dnt:memberDocument() as document-node() {
    document {
        <mei xmlns="http://www.music-encoding.org/ns/mei">
            <facsimile><surface xml:id="surface-1"><zone xml:id="zone-1"/></surface></facsimile>
            <music><body>
                <mdiv xml:id="movement-1">
                    <score>
                        <section><measure xml:id="measure-1"><staff><layer><note xml:id="note-1"/></layer></staff></measure></section>
                        <section><measure xml:id="measure-2"/></section>
                    </score>
                    <mdiv xml:id="nested-movement">
                        <score><section><measure xml:id="nested-measure"/></section></score>
                    </mdiv>
                </mdiv>
                <mdiv xml:id="movement-2"><score><section><measure xml:id="measure-3"/></section></score></mdiv>
            </body></music>
        </mei>
    }
};

declare function dnt:memberCitationTrees() as element(citeStructure)* {
    <refsDecl xmlns:mei="http://www.music-encoding.org/ns/mei">
        <citeStructure match="mei:mdiv" use="@xml:id" unit="Movement">
            <citeStructure match="mei:measure" use="@xml:id" unit="Measure">
                <citeStructure match="mei:note" use="@xml:id" unit="Note"/>
            </citeStructure>
        </citeStructure>
        <citeStructure match="mei:surface" use="@xml:id" unit="Surface">
            <citeStructure match="mei:zone" use="@xml:id" unit="Zone"/>
        </citeStructure>
    </refsDecl>/citeStructure
};

declare
    %test:args(1, "movement-1")
    %test:assertEquals("movement-1")
    %test:args(2, "movement-1")
    %test:assertEquals("movement-1 measure-1 measure-2")
    %test:args(3, "movement-1")
    %test:assertEquals("movement-1 measure-1 note-1 measure-2")
    %test:args("-1", "movement-1")
    %test:assertEquals("movement-1 measure-1 note-1 measure-2")
    %test:args(10, "movement-1")
    %test:assertEquals("movement-1 measure-1 note-1 measure-2")
    %test:args(1, "document")
    %test:assertEquals("movement-1 nested-movement movement-2")
    %test:args(2, "document")
    %test:assertEquals("movement-1 measure-1 measure-2 nested-movement nested-measure movement-2 measure-3")
    %test:args("-1", "document")
    %test:assertEquals("movement-1 measure-1 note-1 measure-2 nested-movement nested-measure movement-2 measure-3")
    function dnt:test-buildMemberArray-depth($down as xs:integer, $scope as xs:string) as xs:string {
        let $document := dnt:memberDocument()
        let $selection := if ($scope eq "document") then $document else $document//*[@xml:id = $scope]
        let $members := dts-navigation:buildMemberArray($selection, dnt:memberCitationTrees()[1], $down)
        return string-join($members/identifier, " ")
};

declare
    %test:assertTrue
    function dnt:test-buildMemberArray-flat-metadata() as xs:boolean {
        let $document := dnt:memberDocument()
        let $tree := dnt:memberCitationTrees()[1]
        let $members := dts-navigation:buildMemberArray($document//*[@xml:id = "movement-1"], $tree, -1)
        let $measure := dts-navigation:buildMemberArray($document//*[@xml:id = "measure-1"], $tree/citeStructure, 1)
        return
            count($members) eq 4
            and empty($members/member)
            and (every $member in $members satisfies (
                $member/self::member and $member/@json:array eq "true"
                and count($member/identifier) eq 1
                and $member/type[@json:name = "@type"] eq "CitableUnit"
            ))
            and $members[1]/level[@json:literal = "true"] eq "1"
            and string($members[1]/parent) eq ""
            and $members[2]/level eq "2"
            and $members[2]/parent eq "movement-1"
            and $members[3]/level eq "3"
            and $members[3]/parent eq "measure-1"
            and $members[3]/citeType eq "Note"
            and count($measure) eq 1
            and $measure/identifier eq "measure-1"
            and $measure/level eq "2"
            and $measure/parent eq "movement-1"
};

declare
    %test:assertTrue
    function dnt:test-buildMemberArray-multiple-selections-and-trees() as xs:boolean {
        let $document := dnt:memberDocument()
        let $trees := dnt:memberCitationTrees()
        let $selection := $document//*[@xml:id = ("movement-1", "movement-2")]
        let $selected := dts-navigation:buildMemberArray(reverse($selection), $trees[1], 2)
        let $all := dts-navigation:buildMemberArray($document, $trees, 2)
        return
            string-join($selected/identifier, " ") eq "movement-1 measure-1 measure-2 movement-2 measure-3"
            and string-join($all/identifier, " ") eq "surface-1 zone-1 movement-1 measure-1 measure-2 nested-movement nested-measure movement-2 measure-3"
            and $all[2]/parent eq "surface-1"
};

declare
    %test:assertTrue
    function dnt:test-buildMemberArray-emptiness() as xs:boolean {
        let $document := dnt:memberDocument()
        let $tree := dnt:memberCitationTrees()[1]
        return
            empty(dts-navigation:buildMemberArray($document, $tree, 0))
            and empty(dts-navigation:buildMemberArray($document, $tree, ()))
            and empty(dts-navigation:buildMemberArray((), $tree, -1))
            and empty(dts-navigation:buildMemberArray($document, (), -1))
            and empty(dts-navigation:buildMemberArray(document { <unmatched/> }, $tree, -1))
};

declare
    %test:assertTrue
    function dnt:test-buildMemberArray-leaf() as xs:boolean {
        let $document := dnt:memberDocument()
        let $tree := dnt:memberCitationTrees()[1]
        let $leaf := $document//*[@xml:id = "note-1"]
        let $members := dts-navigation:buildMemberArray($leaf, $tree/citeStructure/citeStructure, 10)
        return
            count($members) eq 1
            and $members/identifier eq "note-1"
            and $members/level eq "3"
};

declare
    %test:assertTrue
    function dnt:test-navigation-whole-document-member-wrappers() as xs:boolean {
        let $result := dts-navigation:navigation(
            "xmldb:exist:///db/apps/Edirom-Online-Backend/tests/XQSuite/data/mei-score.xml",
            (), (), (), 1, "musicStructure", ()
        )
        return
            count($result/member) eq 2
            and string-join($result/member/identifier, " ") eq "test-mdiv-1 test-mdiv-2"
            and empty($result/member/member)
            and (every $member in $result/member satisfies (
                $member/@json:array eq "true"
                and count($member/identifier) eq 1
                and $member/level eq "1"
            ))
};


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
        let $document := eutil:getDoc($resource)
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
    (: Function sets parent for child unit :)
    %test:arg("resource", "xmldb:exist:///db/apps/Edirom-Online-Backend/tests/XQSuite/data/mei-score.xml")
    %test:arg("ref", "test-measure-1")
    %test:arg("tree", "musicStructure")
    %test:assertEquals("2|test-mdiv-1|Measure")
    (: Function omits parent for root unit :)
    %test:arg("resource", "xmldb:exist:///db/apps/Edirom-Online-Backend/tests/XQSuite/data/mei-score.xml")
    %test:arg("ref", "test-mdiv-1")
    %test:arg("tree", "musicStructure")
    %test:assertEquals("1||Movement")
    (: Function supports TEI div tree :)
    %test:arg("resource", "xmldb:exist:///db/apps/Edirom-Online-Backend/tests/XQSuite/data/tei-document.xml")
    %test:arg("ref", "test-div-1")
    %test:arg("tree", "basicStructure")
    %test:assertEquals("1||Paragraph")
    (:Function supports TEI pagination tree :)
    %test:arg("resource", "xmldb:exist:///db/apps/Edirom-Online-Backend/tests/XQSuite/data/tei-document.xml")
    %test:arg("ref", "pb-1")
    %test:arg("tree", "paginationStructure")
    %test:assertEquals("1||Page")
    function dnt:test-buildCitableUnitObject(
        $resource as xs:string,
        $ref as xs:string,
        $tree as xs:string
    ) as xs:string {
        let $document := eutil:getDoc($resource)
        let $citationTree := dts-navigation:getCitationTrees($document)[@xml:id = $tree]
        let $selection := dts-common:selectBasedOnCiteStructure($document, $ref, $citationTree)
        let $citeStructure := dts-common:getCiteStructureForNode($selection, $citationTree)
        let $result := dts-navigation:buildCitableUnitObject($selection, $citeStructure, $ref)
        return
            string($result[self::level]) || "|" || string($result[self::parent]) || "|" || string($result[self::citeType])
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
    %test:arg("resource", "xmldb:exist:///db/apps/Edirom-Online-Backend/tests/XQSuite/data/mei-score.xml")
    %test:arg("ref", "test-measure-1")
    %test:arg("tree", "musicStructure")
    %test:arg("identifiers", "test-measure-1 test-measure-2 test-measure-3 test-measure-4")
    %test:arg("excludedIdentifiers", "test-mdiv-1 test-mdiv-2")
    %test:assertTrue
    %test:arg("resource", "xmldb:exist:///db/apps/Edirom-Online-Backend/tests/XQSuite/data/mei-score.xml")
    %test:arg("ref", "test-mdiv-2")
    %test:arg("tree", "musicStructure")
    %test:arg("identifiers", "test-mdiv-1 test-mdiv-2")
    %test:arg("excludedIdentifiers", "test-measure-1 test-measure-2 test-measure-3 test-measure-4")
    %test:assertTrue
    %test:arg("resource", "xmldb:exist:///db/apps/Edirom-Online-Backend/tests/XQSuite/data/tei-document.xml")
    %test:arg("ref", "pb-2")
    %test:arg("tree", "paginationStructure")
    %test:arg("identifiers", "pb-2")
    %test:arg("excludedIdentifiers", "pb-1 pb-3")
    %test:assertTrue
    function dnt:test-navigation-down-zero-returns-siblings(
        $resource as xs:string,
        $ref as xs:string,
        $tree as xs:string,
        $identifiers as xs:string,
        $excludedIdentifiers as xs:string
    ) as xs:boolean {
        let $result := dts-navigation:navigation($resource, $ref, (), (), 0, $tree, ())
        return
            $result/ref/identifier eq $ref
            and string-join($result/member/identifier, " ") eq $identifiers
            and empty($result/member[identifier = tokenize($excludedIdentifiers, "\s+")])
            and exists($result/member[identifier = $ref])
            and (every $member in $result/member satisfies (
                $member/@json:array eq "true"
                and $member/type[@json:name = "@type"] eq "CitableUnit"
                and $member/level eq $result/ref/level
                and $member/parent eq $result/ref/parent
                and $member/citeType eq $result/ref/citeType
            ))
};

declare
    %test:assertTrue
    function dnt:test-buildMemberArrayRefDownZero-uses-xml-parent() as xs:boolean {
        let $document := document {
            <mei xmlns="http://www.music-encoding.org/ns/mei">
                <music>
                    <body>
                        <mdiv xml:id="movement-1">
                            <score>
                                <section>
                                    <measure xml:id="measure-before"/>
                                    <measure xml:id="measure-1"/>
                                    <sb xml:id="system-break"/>
                                    <measure xml:id="measure-after"/>
                                </section>
                                <section><measure xml:id="measure-2"/></section>
                            </score>
                            <mdiv xml:id="nested-movement">
                                <score><section><measure xml:id="nested-measure"/></section></score>
                            </mdiv>
                        </mdiv>
                        <mdiv xml:id="movement-2">
                            <score><section><measure xml:id="measure-3"/></section></score>
                        </mdiv>
                    </body>
                </music>
            </mei>
        }
        let $citationTree := dts-navigation:getCitationTrees($document)[@xml:id = "musicStructure"]
        let $selection := dts-common:selectBasedOnCiteStructure($document, "measure-1", $citationTree)
        let $citeStructure := dts-common:getCiteStructureForNode($selection, $citationTree)
        let $members := dts-navigation:buildMemberArrayRefDownZero($selection, $citeStructure)
        let $singleSelection := dts-common:selectBasedOnCiteStructure($document, "measure-3", $citationTree)
        let $singleCiteStructure := dts-common:getCiteStructureForNode($singleSelection, $citationTree)
        let $singleMember := dts-navigation:buildMemberArrayRefDownZero($singleSelection, $singleCiteStructure)
        return
            string-join($members/identifier, " ") eq "measure-before measure-1 measure-after"
            and (every $member in $members satisfies $member/parent eq "movement-1")
            and count($singleMember) eq 1
            and $singleMember/identifier eq "measure-3"
            and $singleMember/@json:array eq "true"
};

declare
    %test:assertTrue
    function dnt:test-navigation-without-down-omits-members() as xs:boolean {
        let $result := dts-navigation:navigation(
            "xmldb:exist:///db/apps/Edirom-Online-Backend/tests/XQSuite/data/mei-score.xml",
            "test-mdiv-1", (), (), (), "musicStructure", ()
        )
        return empty($result/member) and $result/ref/identifier eq "test-mdiv-1"
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
