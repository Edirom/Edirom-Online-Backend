xquery version "3.1";

(:~
 : XQSuite unit tests for the annotation module (data/xqm/annotation.xqm).
 :
 : Scope: primarily the pure / structural functions that can be exercised with in-memory
 : constructed MEI. is-fully-taxonomised is the exception — it resolves @class tokens via
 : eutil:get-referenced-element, so it uses the stored fixture data/mei-annotations.xml,
 : since eXist resolves id() only on stored documents.
 :
 : Still uncovered, all for the same reason and all needing that fixture extended: toJSON,
 : getPriority / getPriorityLabel, get-referenced-category-elements, and
 : get-referenced-categories-as-taxonomy-array.
 :)
module namespace ann = "http://www.edirom.de/xquery/xqsuite/annotation-tests";

import module namespace annotation = "http://www.edirom.de/xquery/annotation" at "xmldb:exist:///db/apps/Edirom-Online-Backend/data/xqm/annotation.xqm";

declare namespace mei = "http://www.music-encoding.org/ns/mei";
declare namespace test = "http://exist-db.org/xquery/xqsuite";


(: annotation:get-class-idrefs-as-sequence =============================== :)

(:~ @class tokens are returned as IDREFs with the leading '#' stripped. :)
declare
    %test:assertEquals("ediromAnnotPrio3 wega.annotation.category.articulation")
function ann:class-idrefs() as xs:string {
    let $a := <mei:annot xml:id="a1" type="editorialComment"
                  class="#ediromAnnotPrio3 #wega.annotation.category.articulation"/>
    return string-join(annotation:get-class-idrefs-as-sequence($a), " ")
};

(:~ An annotation without @class yields the empty sequence (no IDREF cast error). :)
declare
    %test:assertEmpty
function ann:class-idrefs-empty() {
    annotation:get-class-idrefs-as-sequence(<mei:annot xml:id="a1" type="editorialComment"/>)
};


(: annotation:getParticipants ============================================ :)

(:~ Distinct document parts of the @plist tokens (the '#fragment' is dropped). :)
declare
    %test:assertEquals("a.xml b.xml")
function ann:participants() as xs:string {
    let $a := <mei:annot xml:id="a1" type="editorialComment"
                  plist="a.xml#m1 a.xml#m2 b.xml#m1"/>
    return string-join(annotation:getParticipants($a), " ")
};


(: annotation:get-category-label-localized =============================== :)

(:~ A mei:category with no label resolves to its own @xml:id.
   (The category is wrapped in a taxonomy, as it always is in real data — a category
   with no taxonomy ancestor cannot yield a grouping identifier and would, correctly,
   trip the as-xs:string contract of taxonomy:get-parent-taxonomy-identifying-string.) :)
declare
    %test:assertEquals("myCat")
function ann:category-label-falls-to-xmlid() as xs:string {
    let $t := <mei:taxonomy xml:id="t"><mei:category xml:id="myCat"/></mei:taxonomy>
    return annotation:get-category-label-localized($t//mei:category)
};

(:~ An element that is neither category nor term falls back to its local name. :)
declare
    %test:assertEquals("rend")
function ann:category-label-default() as xs:string {
    annotation:get-category-label-localized(<mei:rend/>)
};


(: annotation:is-fully-taxonomised ======================================= :)

(:~
 : This function resolves @class tokens through eutil:get-referenced-element, which uses
 : id() — and eXist resolves id() only on stored documents. The cases below therefore
 : address annotations in the stored fixture rather than constructing them inline.
 :)
declare variable $ann:annotations := "xmldb:exist:///db/apps/Edirom-Online-Backend/tests/XQSuite/data/mei-annotations.xml";

declare
    (: a token resolving to a category inside a taxonomy :)
    %test:args("test.annot.category-only")          %test:assertEquals("true")
    (: an annotation with no classification loses nothing by dropping the legacy fields :)
    %test:args("test.annot.unclassified")           %test:assertEquals("true")
    (: a reference to a taxonomy ITSELF. Editions use one to mark scheme membership, for
       global styling, and as a fallback in the class hierarchy. It appears in neither the
       legacy nor the taxonomy field, so it cannot be lost - but a taxonomy is not its own
       ancestor, so an ancestor-only test wrongly reports the annotation as unexpressible. :)
    %test:args("test.annot.taxonomy-root")          %test:assertEquals("true")
    %test:args("test.annot.taxonomy-root-only")     %test:assertEquals("true")
    (: a dangling @class reference may name a classification the taxonomy fields cannot
       express, so the legacy fields have to stay :)
    %test:args("test.annot.dangling")               %test:assertEquals("false")
    (: a legacy mei:ptr classification :)
    %test:args("test.annot.legacy-ptr")             %test:assertEquals("false")
    (: a legacy priority modelled as mei:term in a termList resolves outside any taxonomy :)
    %test:args("test.annot.term-outside-taxonomy")  %test:assertEquals("false")
    function ann:is-fully-taxonomised($annotId as xs:string) as xs:string {
        string(annotation:is-fully-taxonomised(doc($ann:annotations)/id($annotId)))
};
