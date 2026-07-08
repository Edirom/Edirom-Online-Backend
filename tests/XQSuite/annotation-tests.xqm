xquery version "3.1";

(:~
 : XQSuite unit tests for the annotation module (data/xqm/annotation.xqm).
 :
 : Scope: the pure / structural functions that can be exercised with in-memory
 : constructed MEI. The reference-resolving functions (toJSON, getPriority /
 : getPriorityLabel via eutil:get-referenced-element, get-referenced-category-elements,
 : get-referenced-categories-as-taxonomy-array) depend on id()/doc() resolution and
 : require stored fixtures; they are covered separately.
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
