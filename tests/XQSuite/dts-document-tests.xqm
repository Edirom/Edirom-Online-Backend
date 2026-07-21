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
    (: retrieve meiHead by ref :)
    %test:arg("resource", "xmldb:exist:///db/apps/Edirom-Online-Backend/tests/XQSuite/data/mei-score.xml")
    %test:arg("ref", "meiHead")
    %test:arg("start") %test:arg("end")
    %test:arg("tree")
    %test:arg("mediaType", "application/xml")
    %test:arg("lang")
    %test:assertXPath("/Q{http://www.music-encoding.org/ns/mei}mei//Q{https://w3id.org/dts/api#}wrapper/Q{http://www.music-encoding.org/ns/mei}meiHead")
    (: retrieve meiHead by ref as html :)
    (: TODO Implement this feature
    %test:arg("resource", "xmldb:exist:///db/apps/Edirom-Online-Backend/tests/XQSuite/data/mei-score.xml")
    %test:arg("ref", "meiHead")
    %test:arg("start") %test:arg("end")
    %test:arg("tree")
    %test:arg("mediaType", "text/html")
    %test:arg("lang")
    %test:assertXPath("/Q{http://www.w3.org/1999/xhtml}div[@class='meiHead']") (: TODO check this condition :)
    :)
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
    (: retrieve teiHeader by ref as html :)
    (: TODO: implement this feature
    %test:arg("resource", "xmldb:exist:///db/apps/Edirom-Online-Backend/tests/XQSuite/data/tei-document.xml")
    %test:arg("ref", "teiHeader")
    %test:arg("start") %test:arg("end") %test:arg("tree")
    %test:arg("mediaType", "text/html")
    %test:arg("lang")
    %test:assertXPath("//Q{http://www.w3.org/1999/xhtml}h1") (: TODO check this condition :)
    :)
    (: get the help by resource=help :)
    %test:arg("resource", "help_en")
    %test:arg("ref") %test:arg("start") %test:arg("end") %test:arg("tree")
    %test:arg("mediaType", "text/html")
    %test:arg("lang", "en")
    %test:assertXPath("//Q{http://www.w3.org/1999/xhtml}div[@class='titlePage']")
    (: get the help by URI :)
    %test:arg("resource", "xmldb:exist:///db/apps/Edirom-Online-Backend/help/help_en.xml")
    %test:arg("ref") %test:arg("start") %test:arg("end") %test:arg("tree")
    %test:arg("mediaType", "text/html")
    %test:arg("lang")
    %test:assertXPath("//Q{http://www.w3.org/1999/xhtml}div[@class='titlePage']")
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
    function ddt:test-document(
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

(: TODO test with differen html parameters, e.g. idPrefix :)

declare
    (: Sample prefix :)
    %test:arg("idPrefix", "example_")
    %test:assertXPath("//Q{http://www.w3.org/1999/xhtml}p[starts-with(@id, 'example_')]")
    function ddt:test-document-tei-to-html-idPrefix(
        $idPrefix as xs:string
    ) {
        let $resource := "xmldb:exist:///db/apps/Edirom-Online-Backend/tests/XQSuite/data/tei-document.xml"
        let $ref := ""
        let $start := ""
        let $end := ""
        let $tree := "paginationStructure"
        let $mediaType := "text/html"
        let $html-parameters := map {
            "lang": "de",
            "idPrefix": $idPrefix
        }
        let $document :=
            dts-document:document($resource, $ref, $start, $end, $tree, $mediaType, $html-parameters)
        return
            $document
    };

declare
    (: With Header :)
    %test:arg("autoHead", "true")
    %test:assertTrue
    (: Without Header :)
    %test:arg("autoHead", "false")
    %test:assertTrue
    function ddt:test-document-tei-to-html-autoHead(
        $autoHead as xs:string
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
            "autoToc": "true",
            "autoHead": $autoHead
        }
        let $document :=
            dts-document:document($resource, $ref, $start, $end, $tree, $mediaType, $html-parameters)
        let $header-div4 := $document//xhtml:section[@id="test-div-4"]//xhtml:h1
        let $header-div4-in-toc := $document//xhtml:li/xhtml:a[@title="I am the only paragraph in the fourth div that does not have a heading."]
        return
            if ($autoHead eq "true") then
                exists($header-div4)
                and exists($header-div4-in-toc)
            else
                empty($header-div4)
                and empty($header-div4-in-toc)
    };

