xquery version "3.1";

module namespace st = "http://www.edirom.de/xquery/xqsuite/source-tests";

import module namespace source = "http://www.edirom.de/xquery/source" at "xmldb:exist:///db/apps/Edirom-Online-Backend/data/xqm/source.xqm";

declare namespace mei="http://www.music-encoding.org/ns/mei";
declare namespace test="http://exist-db.org/xquery/xqsuite";

(: The fixture is addressed by path rather than held as a document, because id() only
 : works on stored documents, not on constructed nodes. :)
declare variable $st:parts-labelled := "xmldb:exist:///db/apps/Edirom-Online-Backend/tests/XQSuite/data/mei-parts-labelled.xml";


(: source:label-or-n ======================================================== :)

declare
    (: @label wins over @n :)
    %test:args("measure_3f9a1c2d-flauto-one")   %test:assertEquals("1")
    (: an alphanumeric @label survives verbatim :)
    %test:args("measure_5b7e4d8a-flauto-two")   %test:assertEquals("2b")
    (: @n is used only where there is no @label :)
    %test:args("measure_7d3b5e0f-score-one")    %test:assertEquals("1")
    function st:test-label-or-n($measureId as xs:string) as xs:string? {
        source:label-or-n(doc($st:parts-labelled)/id($measureId))
};


(: source:get-virtual-measure-id ============================================ :)

declare
    (: the mdiv @xml:id contains underscores and must survive intact :)
    %test:args("measure_3f9a1c2d-flauto-one")   %test:assertEquals("measure_test_mdiv_01_1")
    %test:args("measure_1e4a9b7c-oboe-two")     %test:assertEquals("measure_test_mdiv_01_2b")
    (: built from @n where there is no @label :)
    %test:args("measure_7d3b5e0f-score-one")    %test:assertEquals("measure_test_mdiv_02_1")
    function st:test-get-virtual-measure-id($measureId as xs:string) as xs:string {
        source:get-virtual-measure-id(doc($st:parts-labelled)/id($measureId))
};


(: source:resolve-measure-in-mdiv =========================================== :)

declare
    (: a designation occurring once per part yields one measure per part :)
    %test:args("test_mdiv_01", "1")     %test:assertEquals("2")
    %test:args("test_mdiv_01", "2b")    %test:assertEquals("2")
    (: an mdiv without parts yields a single measure :)
    %test:args("test_mdiv_02", "1")     %test:assertEquals("1")
    (: the lookup is scoped to the mdiv: mdiv 2's designation is not visible in mdiv 1 :)
    %test:args("test_mdiv_01", "99")    %test:assertEquals("0")
    %test:args("no-such-mdiv", "1")     %test:assertEquals("0")
    (: empty arguments resolve to nothing rather than to every measure :)
    %test:args("", "1")                 %test:assertEquals("0")
    %test:args("test_mdiv_01", "")      %test:assertEquals("0")
    function st:test-resolve-measure-in-mdiv($mdivId as xs:string, $designation as xs:string) as xs:string {
        string(count(source:resolve-measure-in-mdiv(doc($st:parts-labelled), $mdivId, $designation)))
};


(: source:resolve-virtual-measure-id ======================================== :)

declare
    (: one measure per part :)
    %test:args("measure_test_mdiv_01_1")        %test:assertEquals("2")
    %test:args("measure_test_mdiv_01_2b")       %test:assertEquals("2")
    (: an mdiv without parts yields a single measure :)
    %test:args("measure_test_mdiv_02_1")        %test:assertEquals("1")
    (: a real measure @xml:id is not a virtual ID, even though it starts with 'measure_' :)
    %test:args("measure_3f9a1c2d-flauto-one")   %test:assertEquals("0")
    (: a designation that occurs in no measure of that mdiv :)
    %test:args("measure_test_mdiv_01_99")       %test:assertEquals("0")
    (: not a virtual ID at all :)
    %test:args("no-such-id")                    %test:assertEquals("0")
    function st:test-resolve-virtual-measure-id-count($id as xs:string) as xs:string {
        string(count(source:resolve-virtual-measure-id(doc($st:parts-labelled), $id)))
};

declare
    (: resolution is by designation, so the two parts' measures come back in document order :)
    %test:args("measure_test_mdiv_01_2b")
    %test:assertEquals("measure_5b7e4d8a-flauto-two measure_1e4a9b7c-oboe-two")
    function st:test-resolve-virtual-measure-id-members($id as xs:string) as xs:string {
        string-join(
            source:resolve-virtual-measure-id(doc($st:parts-labelled), $id)/string(@xml:id),
            ' ')
};


(: source:resolve-measure-ref =============================================== :)

declare
    (: a real @xml:id wins even though it starts with 'measure_' - without this guard
     : the reference would be parsed as a virtual ID and resolve to nothing :)
    %test:args("measure_3f9a1c2d-flauto-one")   %test:assertEquals("measure_3f9a1c2d-flauto-one")
    (: a virtual ID resolves to every part's measure :)
    %test:args("measure_test_mdiv_01_2b")
    %test:assertEquals("measure_5b7e4d8a-flauto-two measure_1e4a9b7c-oboe-two")
    (: neither kind :)
    %test:args("no-such-id")                    %test:assertEquals("")
    function st:test-resolve-measure-ref($id as xs:string) as xs:string {
        string-join(
            source:resolve-measure-ref(doc($st:parts-labelled), $id)/string(@xml:id),
            ' ')
};


(: round trip ============================================================== :)

declare
    %test:args("measure_3f9a1c2d-flauto-one")   %test:assertEquals("true")
    (: the alphanumeric label is the interesting case: nothing normalises it on either side :)
    %test:args("measure_5b7e4d8a-flauto-two")   %test:assertEquals("true")
    %test:args("measure_7d3b5e0f-score-one")    %test:assertEquals("true")
    function st:test-virtual-measure-id-round-trip($measureId as xs:string) as xs:string {
        let $doc := doc($st:parts-labelled)
        let $measure := $doc/id($measureId)
        let $resolved := source:resolve-virtual-measure-id($doc, source:get-virtual-measure-id($measure))
        return
            string($measure/@xml:id = $resolved/@xml:id)
};
