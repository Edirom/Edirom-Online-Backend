xquery version "3.1";
(:
 : For LICENSE-Details please refer to the LICENSE file in the root directory of this repository.
 :)

(: IMPORTS ================================================================= :)

import module namespace eutil = "http://www.edirom.de/xquery/eutil" at "../xqm/eutil.xqm";
import module namespace teitext = "http://www.edirom.de/xquery/teitext" at "../xqm/teitext.xqm";

(: NAMESPACE DECLARATIONS ================================================== :)

declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace request = "http://exist-db.org/xquery/request";
declare namespace tei = "http://www.tei-c.org/ns/1.0";
declare namespace xlink = "http://www.w3.org/1999/xlink";
declare namespace xmldb = "http://exist-db.org/xquery/xmldb";

(: OPTION DECLARATIONS ===================================================== :)

declare option output:method "json";
declare option output:media-type "application/json";

(: FUNCTION DECLARATIONS =================================================== :)

let $uri := request:get-parameter('uri', '')
let $mode := request:get-parameter('mode', '')
let $tei := eutil:getDoc($uri)

let $ret as array(*)* :=
    array {
        for $elem in $tei//tei:div[@type = 'chapter'] |
            $tei//tei:div1 | $tei//tei:milestone[@unit = 'number'] |
            $tei//tei:div[@type = 'act']
        let $pageId := teitext:getChapterPageId($elem, $mode)
        return
            if (($elem/local-name() = 'div' and $elem[@type = 'chapter']) or $elem/local-name() = 'div1') then (
                let $chapter := $elem
                return
                    map {
                        "id": $chapter/string(@xml:id),
                        "name": teitext:getChapterName($chapter),
                        "pageId": $pageId
                    }
            ) else if ($elem/local-name() = 'milestone' and $elem[@unit = 'number']) then (
                let $numbers := $elem
                order by $numbers/number(replace(@n, '\D', '')), $numbers/@n
                return
                    map {
                        "id": $numbers/string(@xml:id),
                        "name": teitext:getChapterName($numbers),
                        "pageId": $pageId
                    }
            ) else if ($elem/local-name() = 'div' and $elem[@type = 'act']) then (
                let $act := $elem
                return
                    for $scene in $act//tei:div[@type = 'scene']
                    return
                        map {
                            "id": $scene/string(@xml:id),
                            "name": teitext:getChapterName($scene),
                            "pageId": teitext:getChapterPageId($scene, $mode)
                        }
            ) else
                ()
    }
return
    $ret
