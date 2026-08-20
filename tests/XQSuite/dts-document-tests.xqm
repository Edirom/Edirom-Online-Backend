xquery version "3.1";

module namespace ddt = "http://www.edirom.de/xquery/xqsuite/dts-document-tests";

import module namespace dts-document = "http://www.edirom.de/api/dts-document" at "xmldb:exist:///db/apps/Edirom-Online-Backend/data/xqm/dts-document.xqm";
import module namespace eutil = "http://www.edirom.de/xquery/eutil" at "xmldb:exist:///db/apps/Edirom-Online-Backend/data/xqm/eutil.xqm";

declare namespace dts="https://w3id.org/dts/api#";
declare namespace mei="http://www.music-encoding.org/ns/mei";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace test="http://exist-db.org/xquery/xqsuite";
declare namespace xhtml="http://www.w3.org/1999/xhtml";

declare function ddt:citationTree(
    $tree as xs:string?
) as element(citeStructure)* {
    <refsDecl xmlns:mei="http://www.music-encoding.org/ns/mei">
        <citeStructure xml:id="musicStructure"
                        unit="Movement"
                        match="mei:mdiv"
                        use="@xml:id">
            <citeStructure unit="Measure"
                            match="mei:measure"
                            use="@xml:id"/>
        </citeStructure>
        <citeStructure xml:id="paginationStructure"
                        unit="Surface"
                        match="mei:surface"
                        use="@xml:id">
            <citeStructure unit="Zone"
                            match="mei:zone"
                            use="@xml:id"/>
        </citeStructure>
    </refsDecl>/citeStructure[
        not($tree) or @xml:id = $tree
    ]
};

declare function ddt:alternativeCitationTree(
    $tree as xs:string?
) as element(citeStructure)* {
    <refsDecl xmlns:mei="http://www.music-encoding.org/ns/mei">
        <citeStructure xml:id="musicStructure"
                        unit="Movement"
                        match="mei:mdiv"
                        use="@xml:id">
            <citeStructure unit="Measure"
                            match="mei:measure"
                            use="@n"/>
        </citeStructure>
        <citeStructure xml:id="paginationStructure"
                        unit="Surface"
                        match="mei:surface"
                        use="@xml:id">
            <citeStructure unit="Zone"
                            match="mei:zone"
                            use="@xml:id"/>
        </citeStructure>
    </refsDecl>/citeStructure[
        not($tree) or @xml:id = $tree
    ]
};

declare
    %test:assertEquals("movement-1")
    function ddt:test-selectBasedOnCiteStructure-selects-by-xml-id() as xs:string {
        let $document := document {
            <mei xmlns="http://www.music-encoding.org/ns/mei" meiversion="5.0.0">
                <meiHead/>
                <music>
                    <body>
                        <mdiv xml:id="movement-1">
                            <score>
                                <section>
                                    <measure n="42"/>
                                </section>
                            </score>
                        </mdiv>
                    </body>
                </music>
            </mei>
        }
        let $citationTree := ddt:alternativeCitationTree("musicStructure")
        let $selected := dts-document:selectBasedOnCiteStructure($document, "movement-1", $citationTree)
        return string($selected/@xml:id)
};

declare
    %test:assertEquals("42")
    function ddt:test-selectBasedOnCiteStructure-selects-by-n() as xs:string {
        let $document := document {
            <mei xmlns="http://www.music-encoding.org/ns/mei" meiversion="5.0.0">
                <meiHead/>
                <music>
                    <body>
                        <mdiv xml:id="movement-1">
                            <score>
                                <section>
                                    <measure n="42"/>
                                </section>
                            </score>
                        </mdiv>
                    </body>
                </music>
            </mei>
        }
        let $citationTree := ddt:alternativeCitationTree("musicStructure")
        let $selected := dts-document:selectBasedOnCiteStructure($document, "42", $citationTree)
        return string($selected/@n)
};

declare
    %test:args(
        "<mei xmlns='http://www.music-encoding.org/ns/mei' meiversion='5.0.0' xml:id='root'><meiHead><fileDesc/></meiHead><music><body><mdiv xml:id='selection'/></body></music></mei>"
    )
    %test:assertEquals("5.0.0")
    function ddt:test-wrapSelection-copies-meiversion(
        $documentRoot as element()
    ) as xs:string {
        let $document := document { $documentRoot }
        let $result := dts-document:wrapSelection($document/id("selection"), $document)
        return string($result/@meiversion)
};

