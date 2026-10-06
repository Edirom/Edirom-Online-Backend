xquery version "3.1";
(:
 : For LICENSE-Details please refer to the LICENSE file in the root directory of this repository.
 :)

(:~
 : Returns the details of several link targets at once, the batch version of getLinkTarget.xql.
 : The parameter "uri" may be repeated (GET or POST). The result is a JSON array in the order of
 : the requested URIs. Each entry is the result of getLinkTarget.xql plus the key "uri" holding the
 : requested URI. A URI that cannot be resolved yields an entry of type "unknown" with an empty
 : title and no views.
 :)

(: IMPORTS ================================================================= :)

import module namespace request = "http://exist-db.org/xquery/request";

import module namespace eutil = "http://www.edirom.de/xquery/eutil" at "../xqm/eutil.xqm";
import module namespace linktarget = "http://www.edirom.de/xquery/linktarget" at "../xqm/linktarget.xqm";

(: NAMESPACE DECLARATIONS ================================================== :)

declare namespace map = "http://www.w3.org/2005/xpath-functions/map";
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";

(: OPTION DECLARATIONS ===================================================== :)

declare option output:method "json";
declare option output:media-type "application/json";

(: VARIABLE DECLARATIONS =================================================== :)

declare variable $lang := eutil:getSetLanguage(());
declare variable $uris := request:get-parameter('uri', ());

(: FUNCTION DECLARATIONS =================================================== :)

declare function local:getLinkTarget($uri as xs:string) as map(*) {
    try {
        map:put(linktarget:details($uri, $lang), 'uri', $uri)
    } catch * {
        map {
            'uri': $uri,
            'type': 'unknown',
            'title': '',
            'views': array {}
        }
    }
};

(: QUERY BODY ============================================================== :)

array {
    for $uri in $uris
    return
        local:getLinkTarget($uri)
}
