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

(: $measureId is either a real measure @xml:id or one of the virtual measure IDs that
   Edirom Online uses to reference a measure number across all parts at once.
   source:resolve-measure-ref knows both forms and the precedence between them. :)
let $measure := source:resolve-measure-ref($mei, $measureId)

let $movementId as xs:string := ($measure[1]/ancestor::mei:mdiv[1]/string(@xml:id), '')[1]

return
    map {
        'measureId': $measureId,
        'movementId': $movementId,
        'measureCount': $measureCount
    }
