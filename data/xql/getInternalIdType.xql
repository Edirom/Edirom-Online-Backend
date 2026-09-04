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

declare option output:media-type "text/plain";
declare option output:method "text";

(: QUERY BODY ============================================================== :)

let $uri := request:get-parameter('uri', '')
let $docUri :=
    if (contains($uri, '#')) then
        (substring-before($uri, '#'))
    else
        ($uri)
let $internalId :=
    if (contains($uri, '#')) then
        (substring-after($uri, '#'))
    else
        ()
let $internalId :=
    if (contains($internalId, '?')) then
        (substring-before($internalId, '?'))
    else
        ($internalId)
let $doc := eutil:getDoc($docUri)
let $internal := $doc/id($internalId)

(: An ID that resolves to nothing may still be one of the virtual measure IDs Edirom
   Online uses to reference a measure number across all parts at once. :)
let $internal :=
    if (exists($internal)) then
        ($internal)
    else
        (source:resolve-virtual-measure-id($doc, $internalId)[1])

return
    if (exists($internal)) then
        (local-name($internal))
    else
        ('unknown')