declare
    (: With TOC :)
    %test:arg("autoToc", "true")
    %test:assertTrue
    (: Without TOC :)
    %test:arg("autoToc", "false")
    %test:assertTrue
    function ddt:test-document-tei-to-html-autoToc(
        $autoToc as xs:string
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
            "autoToc": $autoToc
        }
        let $document :=
            dts-document:document($resource, $ref, $start, $end, $tree, $mediaType, $html-parameters)
        let $toc := $document//xhtml:ul[@class="toc toc_body"]
        return
            if ($autoToc eq "true") then
                exists($toc)
            else
                empty($toc)
    };

declare
    (: Depth 0 :)
    %test:arg("tocDepth", 0)
    %test:assertTrue
    (: Depth 1 :)
    %test:arg("tocDepth", 1)
    %test:assertTrue
    function ddt:test-document-tei-to-html-tocDepth(
        $tocDepth as xs:integer
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
            "autoToc": "true",
            "tocDepth": $tocDepth
        }
        let $document :=
            dts-document:document($resource, $ref, $start, $end, $tree, $mediaType, $html-parameters)
        let $toc := $document//xhtml:ul[@class="toc toc_body"]
        return
            if ($tocDepth eq 0) then
                exists($toc//xhtml:a[@class='toc toc_0'])
                and exists($toc//xhtml:a[@title='This is the header of the first div'])
                and empty($toc//xhtml:a[@class='toc toc_1'])
                and empty($toc//xhtml:a[@title='This is the header of the nested div (inside the first div)'])
            else if ($tocDepth eq 1) then
                exists($toc//xhtml:a[@class='toc toc_0'])
                and exists($toc//xhtml:a[@title='This is the header of the first div'])
                and exists($toc//xhtml:a[@class='toc toc_1'])
                and exists($toc//xhtml:a[@title='This is the header of the nested div (inside the first div)'])
            else
                false
    };

declare
    (: With footnote backlink :)
    %test:arg("footnoteBackLink", "true")
    %test:assertTrue
    (: Without footnote backlink :)
    %test:arg("footnoteBackLink", "false")
    %test:assertTrue
    function ddt:test-document-tei-to-html-footnoteBackLink(
        $footnoteBackLink as xs:string
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
            "footnoteBackLink": $footnoteBackLink
        }
        let $document :=
            dts-document:document($resource, $ref, $start, $end, $tree, $mediaType, $html-parameters)
        let $footnote := $document//xhtml:div[@id="note-1"]
        return
            if ($footnoteBackLink eq "true") then
                exists($footnote//xhtml:a[@class="link_return"])
            else
                empty($footnote//xhtml:a[@class="link_return"])
    };

declare
    (: Numbered headings :)
    %test:arg("numberHeadings", "true")
    %test:assertTrue
    (: Unnumbered headings :)
    %test:arg("numberHeadings", "false")
    %test:assertTrue
    function ddt:test-document-tei-to-html-numberHeadings(
        $numberHeadings as xs:string
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
            "autoToc": "true",
            "numberHeadings": $numberHeadings
        }
        let $document :=
            dts-document:document($resource, $ref, $start, $end, $tree, $mediaType, $html-parameters)
        let $headingNumbers := $document//xhtml:span[@class="headingNumber"]
        let $headingNumbersInTOC := $document//xhtml:ul[@class="toc toc_body"]//xhtml:span[@class="headingNumber"]
        return
            if ($numberHeadings eq "true") then
                exists($headingNumbers)
                and exists($headingNumbersInTOC)
            else
                empty($headingNumbers)
                and empty($headingNumbersInTOC)
    };

(: TODO tests with json media type :)

