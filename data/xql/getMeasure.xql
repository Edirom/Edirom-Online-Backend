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
declare namespace xlink = "http://www.w3.org/1999/xlink";
declare namespace xmldb = "http://exist-db.org/xquery/xmldb";

(: OPTION DECLARATIONS ===================================================== :)

declare option output:method "json";
declare option output:media-type "application/json";

(: QUERY BODY ============================================================== :)

let $id := request:get-parameter('id', '')
let $measureId := request:get-parameter('measureId', '')

let $measureCount :=
    if (contains($measureId, 'tstamp2=')) then
        (number(substring-before(substring-after($measureId, 'tstamp2='), 'm')) + 1)
    else
        (1)

let $measureId :=
    if (contains($measureId, '?')) then
        (substring-before($measureId, '?'))
    else
        ($measureId)

let $mei := eutil:getDoc($id)

let $measure := $mei/id($measureId)

(: Edirom Online uses virtual measure IDs for sources containing parts.
   Instead of referencing the IDs of all measures with a certain measure number
   from all parts, this allows for a single reference. The format of this reference
   is: measure_[mdiv ID]_[measure label], where the label is @label, falling back
   to @n — cf. local:get-measure-ids() in getMeasures.xql.

   Only applied when $measureId does not resolve to a real element, since measure
   @xml:id values may themselves start with 'measure_'.
 :)
let $movementId as xs:string :=
    if (exists($measure)) then
        (($measure/ancestor::mei:mdiv[1]/string(@xml:id), '')[1])
    else if (starts-with($measureId, 'measure_') and $mei//mei:parts) then
        (functx:substring-before-last(substring-after($measureId, 'measure_'), '_'))
    else
        ('')

return
    map {
        'measureId': $measureId,
        'movementId': $movementId,
        'measureCount': $measureCount
    }
