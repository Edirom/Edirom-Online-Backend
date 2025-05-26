xquery version "3.1";
(:
 : For LICENSE-Details please refer to the LICENSE file in the root directory of this repository.
 :)

(: IMPORTS ================================================================= :)

import module namespace functx = "http://www.functx.com";

import module namespace eutil = "http://www.edirom.de/xquery/eutil" at "../xqm/eutil.xqm";

(: NAMESPACE DECLARATIONS ================================================== :)

declare namespace mei = "http://www.music-encoding.org/ns/mei";
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace request = "http://exist-db.org/xquery/request";

(: OPTION DECLARATIONS ===================================================== :)

declare option output:method "json";
declare option output:media-type "application/json";

(: FUNCTION DECLARATIONS =================================================== :)

(:~
 : Analyzes measure labels and expands ranges like "1–4" into individual labels.
 :
 : @param $labels The measure labels to analyze
 : @return A sequence of individual labels as xs:string*
 :)
declare function local:analyze-labels($labels as xs:string*) as xs:string* {
    for $label in $labels
    return
        if (contains($label, '–')) then (
            let $first := substring-before($label, '–')
            let $last := substring-after($label, '–')
            let $steps := xs:integer(number($last) - number($first) + 1)
            for $i in 1 to $steps
            return string(number($first) + $i - 1)
        ) else $label
};

(:~
 : Determines the measure IDs (either from @label or @n).
 : Ranges in @label are expanded into individual IDs.
 :
 : @param $measure The measure element
 : @return A sequence of measure IDs as xs:string*
 :)
declare function local:get-measure-ids($measure as element(mei:measure)) as xs:string* {
    if ($measure/@label) then
        local:analyze-labels($measure/@label ! string(.))
    else
        $measure/@n ! string(.)
};

(:~
 : Creates measure maps for a part.
 :
 : @param $part The part element
 : @param $measureN The measure number
 : @param $measures Measures that may contain multiRests
 : @return A sequence of maps with the keys "id", "voice", and "partLabel"
 :)
declare function local:get-part-measures($measures as element(mei:measure)*) as map(*)* {
    for $measure in $measures[ancestor::mei:part]
    let $voiceRef := $measure/ancestor::mei:part/mei:staffDef/data(@decls)
    return
        map {
            "id": $measure/string(@xml:id),
            "voice": $voiceRef,
            "partLabel": eutil:getPartLabel($measure, 'measure')
        }
};

(:~
 : Returns measures for an mdiv element, grouped by measure number.
 :
 : @param $mdiv The mdiv element
 : @param $mdivID The ID of the mdiv
 : @return An array of measure maps with the keys "id", "measures", "mdivs", and "name"
 :)
declare function local:getMeasures($mdiv as element(mei:mdiv)?, $mdivID as xs:string?) as array(*)* {
    array {
        for $measure in $mdiv//mei:measure
        group by $measureN := local:get-measure-ids($measure)
        order by eutil:sort-as-numeric-alpha($measureN)
        return
            map {
                "id": 'measure_' || $mdivID || '_' || $measureN,
                "measures": local:get-part-measures($measure),
                "mdivs": $mdivID,
                "name": $measureN
            }
    }
};

(:~
 : Returns measures containing multiRests for an mdiv and a measure number.
 :
 : @param $mdiv The mdiv element
 : @param $measureN The measure number
 : @return A sequence of measure elements with multiRest
 :)
declare function local:multiRestMeasures($mdiv as element(mei:mdiv), $measureN as xs:string) as element(mei:measure)* {
    if($mdiv//mei:multiRest)
    then
        if ($mdiv//mei:measure/@label)
        then
            ($mdiv//mei:measure[.//mei:multiRest][number(substring-before(@label, '–')) <= number($measureN)][.//mei:multiRest/number(@num) gt (number($measureN) - number(substring-before(@label, '–')))])
        else
            ($mdiv//mei:measure[.//mei:multiRest][number(@n) lt number($measureN)][.//mei:multiRest/number(@num) gt (number($measureN) - number(@n))])
    else ()
};

(: QUERY BODY ============================================================== :)

let $uri := request:get-parameter('uri', '')
let $mdivID := request:get-parameter('mdiv', '')
let $mdiv := eutil:getDoc($uri)/id($mdivID)

return
    local:getMeasures($mdiv, $mdivID)