declare
    %test:args(
        "<mei xmlns='http://www.music-encoding.org/ns/mei' meiversion='5.0.0'><meiHead><fileDesc/></meiHead><music><body><mdiv xml:id='selection'/></body></music></mei>"
    )
    %test:assertTrue
    function ddt:test-wrapSelection-preserves-meiHead(
        $documentRoot as element()
    ) as xs:boolean {
        let $document := document { $documentRoot }
        let $result := dts-document:wrapSelection($document/id("selection"), $document)
        return
            exists($result/mei:meiHead/mei:fileDesc)
            and empty($result//dts:wrapper/mei:meiHead)
};

declare
    %test:args(
        "<mei xmlns='http://www.music-encoding.org/ns/mei' meiversion='5.0.0'><meiHead/><music><body><mdiv xml:id='selection'><score/></mdiv></body></music></mei>"
    )
    %test:assertTrue
    function ddt:test-wrapSelection-inserts-selection-in-dts-wrapper(
        $documentRoot as element()
    ) as xs:boolean {
        let $document := document { $documentRoot }
        let $result := dts-document:wrapSelection($document/id("selection"), $document)
        return exists($result/mei:music/mei:body/dts:wrapper/mei:mdiv[@xml:id = "selection"]/mei:score)
};

declare
    %test:assertTrue
    function ddt:test-wrapSelection-inserts-multiple-mdivs() as xs:boolean {
        let $document :=
            document {
                <mei xmlns="http://www.music-encoding.org/ns/mei" meiversion="5.0.0">
                    <meiHead/>
                    <music>
                        <body>
                            <mdiv xml:id="selection-1"><score/></mdiv>
                            <mdiv xml:id="selection-2"><score/></mdiv>
                        </body>
                    </music>
                </mei>
            }
        let $result := dts-document:wrapSelection(($document/id("selection-1"), $document/id("selection-2")), $document)
        return
            count($result//dts:wrapper/mei:mdiv) = 2
            and exists($result//dts:wrapper/mei:mdiv[@xml:id = "selection-1"]/mei:score)
            and exists($result//dts:wrapper/mei:mdiv[@xml:id = "selection-2"]/mei:score)
};

declare
    %test:args(
        "<mei xmlns='http://www.music-encoding.org/ns/mei' xmlns:xlink='http://www.w3.org/1999/xlink' meiversion='5.0.0'><meiHead/><music><body><mdiv xml:id='selection'/></body></music></mei>"
    )
    %test:assertEquals("http://www.w3.org/1999/xlink")
    function ddt:test-wrapSelection-declares-xlink-namespace(
        $documentRoot as element()
    ) as xs:string {
        let $document := document { $documentRoot }
        let $result := dts-document:wrapSelection($document/id("selection"), $document)
        return namespace-uri-for-prefix("xlink", $result)
};

declare
    %test:assertTrue
    function ddt:test-wrapSelection-wraps-any-mei-selection() as xs:boolean {
        let $document :=
            document {
                <mei xmlns="http://www.music-encoding.org/ns/mei" meiversion="5.0.0">
                    <meiHead/>
                    <music><body><mdiv><score><section xml:id="selection"/></score></mdiv></body></music>
                </mei>
            }
        let $result := dts-document:wrapSelection($document/id("selection"), $document)
        return exists($result/mei:music/mei:body/mei:mdiv/mei:score/dts:wrapper/mei:section[@xml:id = "selection"])
};

declare
    %test:assertTrue
    function ddt:test-wrapSelection-prunes-unselected-sibling-mdivs() as xs:boolean {
        let $document :=
            document {
                <mei xmlns="http://www.music-encoding.org/ns/mei" meiversion="5.0.0">
                    <meiHead/>
                    <music>
                        <body>
                            <mdiv xml:id="selection"/>
                            <mdiv xml:id="skipped"/>
                        </body>
                    </music>
                </mei>
            }
        let $result := dts-document:wrapSelection($document/id("selection"), $document)
        return
            exists($result/mei:music/mei:body/dts:wrapper/mei:mdiv[@xml:id = "selection"])
            and empty($result//mei:mdiv[@xml:id = "skipped"])
};

declare
    %test:assertTrue
    function ddt:test-wrapSelection-preserves-surface-ancestor-and-preceding-graphic-for-zone() as xs:boolean {
        let $document :=
            document {
                <mei xmlns="http://www.music-encoding.org/ns/mei" meiversion="5.0.0">
                    <meiHead/>
                    <music>
                        <facsimile>
                            <surface xml:id="surface">
                                <graphic xml:id="graphic"/>
                                <zone xml:id="selection"/>
                                <zone xml:id="skipped"/>
                            </surface>
                        </facsimile>
                    </music>
                </mei>
            }
        let $result := dts-document:wrapSelection($document/id("selection"), $document)
        return
            exists($result/mei:music/mei:facsimile/mei:surface[@xml:id = "surface"]/dts:wrapper/mei:zone[@xml:id = "selection"])
            and exists($result/mei:music/mei:facsimile/mei:surface[@xml:id = "surface"]/mei:graphic[@xml:id = "graphic"])
            and empty($result//mei:zone[@xml:id = "skipped"])
};

declare
    %test:assertTrue
    function ddt:test-wrapSelection-preserves-measure-ancestor-structure() as xs:boolean {
        let $document :=
            document {
                <mei xmlns="http://www.music-encoding.org/ns/mei" meiversion="5.0.0">
                    <meiHead/>
                    <music>
                        <body>
                            <mdiv>
                                <score>
                                    <section>
                                        <measure xml:id="selection"/>
                                        <measure xml:id="skipped"/>
                                    </section>
                                </score>
                            </mdiv>
                        </body>
                    </music>
                </mei>
            }
        let $result := dts-document:wrapSelection($document/id("selection"), $document)
        return
            exists($result/mei:music/mei:body/mei:mdiv/mei:score/mei:section/dts:wrapper/mei:measure[@xml:id = "selection"])
            and empty($result//mei:measure[@xml:id = "skipped"])
};

declare
    %test:assertTrue
    function ddt:test-wrapSelection-preserves-configured-preceding-sibling() as xs:boolean {
        let $document :=
            document {
                <mei xmlns="http://www.music-encoding.org/ns/mei" meiversion="5.0.0">
                    <meiHead/>
                    <music>
                        <body>
                            <mdiv>
                                <score>
                                    <scoreDef xml:id="preceding-scoreDef">
                                        <staffGrp>
                                            <staffDef n="1"/>
                                        </staffGrp>
                                    </scoreDef>
                                    <section>
                                        <measure xml:id="selection"/>
                                    </section>
                                    <scoreDef xml:id="following-scoreDef"/>
                                </score>
                            </mdiv>
                        </body>
                    </music>
                </mei>
            }
        let $result := dts-document:wrapSelection($document/id("selection"), $document)
        return
            exists($result//mei:scoreDef[@xml:id = "preceding-scoreDef"]/mei:staffGrp/mei:staffDef)
            and empty($result//mei:scoreDef[@xml:id = "following-scoreDef"])
};

declare
    %test:assertTrue
    function ddt:test-wrapSelection-includes-forward-facs-reference() as xs:boolean {
        let $document :=
            document {
                <mei xmlns="http://www.music-encoding.org/ns/mei" meiversion="5.0.0">
                    <meiHead/>
                    <music>
                        <facsimile>
                            <surface xml:id="surface">
                                <zone xml:id="referenced-zone"/>
                                <zone xml:id="skipped-zone"/>
                            </surface>
                        </facsimile>
                        <body>
                            <mdiv>
                                <score>
                                    <section>
                                        <measure facs="#referenced-zone" xml:id="selection"/>
                                    </section>
                                </score>
                            </mdiv>
                        </body>
                    </music>
                </mei>
            }
        let $result := dts-document:wrapSelection($document/id("selection"), $document)
        return
            exists($result//dts:wrapper/mei:measure[@xml:id = "selection"])
            and exists($result/mei:music/mei:facsimile/mei:surface[@xml:id = "surface"]/mei:zone[@xml:id = "referenced-zone"])
            and empty($result//mei:zone[@xml:id = "skipped-zone"])
};

declare
    %test:assertTrue
    function ddt:test-wrapSelection-preserves-configured-preceding-sibling-for-referenced-zone() as xs:boolean {
        let $document :=
            document {
                <mei xmlns="http://www.music-encoding.org/ns/mei" meiversion="5.0.0">
                    <meiHead/>
                    <music>
                        <facsimile>
                            <surface xml:id="surface">
                                <graphic xml:id="graphic"/>
                                <zone xml:id="referenced-zone"/>
                                <zone xml:id="skipped-zone"/>
                            </surface>
                        </facsimile>
                        <body>
                            <mdiv>
                                <score>
                                    <section>
                                        <measure facs="#referenced-zone" xml:id="selection"/>
                                    </section>
                                </score>
                            </mdiv>
                        </body>
                    </music>
                </mei>
            }
        let $result := dts-document:wrapSelection($document/id("selection"), $document)
        return
            exists($result//dts:wrapper/mei:measure[@xml:id = "selection"])
            and exists($result/mei:music/mei:facsimile/mei:surface/mei:graphic[@xml:id = "graphic"])
            and empty($result//mei:zone[@xml:id = "skipped-zone"])
};

declare
    %test:assertTrue
    function ddt:test-wrapSelection-ignores-non-facs-reference-attributes() as xs:boolean {
        let $document :=
            document {
                <mei xmlns="http://www.music-encoding.org/ns/mei" meiversion="5.0.0">
                    <meiHead/>
                    <music>
                        <facsimile>
                            <surface xml:id="surface">
                                <zone xml:id="target-zone"/>
                            </surface>
                        </facsimile>
                        <body>
                            <mdiv>
                                <score>
                                    <section>
                                        <measure corresp="#target-zone" xml:id="selection"/>
                                    </section>
                                </score>
                            </mdiv>
                        </body>
                    </music>
                </mei>
            }
        let $result := dts-document:wrapSelection($document/id("selection"), $document)
        return
            exists($result//dts:wrapper/mei:measure[@xml:id = "selection"])
            and empty($result//mei:zone[@xml:id = "target-zone"])
};

declare
    %test:assertEquals("selection-2")
    function ddt:test-selectAndWrap-selects-ref-in-musicStructure-tree() as xs:string {
        let $documentRoot :=
            <mei xmlns="http://www.music-encoding.org/ns/mei" meiversion="5.0.0">
                <meiHead/>
                <music>
                    <body>
                        <mdiv xml:id="selection-1"/>
                        <mdiv xml:id="selection-2"/>
                    </body>
                </music>
            </mei>
        let $result := dts-document:selectAndWrap(document { $documentRoot }, "selection-2", (), (), ddt:citationTree("musicStructure"))
        return string($result//dts:wrapper/mei:mdiv/@xml:id)
};

declare
    %test:assertEquals("selection-1", "selection-2", "selection-3")
    function ddt:test-selectAndWrap-selects-start-end-range() as xs:string* {
        let $documentRoot :=
            <mei xmlns="http://www.music-encoding.org/ns/mei" meiversion="5.0.0">
                <meiHead/>
                <music>
                    <body>
                        <mdiv xml:id="selection-1"/>
                        <mdiv xml:id="selection-2"/>
                        <mdiv xml:id="selection-3"/>
                    </body>
                </music>
            </mei>
        let $result := dts-document:selectAndWrap(document { $documentRoot }, (), "selection-1", "selection-3", ddt:citationTree("musicStructure"))
        return
            for $mdiv in $result//dts:wrapper/mei:mdiv
            return string($mdiv/@xml:id)
};

declare
    %test:assertError("errors:NotFoundError")
    function ddt:test-selectAndWrap-errors-when-selection-not-found() as node()* {
        let $documentRoot :=
            <mei xmlns="http://www.music-encoding.org/ns/mei" meiversion="5.0.0">
                <meiHead/>
                <music><body><mdiv xml:id="selection-1"/></body></music>
            </mei>
        return dts-document:selectAndWrap(document { $documentRoot }, "missing", (), (), ddt:citationTree("musicStructure"))
};

declare
    %test:assertTrue
    function ddt:test-selectTEIPages-returns-something() {
        let $document := doc("xmldb:exist:///db/apps/Edirom-Online-Backend/tests/XQSuite/data/tei-document.xml")
        let $document := eutil:add-xml-ids($document)
        let $result :=
        <result>
        {
            dts-document:selectTEIPages(
                $document,
                $document//tei:pb[@xml:id = "pb-1"],
                ()
            )
        }
        </result>
        return
            $result
};

declare
    %test:assertTrue
    function ddt:test-selectTEIPages-with-endPb-selects-page-range() as xs:boolean {
        let $document := doc("xmldb:exist:///db/apps/Edirom-Online-Backend/tests/XQSuite/data/tei-document.xml")
        let $document := eutil:add-xml-ids($document)
        let $result := 
        <result>
        {
            dts-document:selectTEIPages(
                $document,
                $document//tei:pb[@xml:id = "pb-1"],
                $document//tei:pb[@xml:id = "pb-2"]
            )
        }
        </result>
        return
            exists($result//tei:pb[@xml:id = "pb-1"])
            and exists($result//tei:pb[@xml:id = "pb-2"])
            and exists($result//tei:p[@xml:id = "yes-in-p2-1"])
            and empty($result//tei:div[@xml:id = "test-div-3"])
            and empty($result//tei:p[@xml:id = "not-in-p2-2"])
};

declare
    %test:assertTrue
    function ddt:test-selectTEIPages-with-empty-endPb-selects-current-page() as xs:boolean {
        let $document := doc("xmldb:exist:///db/apps/Edirom-Online-Backend/tests/XQSuite/data/tei-document.xml")
        let $document := eutil:add-xml-ids($document)
        let $result := dts-document:selectTEIPages(
            $document,
            $document//tei:pb[@xml:id = "pb-2"],
            ()
        )
        return
            exists($result//tei:pb[@xml:id = "pb-2"])
            and exists($result//tei:p[@xml:id = "yes-in-p2-1"])
            and empty($result//tei:pb[@xml:id = "pb-1"])
            and empty($result//tei:pb[@xml:id = "pb-3"])
            and empty($result//tei:p[@xml:id = "not-in-p2-1"])
            and empty($result//tei:p[@xml:id = "not-in-p2-2"])
};

declare
    %test:args("", "mei")                         %test:assertTrue
    %test:args("application/xml", "mei")          %test:assertTrue
    %test:args("text/xml", "mei")                 %test:assertTrue
    %test:args("application/mei+xml", "mei")      %test:assertTrue
    %test:args("application/tei+xml", "mei")      %test:assertFalse
    %test:args("application/json", "edirom")      %test:assertFalse
    %test:args("application/xml", "unknown")      %test:assertFalse
    function ddt:test-isMediaTypeCompatible($mediaType as xs:string?, $namespace as xs:string) as xs:boolean {
        dts-document:isMediaTypeCompatible($mediaType, $namespace)
};

declare
    (: Valid requests :)
    (: retrieve full mei :)
    %test:arg("resource", "xmldb:exist:///db/apps/Edirom-Online-Backend/tests/XQSuite/data/mei-score.xml")
    %test:arg("ref") %test:arg("start") %test:arg("end") %test:arg("tree")
    %test:arg("mediaType", "application/xml")
    %test:arg("lang")
    %test:assertXPath("/Q{http://www.music-encoding.org/ns/mei}mei[@xml:id='test-mei-score']")
    (: retrieve a specific mdiv by ref :)
    %test:arg("resource", "xmldb:exist:///db/apps/Edirom-Online-Backend/tests/XQSuite/data/mei-score.xml")
    %test:arg("ref", "test-mdiv-1")
    %test:arg("start") %test:arg("end")
    %test:arg("tree", "musicStructure")
    %test:arg("mediaType", "application/xml")
    %test:arg("lang", "de")
    %test:assertXPath("/Q{http://www.music-encoding.org/ns/mei}mei//Q{https://w3id.org/dts/api#}wrapper/Q{http://www.music-encoding.org/ns/mei}mdiv[@xml:id='test-mdiv-1']")
    (: retrieve a range of mdivs by start and end :)
    %test:arg("resource", "xmldb:exist:///db/apps/Edirom-Online-Backend/tests/XQSuite/data/mei-score.xml")
    %test:arg("ref")
    %test:arg("start", "test-mdiv-1")
    %test:arg("end", "test-mdiv-2")
    %test:arg("tree", "musicStructure")
    %test:arg("mediaType", "application/xml")
    %test:arg("lang")
    %test:assertXPath("/Q{http://www.music-encoding.org/ns/mei}mei//Q{https://w3id.org/dts/api#}wrapper/Q{http://www.music-encoding.org/ns/mei}mdiv[@xml:id='test-mdiv-1']")
    %test:assertXPath("/Q{http://www.music-encoding.org/ns/mei}mei//Q{https://w3id.org/dts/api#}wrapper/Q{http://www.music-encoding.org/ns/mei}mdiv[@xml:id='test-mdiv-2']")
    (: retrieve a specific measure by ref :)
    %test:arg("resource", "xmldb:exist:///db/apps/Edirom-Online-Backend/tests/XQSuite/data/mei-score.xml")
    %test:arg("ref", "test-measure-1")
    %test:arg("start") %test:arg("end")
    %test:arg("tree", "musicStructure")
    %test:arg("mediaType", "application/xml")
    %test:arg("lang")
    %test:assertXPath("/Q{http://www.music-encoding.org/ns/mei}mei//Q{https://w3id.org/dts/api#}wrapper/Q{http://www.music-encoding.org/ns/mei}measure[@xml:id='test-measure-1']")
    (: retrieve a range of measures by start and end :)
    %test:arg("resource", "xmldb:exist:///db/apps/Edirom-Online-Backend/tests/XQSuite/data/mei-score.xml")
    %test:arg("ref")
    %test:arg("start", "test-measure-2")
    %test:arg("end", "test-measure-4")
    %test:arg("tree", "musicStructure")
    %test:arg("mediaType", "application/xml")
    %test:arg("lang")
    %test:assertXPath("/Q{http://www.music-encoding.org/ns/mei}mei//Q{https://w3id.org/dts/api#}wrapper/Q{http://www.music-encoding.org/ns/mei}measure[@xml:id='test-measure-2']")
    %test:assertXPath("/Q{http://www.music-encoding.org/ns/mei}mei//Q{https://w3id.org/dts/api#}wrapper/Q{http://www.music-encoding.org/ns/mei}measure[@xml:id='test-measure-3']")
    %test:assertXPath("/Q{http://www.music-encoding.org/ns/mei}mei//Q{https://w3id.org/dts/api#}wrapper/Q{http://www.music-encoding.org/ns/mei}measure[@xml:id='test-measure-4']")
    (: retrieve a specific surface by ref :)
    %test:arg("resource", "xmldb:exist:///db/apps/Edirom-Online-Backend/tests/XQSuite/data/mei-facsimile.xml")
    %test:arg("ref", "facsimile-2001002")
    %test:arg("start") %test:arg("end")
    %test:arg("tree", "paginationStructure")
    %test:arg("mediaType", "application/xml")
    %test:arg("lang")
    %test:assertXPath("/Q{http://www.music-encoding.org/ns/mei}mei//Q{https://w3id.org/dts/api#}wrapper/Q{http://www.music-encoding.org/ns/mei}surface[@xml:id='facsimile-2001002']")
    (:retrieve a range of surfaces by start and end :)
    %test:arg("resource", "xmldb:exist:///db/apps/Edirom-Online-Backend/tests/XQSuite/data/mei-facsimile.xml")
    %test:arg("ref")
    %test:arg("start", "facsimile-2001002")
    %test:arg("end", "facsimile-2001004")
    %test:arg("tree", "paginationStructure")
    %test:arg("mediaType", "application/xml")
    %test:arg("lang")
    %test:assertXPath("/Q{http://www.music-encoding.org/ns/mei}mei//Q{https://w3id.org/dts/api#}wrapper/Q{http://www.music-encoding.org/ns/mei}surface[@xml:id='facsimile-2001002']")
    %test:assertXPath("/Q{http://www.music-encoding.org/ns/mei}mei//Q{https://w3id.org/dts/api#}wrapper/Q{http://www.music-encoding.org/ns/mei}surface[@xml:id='facsimile-2001003']")
    %test:assertXPath("/Q{http://www.music-encoding.org/ns/mei}mei//Q{https://w3id.org/dts/api#}wrapper/Q{http://www.music-encoding.org/ns/mei}surface[@xml:id='facsimile-2001004']")
    (: retrieve a specific zone by ref :)
    %test:arg("resource", "xmldb:exist:///db/apps/Edirom-Online-Backend/tests/XQSuite/data/mei-facsimile.xml")
    %test:arg("ref", "zone_bar-2001")
    %test:arg("start") %test:arg("end")
    %test:arg("tree", "paginationStructure")
    %test:arg("mediaType", "application/xml")
    %test:arg("lang")
    %test:assertXPath("/Q{http://www.music-encoding.org/ns/mei}mei//Q{https://w3id.org/dts/api#}wrapper/Q{http://www.music-encoding.org/ns/mei}zone[@xml:id='zone_bar-2001']")
    (: retrieve a range of zones by start and end :)
    %test:arg("resource", "xmldb:exist:///db/apps/Edirom-Online-Backend/tests/XQSuite/data/mei-facsimile.xml")
    %test:arg("ref")
    %test:arg("start", "zone_bar-20013")
    %test:arg("end", "zone_bar-20015")
    %test:arg("tree", "paginationStructure")
    %test:arg("mediaType", "application/xml")
    %test:arg("lang")
    %test:assertXPath("/Q{http://www.music-encoding.org/ns/mei}mei//Q{https://w3id.org/dts/api#}wrapper/Q{http://www.music-encoding.org/ns/mei}zone[@xml:id='zone_bar-20013']")
    %test:assertXPath("/Q{http://www.music-encoding.org/ns/mei}mei//Q{https://w3id.org/dts/api#}wrapper/Q{http://www.music-encoding.org/ns/mei}zone[@xml:id='zone_bar-20014']")
    %test:assertXPath("/Q{http://www.music-encoding.org/ns/mei}mei//Q{https://w3id.org/dts/api#}wrapper/Q{http://www.music-encoding.org/ns/mei}zone[@xml:id='zone_bar-20015']")
    (: retrieve a specific measure by ref in a facsimile document :)
    %test:arg("resource", "xmldb:exist:///db/apps/Edirom-Online-Backend/tests/XQSuite/data/mei-facsimile.xml")
    %test:arg("ref", "bar-2003")
    %test:arg("start") %test:arg("end")
    %test:arg("tree", "musicStructure")
    %test:arg("mediaType", "application/xml")
    %test:arg("lang")
    %test:assertXPath("/Q{http://www.music-encoding.org/ns/mei}mei//Q{https://w3id.org/dts/api#}wrapper/Q{http://www.music-encoding.org/ns/mei}measure[@xml:id='bar-2003']")
    %test:assertXPath("/Q{http://www.music-encoding.org/ns/mei}mei//Q{http://www.music-encoding.org/ns/mei}zone[@xml:id='zone_bar-2003']")
    (: retrieve a range of measures by start and end in a facsimile document :)
    %test:arg("resource", "xmldb:exist:///db/apps/Edirom-Online-Backend/tests/XQSuite/data/mei-facsimile.xml")
    %test:arg("ref")
    %test:arg("start", "bar-20010")
    %test:arg("end", "bar-20013")
    %test:arg("tree", "musicStructure")
    %test:arg("mediaType", "application/xml")
    %test:arg("lang")
    %test:assertXPath("/Q{http://www.music-encoding.org/ns/mei}mei//Q{https://w3id.org/dts/api#}wrapper/Q{http://www.music-encoding.org/ns/mei}measure[@xml:id='bar-20010']")
    %test:assertXPath("/Q{http://www.music-encoding.org/ns/mei}mei//Q{https://w3id.org/dts/api#}wrapper/Q{http://www.music-encoding.org/ns/mei}measure[@xml:id='bar-20011']")
    %test:assertXPath("/Q{http://www.music-encoding.org/ns/mei}mei//Q{https://w3id.org/dts/api#}wrapper/Q{http://www.music-encoding.org/ns/mei}measure[@xml:id='bar-20012']")
    %test:assertXPath("/Q{http://www.music-encoding.org/ns/mei}mei//Q{https://w3id.org/dts/api#}wrapper/Q{http://www.music-encoding.org/ns/mei}measure[@xml:id='bar-20013']")
    %test:assertXPath("/Q{http://www.music-encoding.org/ns/mei}mei//Q{http://www.music-encoding.org/ns/mei}zone[@xml:id='zone_bar-20010']")
    %test:assertXPath("/Q{http://www.music-encoding.org/ns/mei}mei//Q{http://www.music-encoding.org/ns/mei}zone[@xml:id='zone_bar-20011']")
    %test:assertXPath("/Q{http://www.music-encoding.org/ns/mei}mei//Q{http://www.music-encoding.org/ns/mei}zone[@xml:id='zone_bar-20012']")
    %test:assertXPath("/Q{http://www.music-encoding.org/ns/mei}mei//Q{http://www.music-encoding.org/ns/mei}zone[@xml:id='zone_bar-20013']")
    (: retrieve meiHead by ref :)
    %test:arg("resource", "xmldb:exist:///db/apps/Edirom-Online-Backend/tests/XQSuite/data/mei-score.xml")
    %test:arg("ref", "meiHead")
    %test:arg("start") %test:arg("end")
    %test:arg("tree")
    %test:arg("mediaType", "application/xml")
    %test:arg("lang")
    %test:assertXPath("/Q{http://www.music-encoding.org/ns/mei}mei//Q{https://w3id.org/dts/api#}wrapper/Q{http://www.music-encoding.org/ns/mei}meiHead")
    (: retrieve full tei :)
    %test:arg("resource", "xmldb:exist:///db/apps/Edirom-Online-Backend/tests/XQSuite/data/tei-document.xml")
    %test:arg("ref") %test:arg("start") %test:arg("end") %test:arg("tree")
    %test:arg("mediaType", "application/xml")
    %test:arg("lang")
    %test:assertXPath("/Q{http://www.tei-c.org/ns/1.0}TEI[@xml:id='test-tei-document']")
    (: retrieve tei div :)
    %test:arg("resource", "xmldb:exist:///db/apps/Edirom-Online-Backend/tests/XQSuite/data/tei-document.xml")
    %test:arg("ref", "test-div-1")
    %test:arg("start") %test:arg("end") %test:arg("tree")
    %test:arg("mediaType", "application/xml")
    %test:arg("lang")
    %test:assertXPath("/Q{http://www.tei-c.org/ns/1.0}TEI[@xml:id='test-tei-document']//Q{https://w3id.org/dts/api#}wrapper/Q{http://www.tei-c.org/ns/1.0}div[@xml:id='test-div-1']")
    (: retrieve range of tei divs :)
    %test:arg("resource", "xmldb:exist:///db/apps/Edirom-Online-Backend/tests/XQSuite/data/tei-document.xml")
    %test:arg("ref")
    %test:arg("start", "test-div-2")
    %test:arg("end", "test-div-3")
    %test:arg("tree")
    %test:arg("mediaType", "application/xml")
    %test:arg("lang")
    %test:assertXPath("/Q{http://www.tei-c.org/ns/1.0}TEI[@xml:id='test-tei-document']//Q{https://w3id.org/dts/api#}wrapper/Q{http://www.tei-c.org/ns/1.0}div[@xml:id='test-div-2']")
    %test:assertXPath("/Q{http://www.tei-c.org/ns/1.0}TEI[@xml:id='test-tei-document']//Q{https://w3id.org/dts/api#}wrapper/Q{http://www.tei-c.org/ns/1.0}div[@xml:id='test-div-3']")
    (: retrieve tei page :)
    %test:arg("resource", "xmldb:exist:///db/apps/Edirom-Online-Backend/tests/XQSuite/data/tei-document.xml")
    %test:arg("ref", "pb-1")
    %test:arg("start") %test:arg("end")
    %test:arg("tree", "paginationStructure")
    %test:arg("mediaType", "application/xml")
    %test:arg("lang", "de")
    %test:assertXPath("/Q{http://www.tei-c.org/ns/1.0}TEI[@xml:id='test-tei-document']//Q{https://w3id.org/dts/api#}wrapper/Q{http://www.tei-c.org/ns/1.0}pb[@xml:id='pb-1']")
    %test:assertXPath("/Q{http://www.tei-c.org/ns/1.0}TEI[@xml:id='test-tei-document']//Q{https://w3id.org/dts/api#}wrapper/Q{http://www.tei-c.org/ns/1.0}div[@xml:id='test-div-1']")
    (: retrieve tei page starting in the middle of div :)
    %test:arg("resource", "xmldb:exist:///db/apps/Edirom-Online-Backend/tests/XQSuite/data/tei-document.xml")
    %test:arg("ref", "pb-2")
    %test:arg("start") %test:arg("end")
    %test:arg("tree", "paginationStructure")
    %test:arg("mediaType", "application/xml")
    %test:arg("lang", "de")
    %test:assertXPath("/Q{http://www.tei-c.org/ns/1.0}TEI[@xml:id='test-tei-document']//Q{https://w3id.org/dts/api#}wrapper/Q{http://www.tei-c.org/ns/1.0}div[@xml:id='test-div-1']/Q{http://www.tei-c.org/ns/1.0}pb[@xml:id='pb-2']")
    (: retrieve the last tei page worhout any pb after it :)
    %test:arg("resource", "xmldb:exist:///db/apps/Edirom-Online-Backend/tests/XQSuite/data/tei-document.xml")
    %test:arg("ref", "pb-3")
    %test:arg("start") %test:arg("end")
    %test:arg("tree", "paginationStructure")
    %test:arg("mediaType", "application/xml")
    %test:arg("lang", "de")
    %test:assertXPath("/Q{http://www.tei-c.org/ns/1.0}TEI[@xml:id='test-tei-document']//Q{https://w3id.org/dts/api#}wrapper//Q{http://www.tei-c.org/ns/1.0}div[@xml:id='test-div-2']/Q{http://www.tei-c.org/ns/1.0}pb[@xml:id='pb-3']")
    %test:assertXPath("/Q{http://www.tei-c.org/ns/1.0}TEI[@xml:id='test-tei-document']//Q{https://w3id.org/dts/api#}wrapper//Q{http://www.tei-c.org/ns/1.0}div[@xml:id='test-div-3']//Q{http://www.tei-c.org/ns/1.0}p[@rend='footer']")
    (: retieve range of tei pages :)
    %test:arg("resource", "xmldb:exist:///db/apps/Edirom-Online-Backend/tests/XQSuite/data/tei-document.xml")
    %test:arg("ref")
    %test:arg("start", "pb-1")
    %test:arg("end", "pb-2")
    %test:arg("tree", "paginationStructure")
    %test:arg("mediaType", "application/xml")
    %test:arg("lang", "de")
    %test:assertXPath("/Q{http://www.tei-c.org/ns/1.0}TEI[@xml:id='test-tei-document']//Q{https://w3id.org/dts/api#}wrapper/Q{http://www.tei-c.org/ns/1.0}pb[@xml:id='pb-1']")
    %test:assertXPath("/Q{http://www.tei-c.org/ns/1.0}TEI[@xml:id='test-tei-document']//Q{https://w3id.org/dts/api#}wrapper/Q{http://www.tei-c.org/ns/1.0}div[@xml:id='test-div-1']")
    %test:assertXPath("/Q{http://www.tei-c.org/ns/1.0}TEI[@xml:id='test-tei-document']//Q{https://w3id.org/dts/api#}wrapper/Q{http://www.tei-c.org/ns/1.0}div[@xml:id='test-div-1']/Q{http://www.tei-c.org/ns/1.0}pb[@xml:id='pb-2']")
    (: retrieve range of tei pages starting in the middle of div and ending with last pb :)
    %test:arg("resource", "xmldb:exist:///db/apps/Edirom-Online-Backend/tests/XQSuite/data/tei-document.xml")
    %test:arg("ref")
    %test:arg("start", "pb-2")
    %test:arg("end", "pb-3")
    %test:arg("tree", "paginationStructure")
    %test:arg("mediaType", "application/xml")
    %test:arg("lang", "de")
    %test:assertXPath("/Q{http://www.tei-c.org/ns/1.0}TEI[@xml:id='test-tei-document']//Q{https://w3id.org/dts/api#}wrapper//Q{http://www.tei-c.org/ns/1.0}div[@xml:id='test-div-1']/Q{http://www.tei-c.org/ns/1.0}pb[@xml:id='pb-2']")
    %test:assertXPath("/Q{http://www.tei-c.org/ns/1.0}TEI[@xml:id='test-tei-document']//Q{https://w3id.org/dts/api#}wrapper//Q{http://www.tei-c.org/ns/1.0}div[@xml:id='test-div-2']/Q{http://www.tei-c.org/ns/1.0}pb[@xml:id='pb-3']")
    %test:assertXPath("/Q{http://www.tei-c.org/ns/1.0}TEI[@xml:id='test-tei-document']//Q{https://w3id.org/dts/api#}wrapper//Q{http://www.tei-c.org/ns/1.0}div[@xml:id='test-div-3']//Q{http://www.tei-c.org/ns/1.0}p[@rend='footer']")
    (: retrieve teiHeader by ref :)
    %test:arg("resource", "xmldb:exist:///db/apps/Edirom-Online-Backend/tests/XQSuite/data/tei-document.xml")
    %test:arg("ref", "teiHeader")
    %test:arg("start") %test:arg("end") %test:arg("tree")
    %test:arg("mediaType", "application/xml")
    %test:arg("lang")
    %test:assertXPath("/Q{http://www.tei-c.org/ns/1.0}TEI[@xml:id='test-tei-document']//Q{https://w3id.org/dts/api#}wrapper/Q{http://www.tei-c.org/ns/1.0}teiHeader")
    (: Errors :)
    (: ask both for ref and start/end mei :)
    %test:arg("resource", "xmldb:exist:///db/apps/Edirom-Online-Backend/tests/XQSuite/data/mei-score.xml")
    %test:arg("ref", "test-mdiv-1")
    %test:arg("start", "test-mdiv-1")
    %test:arg("end", "test-mdiv-2")
    %test:arg("tree", "musicStructure")
    %test:arg("mediaType", "application/xml")
    %test:arg("lang")
    %test:assertError("errors:InvalidParametersError")
    (: ask both for non-existing ref mei :)
    %test:arg("resource", "xmldb:exist:///db/apps/Edirom-Online-Backend/tests/XQSuite/data/mei-score.xml")
    %test:arg("ref", "foo")
    %test:arg("start")
    %test:arg("end")
    %test:arg("tree", "musicStructure")
    %test:arg("mediaType", "application/xml")
    %test:arg("lang")
    %test:assertError("errors:NotFoundError")
    (: ask both for ref and start/end tei :)
    %test:arg("resource", "xmldb:exist:///db/apps/Edirom-Online-Backend/tests/XQSuite/data/tei-document.xml")
    %test:arg("ref", "test-div-1")
    %test:arg("start", "test-div-1")
    %test:arg("end", "test-div-2")
    %test:arg("tree")
    %test:arg("mediaType", "application/xml")
    %test:arg("lang")
    %test:assertError("errors:InvalidParametersError")
    (: ask for start without end mei :)
    %test:arg("resource", "xmldb:exist:///db/apps/Edirom-Online-Backend/tests/XQSuite/data/mei-score.xml")
    %test:arg("ref")
    %test:arg("start", "test-mdiv-1")
    %test:arg("end")
    %test:arg("tree", "musicStructure")
    %test:arg("mediaType", "application/xml")
    %test:arg("lang")
    %test:assertError("errors:InvalidParametersError")
    (: ask for start without end tei :)
    %test:arg("resource", "xmldb:exist:///db/apps/Edirom-Online-Backend/tests/XQSuite/data/tei-document.xml")
    %test:arg("ref")
    %test:arg("start", "test-div-1")
    %test:arg("end")
    %test:arg("tree")
    %test:arg("mediaType", "application/xml")
    %test:arg("lang")
    %test:assertError("errors:InvalidParametersError")
    (: ask for an mei element that is not in the tree and not in the always-included meiHead :)
    %test:arg("resource", "xmldb:exist:///db/apps/Edirom-Online-Backend/tests/XQSuite/data/mei-score.xml")
    %test:arg("ref", "body")
    %test:arg("start") %test:arg("end")
    %test:arg("tree", "musicStructure")
    %test:arg("mediaType", "application/xml")
    %test:arg("lang")
    %test:assertError("errors:InvalidParametersError")
    (: ask for a tei element that is not in the tree and not in the always-included teiHead :)
    %test:arg("resource", "xmldb:exist:///db/apps/Edirom-Online-Backend/tests/XQSuite/data/tei-document.xml")
    %test:arg("ref", "text")
    %test:arg("start") %test:arg("end")
    %test:arg("tree")
    %test:arg("mediaType", "application/xml")
    %test:arg("lang")
    %test:assertError("errors:InvalidParametersError")
    function ddt:test-document-xml(
        $resource as xs:string,
        $ref as xs:string?,
        $start as xs:string?,
        $end as xs:string?,
        $tree as xs:string?,
        $mediaType as xs:string?,
        $lang as xs:string?
    ) as document-node() { 
        let $html-parameters := map {
            "lang": if ($lang) then $lang else "de",
            "idPrefix": ""
        }
        return
            dts-document:document($resource, $ref, $start, $end, $tree, $mediaType, $html-parameters)
};

declare
    (: retrieve meiHead by ref as html :)
    %test:arg("resource", "xmldb:exist:///db/apps/Edirom-Online-Backend/tests/XQSuite/data/mei-score.xml")
    %test:arg("ref", "meiHead")
    %test:arg("start") %test:arg("end")
    %test:arg("lang")
    %test:arg("idPrefix")
    %test:arg("htmlProfile", "edirom-header")
    %test:assertXPath("/Q{http://www.w3.org/1999/xhtml}div[@class='meiHead']")
    (: retrieve teiHeader by ref as html :)
    (: TODO: once the teiBody2HTML.xsl stylesheet is reactivated
    %test:arg("resource", "xmldb:exist:///db/apps/Edirom-Online-Backend/tests/XQSuite/data/tei-document.xml")
    %test:arg("ref", "teiHeader")
    %test:arg("start") %test:arg("end")
    %test:arg("lang")
    %test:arg("idPrefix")
    %test:arg("htmlProfile", "edirom-header")
    %test:assertXPath("//Q{http://www.w3.org/1999/xhtml}div[@class='teiHeader']")
    :)
    (: get the help by resource=help :)
    %test:arg("resource", "help_en")
    %test:arg("ref") %test:arg("start") %test:arg("end")
    %test:arg("lang", "en")
    %test:arg("idPrefix")
    %test:arg("htmlProfile", "edirom-help")
    %test:assertXPath("//Q{http://www.w3.org/1999/xhtml}div[@class='titlePage']")
    (: get the help by URI :)
    %test:arg("resource", "xmldb:exist:///db/apps/Edirom-Online-Backend/help/help_en.xml")
    %test:arg("ref") %test:arg("start") %test:arg("end")
    %test:arg("lang", "en")
    %test:arg("idPrefix")
    %test:arg("htmlProfile", "edirom-help")
    %test:assertXPath("//Q{http://www.w3.org/1999/xhtml}div[@class='titlePage']")
    (: Sample prefix :)
    %test:arg("resource", "xmldb:exist:///db/apps/Edirom-Online-Backend/tests/XQSuite/data/tei-document.xml")
    %test:arg("ref") %test:arg("start") %test:arg("end")
    %test:arg("lang", "en")
    %test:arg("idPrefix", "example_")
    %test:arg("htmlProfile", "edirom-text")
    %test:assertXPath("//Q{http://www.w3.org/1999/xhtml}p[starts-with(@id, 'example_')]")
    function ddt:test-document-html(
        $resource as xs:string,
        $ref as xs:string?,
        $start as xs:string?,
        $end as xs:string?,
        $lang as xs:string?,
        $idPrefix as xs:string?,
        $htmlProfile as xs:string?
    ) as document-node() {
        let $html-parameters := map {
            "lang": if ($lang) then $lang else "de",
            "idPrefix": if ($idPrefix) then $idPrefix else "",
            "htmlProfile": if ($htmlProfile) then $htmlProfile else ""
        }
        let $tree := ""
        let $mediaType := "text/html"
        return
            dts-document:document($resource, $ref, $start, $end, $tree, $mediaType, $html-parameters)
};

declare
    (: retrieve tei page starting in the middle of div :)
    %test:arg("resource", "xmldb:exist:///db/apps/Edirom-Online-Backend/tests/XQSuite/data/tei-document.xml")
    %test:arg("ref", "pb-2")
    %test:arg("start") %test:arg("end")
    %test:arg("tree", "paginationStructure")
    %test:arg("mediaType", "application/xml")
    %test:arg("lang", "de")
    %test:assertEmpty
    function ddt:test-document-elements-not-in-tei-page(
        $resource as xs:string,
        $ref as xs:string?,
        $start as xs:string?,
        $end as xs:string?,
        $tree as xs:string?,
        $mediaType as xs:string?,
        $lang as xs:string?
    ) { 
        let $html-parameters := map {
            "lang": if ($lang) then $lang else "de",
            "idPrefix": ""
        }
        let $document :=
            dts-document:document($resource, $ref, $start, $end, $tree, $mediaType, $html-parameters)
        return ($document//tei:p[@xml:id = "not-in-p2-1"], $document//tei:p[@xml:id = "not-in-p2-2"])
    };

declare
    (: retrieve tei page starting in the middle of div :)
    %test:arg("resource", "xmldb:exist:///db/apps/Edirom-Online-Backend/tests/XQSuite/data/tei-document.xml")
    %test:arg("ref")
    %test:arg("start", "pb-2")
    %test:arg("end", "pb-3")
    %test:arg("tree", "paginationStructure")
    %test:arg("mediaType", "application/xml")
    %test:arg("lang", "de")
    %test:assertEmpty
    function ddt:test-document-elements-not-in-tei-page-range(
        $resource as xs:string,
        $ref as xs:string?,
        $start as xs:string?,
        $end as xs:string?,
        $tree as xs:string?,
        $mediaType as xs:string?,
        $lang as xs:string?
    ) { 
        let $html-parameters := map {
            "lang": if ($lang) then $lang else "de",
            "idPrefix": ""
        }
        let $document :=
            dts-document:document($resource, $ref, $start, $end, $tree, $mediaType, $html-parameters)
        return $document//tei:p[@xml:id = "not-in-p2-1"]
    };

declare
    (: Edirom Text profile :)
    %test:arg("htmlProfile", "edirom-text")
    %test:assertTrue
    (: Edirom Help profile :)
    %test:arg("htmlProfile", "edirom-help")
    %test:assertTrue
    (: Edirom Header profile :)
    (: TODO: once the teiBody2HTML.xsl stylesheet is reactivated
    %test:arg("htmlProfile", "edirom-header")
    %test:assertTrue
    :)
    function ddt:test-document-html-htmlProfile(
        $htmlProfile as xs:string
    ) {
        let $resource := "xmldb:exist:///db/apps/Edirom-Online-Backend/tests/XQSuite/data/tei-document.xml"
        let $ref := ""
        let $start := ""
        let $end := ""
        let $tree := "paginationStructure"
        let $mediaType := "text/html"
        let $html-parameters := map {
            "lang": "de",
            "idPrefix": "",
            "htmlProfile": $htmlProfile
        }
        let $document :=
            dts-document:document($resource, $ref, $start, $end, $tree, $mediaType, $html-parameters)
        let $header-div4 := $document//xhtml:section[@id="test-div-4"]//xhtml:h1
        let $header-div4-in-toc := $document//xhtml:li/xhtml:a[@title="I am the only paragraph in the fourth div that does not have a heading."]
        let $toc := $document//xhtml:ul[@class="toc toc_body"]
        let $headingNumbers := $document//xhtml:span[@class="headingNumber"]
        let $headingNumbersInTOC := $document//xhtml:ul[@class="toc toc_body"]//xhtml:span[@class="headingNumber"]
        let $footnote := $document//xhtml:div[@id="note-1"]
        return
            if ($htmlProfile eq "edirom-text") then
                (: autoHead is false :)
                empty($header-div4)
                and empty($header-div4-in-toc)
                (: autoToc is false :)
                and empty($toc)
                (: numberHeading is false :)
                and empty($headingNumbers)
                and empty($headingNumbersInTOC)
                (:footnoteBackLink is true :)
                and exists($footnote//xhtml:a[@class="link_return"])
            else if ($htmlProfile eq "edirom-help") then
                (: autoHead is false :)
                empty($header-div4-in-toc)
                (: autoToc is true :)
                and exists($toc)
                (: tocDepth is 1 :)
                and exists($toc//xhtml:a[@class='toc toc_0'])
                and exists($toc//xhtml:a[@title='This is the header of the first div'])
                and exists($toc//xhtml:a[@class='toc toc_1'])
                and exists($toc//xhtml:a[@title='This is the header of the nested div (inside the first div)'])
                (: footnoteBackLink is false :)
                and empty($footnote//xhtml:a[@class="link_return"])
                (: numberHeading is true :)
                and exists($headingNumbers)
                and exists($headingNumbersInTOC)
            else
                false
    };

declare
    %test:assertTrue
    function ddt:test-document-tei-to-html-edirom-text-profile-parameters() {
        let $parameters := dts-document:htmlProfileParameters("edirom-text")
        return
            count($parameters) eq 4
            and $parameters[attribute(name) = "footnoteBackLink"]/attribute(value) eq "true"
            and $parameters[attribute(name) = "autoHead"]/attribute(value) eq "false"
            and $parameters[attribute(name) = "autoToc"]/attribute(value) eq "false"
            and $parameters[attribute(name) = "numberHeadings"]/attribute(value) eq "false"
    };

declare
    %test:assertTrue
    function ddt:test-document-tei-to-html-edirom-help-profile-parameters() {
        let $parameters := dts-document:htmlProfileParameters("edirom-help")
        return
            count($parameters) eq 1
            and $parameters[attribute(name) = "tocDepth"]/attribute(value) eq "1"
    };

declare
    %test:assertError("errors:InvalidParametersError")
    function ddt:test-document-tei-to-html-unsupported-profile-raises-error() {
        dts-document:htmlProfileParameters("unknown-profile")
    };

(: Tests with json media type :)

declare
    %test:assertTrue
    function ddt:test-wrappedMEIToMap-resolves-references-and-arrays() as xs:boolean {
        let $xml := <root xmlns:dts="https://w3id.org/dts/api#">
                <dts:wrapper>
                    <parent xml:id="p1" facs="#linked">
                        <child>one</child>
                        <child>two</child>
                    </parent>
                </dts:wrapper>
                <linked xml:id="linked">
                    <name>LinkedName</name>
                </linked>
            </root>
        (:
        map {
            "parent": map {
                "child": ["one","two"],
                "facs": map {
                    "linkedId": "linked",
                    "name": "LinkedName"
                },
                "parentId": "p1"
            }
        }
        :)
        let $processed := dts-document:processForJSON($xml, true(), QName("", "facs"))
        let $m := dts-document:wrappedMEIToMap($processed)
        let $parent := map:get($m, "parent")(1)
        let $parentId := map:get($parent, "parentId")
        let $children := map:get($parent, "child")
        let $refMap := map:get($parent, "facs")(1)
        return
            map:contains($m, "parent")
            and $parentId = "p1"
            and map:get($children(1), "text") = "one"
            and map:get($children(2), "text") = "two"
            and map:get(map:get($refMap, "name")(1), "text") = "LinkedName"
};

declare
    %test:assertTrue
    function ddt:test-wrappedMEIToMap-resolves-multiple-facs-references-as-array() as xs:boolean {
        let $xml := <root xmlns:dts="https://w3id.org/dts/api#">
                <dts:wrapper>
                    <measure xml:id="m1" facs="#linked1 #linked2">
                        <name>Measure1</name>
                    </measure>
                </dts:wrapper>
                <linked1 xml:id="linked1">
                    <title>LinkOne</title>
                </linked1>
                <linked2 xml:id="linked2">
                    <title>LinkTwo</title>
                </linked2>
            </root>
        let $processed := dts-document:processForJSON($xml, true(), QName("", "facs"))
        let $m := dts-document:wrappedMEIToMap($processed)
        let $measure := map:get($m, "measure")(1)
        let $facs := map:get($measure, "facs")
        return
            map:contains($m, "measure")
            and array:size($facs) = 2
            and map:get(map:get($facs(1), "title")(1), "text") = "LinkOne"
            and map:get(map:get($facs(2), "title")(1), "text") = "LinkTwo"
};

declare
    %test:assertTrue
    function ddt:test-wrappedMEIToMap-preserves-missing-facs() as xs:boolean {
        let $xml := <root xmlns:dts="https://w3id.org/dts/api#">
                <dts:wrapper>
                    <measure xml:id="m1" facs="#linked1 #missing #linked2">
                        <name>Measure1</name>
                    </measure>
                </dts:wrapper>
                <linked1 xml:id="linked1">
                    <title>LinkOne</title>
                </linked1>
                <linked2 xml:id="linked2">
                    <title>LinkTwo</title>
                </linked2>
            </root>
        let $processed := dts-document:processForJSON($xml, true(), QName("", "facs"))
        let $m := dts-document:wrappedMEIToMap($processed)
        let $measure := map:get($m, "measure")(1)
        let $facs := map:get($measure, "facs")
        return
            map:contains($m, "measure")
            and array:size($facs) = 3
            and map:get(map:get($facs(1), "title")(1), "text") = "LinkOne"
            and map:get($facs(2), "text") = "#missing"
            and map:get(map:get($facs(3), "title")(1), "text") = "LinkTwo"
};

declare
    %test:assertTrue
    function ddt:test-wrappedMEIToMap-preserves-references-not-to-be-followed() as xs:boolean {
        let $xml := <root xmlns:dts="https://w3id.org/dts/api#">
                <dts:wrapper>
                    <measure measureId="m1" refNotToFollow="#linked1 #linked2">
                        <name>Measure1</name>
                    </measure>
                </dts:wrapper>
                <linked1 linked1Id="linked1">
                    <title>LinkOne</title>
                </linked1>
                <linked2 linked2Id="linked2">
                    <title>LinkTwo</title>
                </linked2>
            </root>
        let $m := dts-document:wrappedMEIToMap($xml)
        let $measure := map:get($m, "measure")(1)
        let $refNotToFollow := map:get($measure, "refNotToFollow")
        return
            map:contains($m, "measure")
            and $refNotToFollow = "#linked1 #linked2"
};

declare
    %test:assertTrue
    function ddt:test-wrappedMEIToMap-single-text-child-uses-text-property() as xs:boolean {
        let $xml := <root xmlns:dts="https://w3id.org/dts/api#">
                <dts:wrapper>
                    <item itemId="i1">
                        <value>only</value>
                    </item>
                </dts:wrapper>
            </root>
        (:
        map {
            "item": map {
                "itemId": "i1",
                "value": [{"text": "only"}]
            }
        }
        :)
        let $m := dts-document:wrappedMEIToMap($xml)
        let $item := map:get($m, "item")(1)
        let $values := map:get($item, "value")
        return
            map:get($item, "itemId") = "i1"
            and map:get($values(1), "text") = "only"
};

declare
    %test:assertTrue
    function ddt:test-wrappedMEIToMap-preserves-text-with-attributes-and-children() as xs:boolean {
        let $xml := <root xmlns:dts="https://w3id.org/dts/api#">
                <dts:wrapper>
                    <item type="example">Before <emph>middle</emph> after</item>
                </dts:wrapper>
            </root>
        let $m := dts-document:wrappedMEIToMap($xml)
        let $item := map:get($m, "item")(1)
        let $emphases := map:get($item, "emph")
        return
            map:get($item, "type") = "example"
            and map:get($item, "text") = "Before  after"
            and map:get($emphases(1), "text") = "middle"
};

declare
    %test:assertTrue
    function ddt:test-wrappedMEIToMap-omits-whitespace-only-text() as xs:boolean {
        let $xml := <root xmlns:dts="https://w3id.org/dts/api#">
                <dts:wrapper>
                    <item>
                        <child/>
                    </item>
                </dts:wrapper>
            </root>
        let $m := dts-document:wrappedMEIToMap($xml)
        let $item := map:get($m, "item")(1)
        return
            not(map:contains($item, "text"))
};

declare
    (: retrieve a specific zone by ref :)
    %test:arg("resource", "xmldb:exist:///db/apps/Edirom-Online-Backend/tests/XQSuite/data/mei-facsimile.xml")
    %test:arg("ref", "zone_bar-2001")
    %test:arg("expectedUlx", "478")
    %test:arg("expectedSurfaceId", "facsimile-2001002")
    %test:assertTrue
    (: retrieve a specific zone by ref :)
    %test:arg("resource", "xmldb:exist:///db/apps/Edirom-Online-Backend/tests/XQSuite/data/mei-facsimile-parts.xml")
    %test:arg("ref", "zone_barGroup-1083")
    %test:arg("expectedUlx", "820")
    %test:arg("expectedSurfaceId", "facsimile-3713")
    %test:assertTrue
    function ddt:test-document-json-zone-ref(
        $resource as xs:string,
        $ref as xs:string?,
        $expectedUlx as xs:string?,
        $expectedSurfaceId as xs:string?
    ) { 
        let $html-parameters := map {
            "lang": "de",
            "idPrefix": ""
        }
        let $mediaType := "application/json"
        let $tree := "paginationStructure"
        let $response := dts-document:document($resource, $ref, (), (), $tree, $mediaType, $html-parameters)
        let $zone := $response?zone(1)
        let $zoneId := $zone?zoneId
        let $ulx := $zone?ulx
        let $surfaceId := $zone?surfaceId
        return
            map:contains($response, "zone")
            and $zoneId = $ref
            and $ulx = $expectedUlx
            and $surfaceId = $expectedSurfaceId
            (: response structure :)
            and map:contains($zone, "measure")
            and map:contains($zone, "ulx")
            and map:contains($zone, "uly")
            and map:contains($zone, "lrx")
            and map:contains($zone, "lry")
            and map:contains($zone, "surfaceId")
            and map:contains($zone, "zoneId")
            and map:contains($zone, "zoneType")
            and map:contains($zone, "target")
            and map:contains($zone, "height")
            and map:contains($zone, "width")
};

declare
    (: retrieve a range of zones by start and end :)
    %test:arg("resource", "xmldb:exist:///db/apps/Edirom-Online-Backend/tests/XQSuite/data/mei-facsimile.xml")
    %test:arg("start", "zone_bar-20013")
    %test:arg("end", "zone_bar-20015")
    %test:arg("expectedZoneCount", 3)
    %test:arg("expectedUlxStart", "2926")
    %test:arg("expectedSurfaceId", "facsimile-2001002")
    %test:assertTrue
    function ddt:test-document-json-zone-start-end(
        $resource as xs:string,
        $start as xs:string?,
        $end as xs:string?,
        $expectedZoneCount as xs:integer?,
        $expectedUlxStart as xs:string?,
        $expectedSurfaceId as xs:string?
    ) { 
        let $html-parameters := map {
            "lang": "de",
            "idPrefix": ""
        }
        let $tree := "paginationStructure"
        let $mediaType := "application/json"
        let $response := dts-document:document($resource, (), $start, $end, $tree, $mediaType, $html-parameters)
        let $zoneIdFirst := $response?zone(1)?zoneId
        let $zoneCount := array:size($response?zone)
        let $zoneIdLast := $response?zone($zoneCount)?zoneId
        let $ulxStart := $response?zone(1)?ulx
        let $surfaceIdStart := $response?zone(1)?surfaceId
        let $surfaceIdEnd := $response?zone($zoneCount)?surfaceId
        return
            map:contains($response, "zone")
            and ($zoneIdFirst eq $start)
            and ($zoneIdLast eq $end)
            and ($ulxStart eq $expectedUlxStart)
            and ($surfaceIdStart eq $expectedSurfaceId)
            and ($surfaceIdEnd eq $expectedSurfaceId)
            and ($zoneCount eq $expectedZoneCount)
            (: response structure :)
            and map:contains($response?zone(1), "measure")
            and map:contains($response?zone(1), "ulx")
            and map:contains($response?zone(1), "uly")
            and map:contains($response?zone(1), "lrx")
            and map:contains($response?zone(1), "lry")
            and map:contains($response?zone(1), "surfaceId")
            and map:contains($response?zone(1), "zoneId")
            and map:contains($response?zone(1), "zoneType")
            and map:contains($response?zone(1), "target")
            and map:contains($response?zone(1), "height")
            and map:contains($response?zone(1), "width")
            and map:contains($response?zone($zoneCount), "measure")
            and map:contains($response?zone($zoneCount), "ulx")
            and map:contains($response?zone($zoneCount), "uly")
            and map:contains($response?zone($zoneCount), "lrx")
            and map:contains($response?zone($zoneCount), "lry")
            and map:contains($response?zone($zoneCount), "surfaceId")
            and map:contains($response?zone($zoneCount), "zoneId")
            and map:contains($response?zone($zoneCount), "zoneType")
            and map:contains($response?zone($zoneCount), "target")
            and map:contains($response?zone($zoneCount), "height")
            and map:contains($response?zone($zoneCount), "width")

};

declare
    (: retrieve a specific surface by ref :)
    %test:arg("resource", "xmldb:exist:///db/apps/Edirom-Online-Backend/tests/XQSuite/data/mei-facsimile.xml")
    %test:arg("ref", "facsimile-2001003")
    %test:arg("expectedUlxFirst", "296")
    %test:arg("expectedWidth", "3950")
    %test:assertTrue
    function ddt:test-document-json-surface-ref(
        $resource as xs:string,
        $ref as xs:string?,
        $expectedUlxFirst as xs:string?,
        $expectedWidth as xs:string?
    ) { 
        let $html-parameters := map {
            "lang": "de",
            "idPrefix": ""
        }
        let $mediaType := "application/json"
        let $tree := "paginationStructure"
        let $response := dts-document:document($resource, $ref, (), (), $tree, $mediaType, $html-parameters)
        let $surface := $response?surface(1)
        let $zoneFirst := $surface?zone(1)
        let $zoneSecond := $surface?zone(2)
        let $ulx := $zoneFirst?ulx
        let $surfaceId := $zoneFirst?surfaceId
        let $widthFirst := $zoneFirst?width
        let $widthSecond := $zoneSecond?width
        return
            map:contains($response, "surface")
            and $ulx = $expectedUlxFirst
            and $surfaceId = $ref
            and $widthFirst = $expectedWidth
            and $widthSecond = $expectedWidth
            (: response structure :)
            and map:contains($surface, "zone")
            and map:contains($zoneFirst, "measure")
            and map:contains($zoneFirst, "target")


};

declare
    (: retrieve a range of surfaces by start and end :)
    %test:arg("resource", "xmldb:exist:///db/apps/Edirom-Online-Backend/tests/XQSuite/data/mei-facsimile.xml")
    %test:arg("start", "facsimile-2001003")
    %test:arg("end", "facsimile-2001004")
    %test:arg("expectedSurfaceCount", 2)
    %test:arg("expectedUlxFirst", "296")
    %test:arg("expectedWidthFirst", "3950")
    %test:assertTrue
    function ddt:test-document-json-surface-start-end(
        $resource as xs:string,
        $start as xs:string?,
        $end as xs:string?,
        $expectedSurfaceCount as xs:integer?,
        $expectedUlxFirst as xs:string?,
        $expectedWidthFirst as xs:string?
    ) { 
        let $html-parameters := map {
            "lang": "de",
            "idPrefix": ""
        }
        let $tree := "paginationStructure"
        let $mediaType := "application/json"
        let $response := dts-document:document($resource, (), $start, $end, $tree, $mediaType, $html-parameters)
        let $zoneFirst := $response?surface(1)?zone(1)
        let $zoneLast := $response?surface(array:size($response?surface))?zone(1)
        let $ulx := $zoneFirst?ulx
        let $surfaceIdFirst := $zoneFirst?surfaceId
        let $surfaceIdLast := $zoneLast?surfaceId
        let $widthFirst := $zoneFirst?width
        return
            map:contains($response, "surface")
            and $ulx = $expectedUlxFirst
            and $surfaceIdFirst = $start
            and $surfaceIdLast = $end
            and $widthFirst = $expectedWidthFirst
            and (array:size($response?surface) eq $expectedSurfaceCount)
            (: response structure :)
            and map:contains($response?surface(1), "zone")
            and map:contains($response?surface(1)?zone(1), "measure")
            and map:contains($response?surface(1)?zone(1), "target")

};

declare
    (: retrieve a specific measure by ref :)
    %test:arg("resource", "xmldb:exist:///db/apps/Edirom-Online-Backend/tests/XQSuite/data/mei-facsimile.xml")
    %test:arg("ref", "bar-2003")
    %test:arg("expectedMdivId", "part-1")
    %test:arg("expectedZoneId", "zone_bar-2003")
    %test:arg("expectedSurfaceId", "facsimile-2001002")
    %test:arg("expectedUlx", "1332")
    %test:assertTrue
    (: retrieve a specific measure by ref (parts file):)
    %test:arg("resource", "xmldb:exist:///db/apps/Edirom-Online-Backend/tests/XQSuite/data/mei-facsimile-parts.xml")
    %test:arg("ref", "bar-1269")
    %test:arg("expectedMdivId", "x2eb1eec1-5284-429c-9a80-c16ebe4e8233")
    %test:arg("expectedZoneId", "zone_bar-1269")
    %test:arg("expectedSurfaceId", "facsimile-3715")
    %test:arg("expectedUlx", "2194")
    %test:assertTrue
    function ddt:test-document-json-measure-ref(
        $resource as xs:string,
        $ref as xs:string?,
        $expectedMdivId as xs:string?,
        $expectedZoneId as xs:string?,
        $expectedSurfaceId as xs:string?,
        $expectedUlx as xs:string?
    ) { 
        let $html-parameters := map {
            "lang": "de",
            "idPrefix": ""
        }
        let $mediaType := "application/json"
        let $tree := "musicStructure"
        let $response := dts-document:document($resource, $ref, (), (), $tree, $mediaType, $html-parameters)
        let $measure := $response?measure(1)
        let $mdivId := $measure?mdivId
        let $facsimile := $measure?facs(1)
        let $zoneId := $facsimile?zoneId
        let $surfaceId := $facsimile?surfaceId
        let $ulx := $facsimile?ulx
        return
            map:contains($response, "measure")
            and $mdivId = $expectedMdivId
            and $zoneId = $expectedZoneId
            and $surfaceId = $expectedSurfaceId
            and $ulx = $expectedUlx
            (: response structure :)
            and map:contains($measure, "measureId")
            and map:contains($measure, "facs")
            and map:contains($measure, "mdivId")
            and map:contains($facsimile, "zoneId")
            and map:contains($facsimile, "surfaceId")
            and map:contains($facsimile, "target")
            and map:contains($facsimile, "ulx")

};

declare
    (: retrieve a range of measures by start and end :)
    %test:arg("resource", "xmldb:exist:///db/apps/Edirom-Online-Backend/tests/XQSuite/data/mei-facsimile.xml")
    %test:arg("start", "bar-20010")
    %test:arg("end", "bar-20013")
    %test:arg("expectedMeasureCount", 4)
    %test:arg("expectedUlxFirst", "2458")
    %test:arg("expectedUlxLast", "2926")
    %test:assertTrue
    (: retrieve a range of measures by start and end (parts file):)
    %test:arg("resource", "xmldb:exist:///db/apps/Edirom-Online-Backend/tests/XQSuite/data/mei-facsimile-parts.xml")
    %test:arg("start", "bar-5021")
    %test:arg("end", "bar-5025")
    %test:arg("expectedMeasureCount", 5)
    %test:arg("expectedUlxFirst", "458")
    %test:arg("expectedUlxLast", "1700")
    %test:assertTrue
    function ddt:test-document-json-measure-start-end(
        $resource as xs:string,
        $start as xs:string?,
        $end as xs:string?,
        $expectedMeasureCount as xs:integer?,
        $expectedUlxFirst as xs:string?,
        $expectedUlxLast as xs:string?
    ) { 
        let $html-parameters := map {
            "lang": "de",
            "idPrefix": ""
        }
        let $tree := "musicStructure"
        let $mediaType := "application/json"
        let $response := dts-document:document($resource, (), $start, $end, $tree, $mediaType, $html-parameters)
        let $measures := $response?measure
        let $measureCount := array:size($measures)
        let $measureFirst := $measures(1)
        let $measureLast := $measures($measureCount)
        let $ulxFirst := $measureFirst?facs(1)?ulx
        let $ulxLast := $measureLast?facs(1)?ulx
        return
            map:contains($response, "measure")
            and $measureCount = $expectedMeasureCount
            and $ulxFirst = $expectedUlxFirst
            and $ulxLast = $expectedUlxLast
            (: response structure :)
            and map:contains($response?measure(1), "measureId")
            and map:contains($response?measure(1), "facs")
            and map:contains($response?measure(1), "mdivId")
            and map:contains($response?measure(1)?facs(1), "zoneId")
            and map:contains($response?measure(1)?facs(1), "surfaceId")
            and map:contains($response?measure(1)?facs(1), "target")
            and map:contains($response?measure(1)?facs(1), "ulx")
};

declare
    %test:arg("resource", "xmldb:exist:///db/apps/Edirom-Online-Backend/tests/XQSuite/data/mei-facsimile.xml")
    %test:arg("tree", "musicStructure")
    %test:assertTrue
    %test:arg("resource", "xmldb:exist:///db/apps/Edirom-Online-Backend/tests/XQSuite/data/mei-facsimile.xml")
    %test:arg("tree", "paginationStructure")
    %test:assertTrue
    function ddt:test-document-json-full-document(
        $resource as xs:string,
        $tree as xs:string?
    ) as xs:boolean {
        let $html-parameters := map {
            "lang": "de",
            "idPrefix": ""
        }
        let $mediaType := "application/json"
        let $response := dts-document:document($resource, (), (), (), $tree, $mediaType, $html-parameters)
        let $checkResponseStructure := 
            if ($tree eq "musicStructure") then
                map:contains($response, "mdiv")
                and map:contains($response?mdiv(1)?score(1)?section(1), "measure")
                and map:contains($response?mdiv(1)?score(1)?section(1)?measure(1), "measureId")
                and map:contains($response?mdiv(1)?score(1)?section(1)?measure(1), "facs")
                and map:contains($response?mdiv(1)?score(1)?section(1)?measure(1), "mdivId")
                and map:contains($response?mdiv(1)?score(1)?section(1)?measure(1)?facs(1), "zoneId")
                and map:contains($response?mdiv(1)?score(1)?section(1)?measure(1)?facs(1), "surfaceId")
                and map:contains($response?mdiv(1)?score(1)?section(1)?measure(1)?facs(1), "target")
                and map:contains($response?mdiv(1)?score(1)?section(1)?measure(1)?facs(1), "ulx")
            else if ($tree eq "paginationStructure") then
                map:contains($response, "surface")
                and map:contains($response?surface(3), "zone")
                and map:contains($response?surface(3), "surfaceId")
                and map:contains($response?surface(3)?zone(1), "measure")
                and map:contains($response?surface(3)?zone(1), "ulx")
            else
                false
        return
            $response instance of map(*)
            and map:size($response) gt 0
            and $checkResponseStructure
};
