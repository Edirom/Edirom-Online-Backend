xquery version "3.1";

module namespace dct = "http://www.edirom.de/xquery/xqsuite/dts-common-tests";

import module namespace dts-common = "http://www.edirom.de/api/dts-common" at "xmldb:exist:///db/apps/Edirom-Online-Backend/data/xqm/dts-common.xqm";

declare namespace test = "http://exist-db.org/xquery/xqsuite";


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
