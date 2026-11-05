xquery version "3.1";
(:
 : For LICENSE-Details please refer to the LICENSE file in the root directory of this repository.
 :)

(: IMPORTS ================================================================= :)

import module namespace eutil = "http://www.edirom.de/xquery/eutil" at "../xqm/eutil.xqm";
import module namespace source = "http://www.edirom.de/xquery/source" at "../xqm/source.xqm";

(: NAMESPACE DECLARATIONS ================================================== :)

declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace request = "http://exist-db.org/xquery/request";

(: OPTION DECLARATIONS ===================================================== :)

declare option output:media-type "text/plain";
declare option output:method "text";

(: QUERY BODY ============================================================== :)

let $uri := request:get-parameter('uri', '')
let $movementId := request:get-parameter('movementId', '')

let $mei := eutil:getDoc($uri)
let $firstMeasure := eutil:getFirstMeasureInMovement($mei, $movementId)
let $zoneId := source:getZoneIdFromMeasure($firstMeasure)
let $surface := source:getSurfaceForZone($mei, $zoneId)

return
    $surface/string(@xml:id)
