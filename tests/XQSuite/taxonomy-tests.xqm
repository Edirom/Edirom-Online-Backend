xquery version "3.1";

(:~
 : XQSuite unit tests for the taxonomy module (data/xqm/taxonomy.xqm).
 :
 : Scope: the structural / pure functions that do not depend on id() resolution or a
 : request context, so they can be exercised with in-memory constructed MEI. Functions
 : that rely on id() (taxonomy:get-root-identifying-string) or doc()/base-uri
 : (the cross-file resolvers) require stored fixtures and are covered separately.
 :)
module namespace tax = "http://www.edirom.de/xquery/xqsuite/taxonomy-tests";

import module namespace taxonomy = "http://www.edirom.de/xquery/taxonomy" at "xmldb:exist:///db/apps/Edirom-Online-Backend/data/xqm/taxonomy.xqm";

declare namespace mei = "http://www.music-encoding.org/ns/mei";
declare namespace test = "http://exist-db.org/xquery/xqsuite";


(: FIXTURES =============================================================== :)

(:~ Pattern A: inner taxonomy carries its own @xml:id; categories have no @class. :)
declare %private function tax:patternA() as element(mei:taxonomy) {
    <mei:taxonomy xml:id="myAnnotationTypes">
        <mei:label xml:lang="de">Annotationstypen</mei:label>
        <mei:label xml:lang="en">Annotation Types</mei:label>
        <mei:category xml:id="myType.structural">
            <mei:label xml:lang="de">Strukturell</mei:label>
            <mei:label xml:lang="en">Structural</mei:label>
        </mei:category>
    </mei:taxonomy>
};

(:~ Pattern B: categories name their group via @class, which takes precedence over the
   inner taxonomy's own @xml:id. :)
declare %private function tax:patternB() as element(mei:taxonomy) {
    <mei:taxonomy xml:id="ediromClassification">
        <mei:category xml:id="ediromPriority"/>
        <mei:taxonomy xml:id="ediromPriorityTaxonomy">
            <mei:category class="#ediromPriority" xml:id="ediromAnnotPrio1">
                <mei:label xml:lang="de">1</mei:label>
                <mei:label xml:lang="en">1</mei:label>
            </mei:category>
        </mei:taxonomy>
    </mei:taxonomy>
};


(: taxonomy:get-parent-taxonomy-identifying-string ======================== :)

(:~ Pattern B: the @class fragment is the grouping key. :)
declare
    %test:assertEquals("ediromPriority")
function tax:parent-id-from-class() as xs:string {
    taxonomy:get-parent-taxonomy-identifying-string(
        tax:patternB()//mei:category[@xml:id = "ediromAnnotPrio1"])
};

(:~ Pattern A: with no @class, the grouping key is the nearest taxonomy @xml:id. :)
declare
    %test:assertEquals("myAnnotationTypes")
function tax:parent-id-from-taxonomy() as xs:string {
    taxonomy:get-parent-taxonomy-identifying-string(
        tax:patternA()//mei:category[@xml:id = "myType.structural"])
};


(: taxonomy:get-languages ================================================= :)

(:~ Distinct @xml:lang values found beneath the ancestor taxonomy (order-independent). :)
declare
    %test:assertEquals("de en")
function tax:languages() as xs:string {
    string-join(sort(array:flatten(taxonomy:get-languages(tax:patternA()))), " ")
};

(:~ No @xml:lang anywhere yields an empty language array. :)
declare
    %test:assertEquals(0)
function tax:languages-empty() as xs:integer {
    array:size(taxonomy:get-languages(<mei:taxonomy xml:id="t"><mei:category xml:id="c"/></mei:taxonomy>))
};


(: taxonomy:get-labels ==================================================== :)

(:~ 2-arity, explicit language: returns the matching mei:label. :)
declare
    %test:assertEquals("Structural")
function tax:labels-explicit-lang() as xs:string {
    taxonomy:get-labels(tax:patternA()//mei:category[@xml:id = "myType.structural"], ["en"])("en")
};

(:~ 1-arity 'und' fallback: prefers @label when no language-neutral mei:label is present. :)
declare
    %test:assertEquals("LBL")
function tax:labels-und-uses-label-attr() as xs:string {
    let $t := <mei:taxonomy xml:id="t"><mei:category xml:id="c" label="LBL"><mei:label xml:lang="en">E</mei:label></mei:category></mei:taxonomy>
    return taxonomy:get-labels($t//mei:category)("und")
};

(:~ 1-arity 'und' fallback: drops through to @xml:id when there is no label at all. :)
declare
    %test:assertEquals("c")
function tax:labels-und-falls-to-xmlid() as xs:string {
    let $t := <mei:taxonomy xml:id="t"><mei:category xml:id="c"/></mei:taxonomy>
    return taxonomy:get-labels($t//mei:category)("und")
};


(: taxonomy:get-label-localized-as-string ================================= :)

(:~ With no language-specific label, resolution drops to the element's @xml:id
   regardless of the active language. :)
declare
    %test:assertEquals("c")
function tax:label-localized-falls-to-xmlid() as xs:string {
    let $t := <mei:taxonomy xml:id="t"><mei:category xml:id="c"/></mei:taxonomy>
    return taxonomy:get-label-localized-as-string($t//mei:category)
};

(:~ An empty input yields the empty sequence. :)
declare
    %test:assertEmpty
function tax:label-localized-empty() {
    taxonomy:get-label-localized-as-string(())
};


(: taxonomy:taxonomy-or-category-test ===================================== :)

(:~ A mei:taxonomy passes the type test and is returned unchanged. :)
declare
    %test:assertEquals("taxonomy")
function tax:type-test-accepts-taxonomy() as xs:string {
    local-name(taxonomy:taxonomy-or-category-test(<mei:taxonomy xml:id="t"/>))
};

(:~ A mei:category passes the type test and is returned unchanged. :)
declare
    %test:assertEquals("category")
function tax:type-test-accepts-category() as xs:string {
    local-name(taxonomy:taxonomy-or-category-test(<mei:category/>))
};

(:~ Any other element raises the standard XPTY0004 type error. :)
declare
    %test:assertError("XPTY0004")
function tax:type-test-rejects-other() {
    taxonomy:taxonomy-or-category-test(<mei:label/>)
};