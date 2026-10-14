xquery version "3.1";
(:
 : For LICENSE-Details please refer to the LICENSE file in the root directory of this repository.
 :)

(: IMPORTS ================================================================= :)

import module namespace request = "http://exist-db.org/xquery/request";

import module namespace eutil = "http://www.edirom.de/xquery/eutil" at "../xqm/eutil.xqm";
import module namespace linktarget = "http://www.edirom.de/xquery/linktarget" at "../xqm/linktarget.xqm";

(: NAMESPACE DECLARATIONS ================================================== :)

declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";

(: OPTION DECLARATIONS ===================================================== :)

declare option output:method "json";
declare option output:media-type "application/json";

(: VARIABLE DECLARATIONS =================================================== :)

declare variable $lang := eutil:getSetLanguage(());
declare variable $uri := request:get-parameter('uri', '');

(: QUERY BODY ============================================================== :)

linktarget:details($uri, $lang)
