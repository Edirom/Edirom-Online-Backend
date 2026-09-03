xquery version "3.1";
(:
 : For LICENSE-Details please refer to the LICENSE file in the root directory of this repository.
 :)

(: IMPORTS ================================================================= :)

import module namespace eutil = "http://www.edirom.de/xquery/eutil" at "../xqm/eutil.xqm";
import module namespace source = "http://www.edirom.de/xquery/source" at "../xqm/source.xqm";

(: NAMESPACE DECLARATIONS ================================================== :)

declare namespace mei = "http://www.music-encoding.org/ns/mei";
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace request = "http://exist-db.org/xquery/request";
declare namespace xlink = "http://www.w3.org/1999/xlink";
declare namespace xmldb = "http://exist-db.org/xquery/xmldb";

(: OPTION DECLARATIONS ===================================================== :)

declare option output:method "json";
declare option output:media-type "application/json";

(: FUNCTION DECLARATIONS =================================================== :)

(:~
    Resolves the 'measure' parameter, which is either a measure @xml:id or a plain measure
    designation to be looked up within $movementId.

    Only ONE measure is wanted even where a designation occurs once per part: the caller
    fires one request per part, each feeding its own viewer. The choice therefore lives here,
    at the point where that constraint originates, rather than inside the lookup.

    Of the candidates, one that is on the facsimile is preferred over one that is not. Where a
    part's stave was omitted from the source, that part carries the measure as an invisible
    rest with no @facs, and it can perfectly well come first in document order - taking it
    would leave the response with no zone to report and hence empty, even though other parts
    do show the measure.

    @param $mei The sourcefile
    @param $movementId The ID of the mdiv to look in
    @param $measureIdName A measure @xml:id or a measure designation
    @returns The measure, or the empty sequence if neither resolves
:)
declare function local:findMeasure($mei, $movementId, $measureIdName) as element(mei:measure)? {
    let $candidates :=
        ($mei/id($measureIdName)[self::mei:measure],
         source:resolve-measure-in-mdiv($mei, $movementId, $measureIdName))
    return
        ($candidates[@facs], $candidates)[1]
};
(:~
    Returns one map per zone the measure is linked to.

    A measure broken across two systems or pages is encoded as a single measure
    referencing two or more zones - see docs/data-creation-workflow.md, "ensure that a
    single measure is linked to two or more zones, rather than creating separate
    measures". @facs is therefore a whitespace-separated list of IDREFs, and each of its
    zones needs its own entry so the viewer can lay the fragments out side by side.

    The maps are emitted in @facs order, which the caller relies on to tell the fragments
    apart: it starts a new viewer wherever a zone's @ulx moves back to the left of its
    predecessor.

    @param $mei The sourcefile
    @param $measure The measure to process
    @param $movementId The ID of the mdiv the measure belongs to
    @returns One json object per zone, or none if $measure is empty
:)
declare function local:getMeasure($mei, $measure, $movementId) as map(*)* {
    let $measureId := $measure/string(@xml:id)
    for $zoneRef in tokenize(normalize-space($measure/@facs), '\s+')
    let $zoneId := substring-after($zoneRef, '#')
    let $zone := $mei/id($zoneId)
    let $surface := $zone/parent::mei:surface
    let $graphic := $surface/mei:graphic[@type = 'facsimile']
    return
        map {
            "measureId": $measureId,
            "zoneId": $zoneId,
            "pageId": $surface/string(@xml:id),
            "movementId": $movementId,
            "path": $graphic/string(@target),
            "width": $graphic/string(@width),
            "height": $graphic/string(@height),
            "ulx": $zone/string(@ulx),
            "uly": $zone/string(@uly),
            "lrx": $zone/string(@lrx),
            "lry": $zone/string(@lry)
        }
};

(: QUERY BODY ============================================================== :)

let $id := request:get-parameter('id', '')
let $measureIdName := request:get-parameter('measure', '')
let $movementId := request:get-parameter('movementId', '')
let $measureCount := request:get-parameter('measureCount', '1')

let $mei := eutil:getDoc($id)

let $measure := local:findMeasure($mei, $movementId, $measureIdName)
let $extraMeasures :=
    for $i in (2 to xs:integer($measureCount))
    let $m := $measure/following-sibling::mei:measure[$i - 1] (: TODO: following-sibling könnte problematisch sein, da so section-Grenzen nicht überwunden werden :)
    return
        if ($m) then
            ($m)
        else
            ()
        
(: Extra measure parts :)
let $extraMeasuresParts :=
    for $exm in $measure | $extraMeasures
    return
        $exm/following-sibling::mei:measure[(exists(@label) and @label = $exm/@label) or (not(exists(@label)) and @n = $exm/@n)]

return
    array {
        local:getMeasure($mei, $measure, $movementId),
        for $m in $extraMeasures
        return
            local:getMeasure($mei, $m, $movementId),
        for $m in $extraMeasuresParts
        return
            local:getMeasure($mei, $m, $movementId)
    }
