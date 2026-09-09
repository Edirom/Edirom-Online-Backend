xquery version "3.1";

module namespace dct = "http://www.edirom.de/xquery/xqsuite/dts-common-tests";

import module namespace dts-common = "http://www.edirom.de/api/dts-common" at "xmldb:exist:///db/apps/Edirom-Online-Backend/data/xqm/dts-common.xqm";

declare namespace test = "http://exist-db.org/xquery/xqsuite";

declare variable $dct:openAPI := json-doc("xmldb:exist:///db/apps/Edirom-Online-Backend/data/api/api.json");

declare function dct:alternativeCitationTree(
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


declare %private function dct:uriTemplateParameterNames($uri as xs:string) as xs:string* {
    tokenize(substring-before(substring-after($uri, "{?"), "}"), ",")
};

declare %private function dct:openAPIQueryParameterNames($path as xs:string) as xs:string* {
    for $parameter in $dct:openAPI?paths?($path)?get?parameters?*
    where $parameter?in eq "query"
    return xs:string($parameter?name)
};


declare
    %test:assertEquals("https://example.org/api/collection/{?id,page,nav}")
    function dct:test-buildCollectionURI-template() as xs:string {
        dts-common:buildCollectionURI("https://example.org", (), (), ())
};

declare
    %test:assertEquals("https://example.org/api/collection/?id=resource{&amp;page,nav}")
    function dct:test-buildCollectionURI-assignment() as xs:string {
        dts-common:buildCollectionURI("https://example.org", "resource", (), ())
};

declare
    %test:assertEquals("https://example.org/api/navigation/{?resource,ref,start,end,down,tree,page}")
    function dct:test-buildNavigationURI-template() as xs:string {
        dts-common:buildNavigationURI("https://example.org", (), (), (), (), (), (), ())
};

declare
    %test:assertEquals("https://example.org/api/navigation/?resource=resource&amp;tree=main{&amp;ref,start,end,down,page}")
    function dct:test-buildNavigationURI-assignments() as xs:string {
        dts-common:buildNavigationURI("https://example.org", "resource", (), (), (), (), "main", ())
};

declare
    %test:assertEquals("https://example.org/api/document/{?resource,ref,start,end,tree,mediaType,lang,idPrefix,htmlProfile}")
    function dct:test-buildDocumentURI-template() as xs:string {
        dts-common:buildDocumentURI("https://example.org", (), (), (), (), (), (), (), (), ())
};

declare
    %test:assertEquals("https://example.org/api/document/?resource=resource&amp;ref=1&amp;mediaType=text/html{&amp;start,end,tree,lang,idPrefix,htmlProfile}")
    function dct:test-buildDocumentURI-assignments() as xs:string {
        dts-common:buildDocumentURI("https://example.org", "resource", "1", (), (), (), "text/html", (), (), ())
};

declare
    %test:assertEquals("movement-1")
    function dct:test-selectBasedOnCiteStructure-selects-by-xml-id() as xs:string {
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
        let $citationTree := dct:alternativeCitationTree("musicStructure")
        let $selected := dts-common:selectBasedOnCiteStructure($document, "movement-1", $citationTree)
        return string($selected/@xml:id)
};

declare
    %test:assertEquals("42")
    function dct:test-selectBasedOnCiteStructure-selects-by-n() as xs:string {
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
        let $citationTree := dct:alternativeCitationTree("musicStructure")
        let $selected := dts-common:selectBasedOnCiteStructure($document, "42", $citationTree)
        return string($selected/@n)
};

declare
    %test:assertTrue
    function dct:test-selectBasedOnCiteStructure-no-match() as xs:boolean {
        let $document := document {
            <mei xmlns="http://www.music-encoding.org/ns/mei">
                <measure n="42"/>
                <note xml:id="note-1"/>
            </mei>
        }
        let $citationTree := dct:alternativeCitationTree("musicStructure")
        return
            empty(dts-common:selectBasedOnCiteStructure($document, (), $citationTree))
            and empty(dts-common:selectBasedOnCiteStructure($document, "missing", $citationTree))
            and empty(dts-common:selectBasedOnCiteStructure($document, "note-1", $citationTree))
};

declare
    %test:assertTrue
    function dct:test-getCiteStructureForNode-root-and-descendant() as xs:boolean {
        let $citationTree := dct:alternativeCitationTree("musicStructure")
        let $movement := <mdiv xmlns="http://www.music-encoding.org/ns/mei" xml:id="movement-1"/>
        let $measure := <measure xmlns="http://www.music-encoding.org/ns/mei" n="42"/>
        return
            dts-common:getCiteStructureForNode($movement, $citationTree) is $citationTree
            and dts-common:getCiteStructureForNode($measure, $citationTree) is $citationTree/citeStructure
};

declare
    %test:assertTrue
    function dct:test-getCiteStructureForNode-no-match() as xs:boolean {
        let $citationTree := dct:alternativeCitationTree("musicStructure")
        return
            empty(dts-common:getCiteStructureForNode(<measure/>, $citationTree))
            and empty(dts-common:getCiteStructureForNode(
                <note xmlns="http://www.music-encoding.org/ns/mei"/>, $citationTree
            ))
            and empty(dts-common:getCiteStructureForNode(<measure/>, ()))
            and empty(dts-common:getCiteStructureForNode(<measure/>, <citeStructure/>))
};

declare
    %test:assertTrue
    function dct:test-getCiteStructureForNode-keeps-all-matches() as xs:boolean {
        let $citationTree :=
            <refsDecl xmlns:mei="http://www.music-encoding.org/ns/mei">
                <citeStructure match="mei:measure" use="@xml:id" unit="MeasureById"/>
                <citeStructure match="mei:measure" use="@n" unit="MeasureByNumber"/>
            </refsDecl>/citeStructure
        let $node := <m:measure xmlns:m="http://www.music-encoding.org/ns/mei" xml:id="measure-1" n="42"/>
        let $result := dts-common:getCiteStructureForNode($node, $citationTree)
        return
            count($result) eq 2
            and $result[1] is $citationTree[1]
            and $result[2] is $citationTree[2]
};

(: TODO: Create openapi specification for the collection endpoint
declare
    %test:assertTrue
    function dct:test-buildCollectionURI-parameters-match-openAPI() as xs:boolean {
        deep-equal(
            dct:uriTemplateParameterNames(dts-common:buildCollectionURI("https://example.org", (), (), ())),
            dct:openAPIQueryParameterNames("/api/collection")
        )
};
:)

declare
    %test:assertTrue
    function dct:test-buildNavigationURI-parameters-match-openAPI() as xs:boolean {
        deep-equal(
            dct:uriTemplateParameterNames(dts-common:buildNavigationURI("https://example.org", (), (), (), (), (), (), ())),
            dct:openAPIQueryParameterNames("/api/navigation")
        )
};

declare
    %test:assertTrue
    function dct:test-buildDocumentURI-parameters-match-openAPI() as xs:boolean {
        deep-equal(
            dct:uriTemplateParameterNames(dts-common:buildDocumentURI("https://example.org", (), (), (), (), (), (), (), (), ())),
            dct:openAPIQueryParameterNames("/api/document")
        )
};
