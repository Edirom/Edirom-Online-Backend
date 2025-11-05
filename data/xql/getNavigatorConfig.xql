xquery version "3.1";
(:
 : For LICENSE-Details please refer to the LICENSE file in the root directory of this repository.
 :)

(: IMPORTS ================================================================= :)

import module namespace eutil = "http://www.edirom.de/xquery/eutil" at "../xqm/eutil.xqm";

(: NAMESPACE DECLARATIONS ================================================== :)

declare namespace edirom = "http://www.edirom.de/ns/1.3";
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace request = "http://exist-db.org/xquery/request";
declare namespace xlink = "http://www.w3.org/1999/xlink";
declare namespace xmldb = "http://exist-db.org/xquery/xmldb";

(: OPTION DECLARATIONS ===================================================== :)

declare option output:media-type "application/json";
declare option output:method "json";
declare option output:indent "yes";

(: VARIABLE DECLARATIONS =================================================== :)

declare variable $lang := request:get-parameter('lang', '');

(: FUNCTION DECLARATIONS =================================================== :)

declare function local:getCategory($category) {
    let $items := 
        for $elem in $category/edirom:navigatorItem | $category/edirom:navigatorCategory | $category/edirom:navigatorSeparator
        return
            if (local-name($elem) eq 'navigatorItem') then (
                local:getItem($elem)
            ) else if (local-name($elem) eq 'navigatorSeparator') then (
                local:getSeparator()
            ) else if (local-name($elem) eq 'navigatorCategory') then (
                local:getCategory($elem)
            ) else
                ()
    
    return
        map {
            "type": "navigatorCategory",
            "id": string($category/@xml:id),
            "sortNo": string($category/@sortNo),
            "name": eutil:getLocalizedName($category, $lang),
            "items": array { $items }
        }
};

declare function local:getItem($item) {
    let $target := $item/replace(@targets, '\[.*\]', '')
    let $cfg := substring-before($item/substring-after(@targets, '['), ']')
    let $baseMap := map {
        "type": "navigatorItem",
        "id": string($item/@xml:id),
        "sortNo": string($item/@sortNo),
        "name": eutil:getLocalizedName($item, $lang),
        "targets": string($item/@targets),
        "target": $target
    }
    
    return
        if ($cfg != '') then
            map:put($baseMap, "config", $cfg)
        else
            $baseMap
};

declare function local:getSeparator() {
    map {
        "type": "navigatorSeparator"
    }
};

declare function local:getDefinition($navConfig) {
    let $elems := $navConfig/*
    
    return
        array {
            for $elem in $elems
            return
                if (local-name($elem) eq 'navigatorItem') then (
                    local:getItem($elem)
                ) else if (local-name($elem) eq 'navigatorSeparator') then (
                    local:getSeparator()
                ) else if (local-name($elem) eq 'navigatorCategory') then (
                    local:getCategory($elem)
                ) else
                    ()
        }
};

(: QUERY BODY ============================================================== :)

let $editionId := request:get-parameter('editionId', '')
let $workId := request:get-parameter('workId', '')
let $edition := doc($editionId)/root()
let $work := $edition/id($workId)
let $navConfig := $work/edirom:navigatorDefinition

return
    map {
        "navigatorDefinition": local:getDefinition($navConfig)
    }
