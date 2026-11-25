xquery version "3.1";
(:
 : For LICENSE-Details please refer to the LICENSE file in the root directory of this repository.
 :)

(:~
 : This module provides library functions for Texts
 :
 : @author <a href="mailto:roewenstrunk@edirom.de">Daniel Röwenstrunk</a>
 :)
module namespace teitext="http://www.edirom.de/xquery/teitext";

(: IMPORTS ================================================================= :)

import module namespace edition="http://www.edirom.de/xquery/edition" at "edition.xqm";
import module namespace eutil="http://www.edirom.de/xquery/eutil" at "eutil.xqm";

(: NAMESPACE DECLARATIONS ================================================== :)

declare namespace tei="http://www.tei-c.org/ns/1.0";

(: FUNCTION DECLARATIONS =================================================== :)

(:~
 : Returns whether a document is a work or not
 :
 : @param $uri The URI of the document
 : @return Is work or not
 :)
declare function teitext:isText($uri as xs:string) as xs:boolean {

    exists(eutil:getDoc($uri)/tei:TEI)

};

(:~
 : Returns a text's label
 :
 : @param $source The URIs of the Text's document to process
 : @return The label
 :)
declare function teitext:getLabel($uri as xs:string, $edition as xs:string) as xs:string {

    eutil:getLocalizedTitle(eutil:getDoc($uri), edition:getLanguage($edition))

};

(:~
 : Returns the display name for a chapter, numbered milestone, or scene.
 : Chapter labels are limited to 30 characters and scene labels to 40 characters.
 : Whitespace in chapter labels is normalized.
 :
 : @param $elem The TEI element whose display name to return
 : @return The display name
 :)
declare function teitext:getChapterName($elem as element()) as xs:string {
    if (($elem/local-name() = 'div' and $elem[@type = 'chapter']) or $elem/local-name() = 'div1') then
        let $n := if ($elem/@n) then concat($elem/@n, ': ') else ''
        let $label :=
            normalize-space(
                if ($elem/tei:head) then
                    string($elem/tei:head)
                else
                    string-join($elem/text() ! string(.), ' ')
            )
        let $label :=
            if (string-length($label) > 30) then
                concat(substring($label, 1, 30), '…')
            else
                $label
        return concat($n, $label)
    else if ($elem/local-name() = 'milestone' and $elem[@unit = 'number']) then
        concat('No. ', $elem/@n)
    else if ($elem/local-name() = 'div' and $elem[@type = 'scene']) then
        let $act := $elem/ancestor::tei:div[@type = 'act'][1]
        let $label := eutil:changeFormatToRomanNumeral($act/@n) || ' - ' || string-join(
            for $t in $elem/tei:head//text()
            return
                if (matches($t, '\w')) then $t else (), '')
        return
            if (string-length($label) > 40) then
                concat(substring($label, 1, 40), '…')
            else
                $label
    else
        ''
};

(:~
 : Returns the page identifier associated with a TEI element.
 : In page mode, this is the fragment identifier from the nearest preceding page break;
 : in other modes, the function returns -1.
 :
 : @param $elem The TEI node for which to find the page identifier
 : @param $mode The display mode
 : @return The page identifier, or -1 outside page mode
 :)
declare function teitext:getChapterPageId($elem as node(), $mode as xs:string) as xs:string {
    if ($mode eq 'pageMode') then
        substring-after($elem/preceding::tei:pb[1]/@facs, '#')
    else
        '-1'
};
