xquery version "3.1";
(:
 : For LICENSE-Details please refer to the LICENSE file in the root directory of this repository.
 :)

(: IMPORTS ================================================================= :)

import module namespace eutil = "http://www.edirom.de/xquery/eutil" at "../xqm/eutil.xqm";

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

declare function local:getName($elem as element()) as xs:string {
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

declare function local:getPageId($elem as node(), $mode as xs:string) as xs:string {
    if ($mode eq 'pageMode') then
        substring-after($elem/preceding::tei:pb[1]/@facs, '#')
    else
        '-1'
};

let $uri := request:get-parameter('uri', '')
let $mode := request:get-parameter('mode', '')
let $tei := eutil:getDoc($uri)

let $ret as array(*)* :=
    array {
        for $elem in $tei//tei:div[@type = 'chapter'] |
            $tei//tei:div1 | $tei//tei:milestone[@unit = 'number'] |
            $tei//tei:div[@type = 'act']
        let $pageId := local:getPageId($elem, $mode)
        return
            if (($elem/local-name() = 'div' and $elem[@type = 'chapter']) or $elem/local-name() = 'div1') then (
                let $chapter := $elem
                return
                    map {
                        "id": $chapter/string(@xml:id),
                        "name": local:getName($chapter),
                        "pageId": $pageId
                    }
            ) else if ($elem/local-name() = 'milestone' and $elem[@unit = 'number']) then (
                let $numbers := $elem
                order by $numbers/number(replace(@n, '\D', '')), $numbers/@n
                return
                    map {
                        "id": $numbers/string(@xml:id),
                        "name": local:getName($numbers),
                        "pageId": $pageId
                    }
            ) else if ($elem/local-name() = 'div' and $elem[@type = 'act']) then (
                let $act := $elem
                return
                    for $scene in $act//tei:div[@type = 'scene']
                    return
                        map {
                            "id": $scene/string(@xml:id),
                            "name": local:getName($scene),
                            "pageId": local:getPageId($scene, $mode)
                        }
            ) else
                ()
    }
return
    $ret
