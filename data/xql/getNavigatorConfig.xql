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
declare namespace response = "http://exist-db.org/xquery/response";
declare namespace xlink = "http://www.w3.org/1999/xlink";
declare namespace xmldb = "http://exist-db.org/xquery/xmldb";

(: OPTION DECLARATIONS ===================================================== :)

declare option output:media-type "text/html";
declare option output:method "xhtml";
declare option output:indent "yes";
declare option output:omit-xml-declaration "yes";

(: VARIABLE DECLARATIONS =================================================== :)

declare variable $lang := request:get-parameter('lang', '');

(: FUNCTION DECLARATIONS =================================================== :)

(: HTML functions :)

declare function local:getCategory-html($category as element(edirom:navigatorCategory), $depth as xs:integer) as element(div) {
    <div
        class="navigatorCategory{
                if ($depth = 1) then
                    ()
                else
                    ($depth)
            }"
        id="{$category/@xml:id}">
        <div
            class="navigatorCategoryTitle{
                    if ($depth = 1) then
                        ()
                    else
                        ($depth)
                }">
            {
                if ($depth = 1) then
                    (eutil:getLocalizedName($category, $lang))
                else
                    (
                    <span
                        id="{$category/@xml:id}-title"
                        onclick="if(Ext.get('{$category/@xml:id}-title').hasCls('folded')) {{Ext.get('{$category/@xml:id}-title').removeCls('folded');Ext.get(Ext.get('{$category/@xml:id}-title').query('.fa')[0]).removeCls('fa-caret-right').addCls('fa-caret-down');Ext.get('{$category/@xml:id}-items').removeCls('hidden');}}else{{Ext.get('{$category/@xml:id}-title').addCls('folded');Ext.get(Ext.get('{$category/@xml:id}-title').query('.fa')[0]).removeCls('fa-caret-down').addCls('fa-caret-right');Ext.get('{$category/@xml:id}-items').addCls('hidden');}}"
                        class="folded">{eutil:getLocalizedName($category, $lang)}<i
                            class="fa fa-caret-right fa-fw"></i></span>
                    )
            }
        </div>
        <div
            id="{$category/@xml:id}-items"
            class="{
                    if ($depth = 1) then
                        ()
                    else
                        ('hidden')
                }">
            {
                for $elem in $category/edirom:navigatorItem | $category/edirom:navigatorCategory
                return
                    if (local-name($elem) eq 'navigatorItem') then (
                        local:getItem-html($elem, $depth)
                    ) else if (local-name($elem) eq 'navigatorSeparator') then (
                        local:getSeparator-html()
                    ) else if (local-name($elem) eq 'navigatorCategory') then (
                        local:getCategory-html($elem, $depth + 1)
                    ) else
                        ()
            }
        </div>
    </div>
};

declare function local:getItem-html($item as element(edirom:navigatorItem), $depth as xs:integer) as element(div) {
    let $target := $item/replace(@targets, '\[.*\]', '')
    let $cfg := concat('{', replace(substring-before($item/substring-after(@targets, '['), ']'), '=', ':'), '}')
    let $target :=
        if (starts-with($target, 'javascript:')) then
            (replace($target, 'javascript:', ''))
        else
            (concat("loadLink('", $target, "', ", $cfg, ")"))
    return
        <div class="navigatorItem{
                    if ($depth lt 2) then
                        ()
                    else
                        ($depth)
                }"
            id="{$item/@xml:id}"
            onclick="{$target}">
            {eutil:getLocalizedName($item, $lang)}
        </div>
};

declare function local:getSeparator-html() as element(div) {
    <div class="navigatorSeparator"></div>
};

declare function local:getDefinition-html($navConfig as element(edirom:navigatorDefinition)) as element(div)* {
    let $elems := $navConfig/*
    
    for $elem in $elems
    return
        if (local-name($elem) eq 'navigatorItem') then (
            local:getItem-html($elem, 1)
        ) else if (local-name($elem) eq 'navigatorSeparator') then (
            local:getSeparator-html()
        ) else if (local-name($elem) eq 'navigatorCategory') then (
            local:getCategory-html($elem, 1)
        ) else
            ()
};

(: JSON functions :)

declare function local:getCategory-json($category as element(edirom:navigatorCategory)) as map(*) {
    let $items :=
        for $elem in $category/edirom:navigatorItem | $category/edirom:navigatorCategory | $category/edirom:navigatorSeparator
        return
            if (local-name($elem) eq 'navigatorItem') then (
                local:getItem-json($elem)
            ) else if (local-name($elem) eq 'navigatorSeparator') then (
                local:getSeparator-json()
            ) else if (local-name($elem) eq 'navigatorCategory') then (
                local:getCategory-json($elem)
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

declare function local:getItem-json($item as element(edirom:navigatorItem)) as map(*) {
    map {
        "type": "navigatorItem",
        "id": string($item/@xml:id),
        "sortNo": string($item/@sortNo),
        "name": eutil:getLocalizedName($item, $lang),
        "targets": string($item/@targets)
    }
};

declare function local:getSeparator-json() as map(*) {
    map {
        "type": "navigatorSeparator"
    }
};

declare function local:getDefinition-json($navConfig as element(edirom:navigatorDefinition)) as array(*)? {
    let $elems := $navConfig/*
    
    return
        array {
            for $elem in $elems
            return
                if (local-name($elem) eq 'navigatorItem') then (
                    local:getItem-json($elem)
                ) else if (local-name($elem) eq 'navigatorSeparator') then (
                    local:getSeparator-json()
                ) else if (local-name($elem) eq 'navigatorCategory') then (
                    local:getCategory-json($elem)
                ) else
                    ()
        }
};

(: QUERY BODY ============================================================== :)

let $editionId := request:get-parameter('editionId', '')
let $workId := request:get-parameter('workId', '')
let $mode := request:get-parameter('mode', '')
let $edition := eutil:getDoc($editionId)
let $work := $edition/id($workId)
let $navConfig := $work/edirom:navigatorDefinition

return
    if ($mode = 'json') then (
        let $serializationParameters := "method=text media-type=application/json encoding=utf-8"
        let $outputOptions :=
            <output:serialization-parameters>
                <output:method>json</output:method>
                <output:indent>yes</output:indent>
            </output:serialization-parameters>
        let $data :=
            map {
                "navigatorDefinition": local:getDefinition-json($navConfig)
            }
        return
            response:stream($data => serialize($outputOptions), $serializationParameters)
    ) else
        local:getDefinition-html($navConfig)
