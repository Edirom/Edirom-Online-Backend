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

(: OPTION DECLARATIONS ===================================================== :)

declare option output:method "json";
declare option output:media-type "application/json";

(: FUNCTION DECLARATIONS =================================================== :)

(:~
 : Creates measure maps from parts.
 :
 : @param $measures The measure elements to process
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
 : Creates measure maps from the score.
 :
 : @param $measures The measure elements to process
 : @return A sequence of maps with the keys "id", and "voice"
 :)
declare function local:get-score-measures($measures as element(mei:measure)*) as map(*)* {
    for $measure in $measures
    return
        map {
            "id": $measure/string(@xml:id),
            "voice": "score"
        }
};

(:~
 : Returns measures for an mdiv element, grouped by measure number.
 :
 : @param $mdiv The mdiv element
 : @param $mdivID The ID of the mdiv
 : @return An array of measure maps with the keys "id", "measures", "mdivs", and "name"
 :)
declare function local:getMeasures($mdiv as element(mei:mdiv)?, $mdivID as xs:string?, $hasParts as xs:boolean) as array(*)* {
    array {
        (: One tuple per measure and designation, so that a measure standing for several of
           them - a range label, or a multiRest - contributes to each. Grouping on the
           unexpanded value is not an option: a measure yielding more than one designation
           would make the grouping key a sequence, which raises err:XPTY0004. :)
        for $measure in source:effective-measures($mdiv)
        for $designation in source:measure-designations($measure)
        group by $designation
        let $measures :=
            if($hasParts)
            then local:get-part-measures($measure)
            else local:get-score-measures($measure)
        order by eutil:compute-measure-sort-key($designation)
        return
            map {
                "id": source:measure-reference($measure, $designation),
                "measures": array { $measures },
                "mdivs": array { $mdivID },
                "name": $designation
            }
    }
};

(: QUERY BODY ============================================================== :)

let $uri := request:get-parameter('uri', '')
let $mdivID := request:get-parameter('mdiv', '')
let $mdiv := eutil:getDoc($uri)/id($mdivID)
let $hasParts := exists($mdiv//mei:part)

return
    local:getMeasures($mdiv, $mdivID, $hasParts)
 