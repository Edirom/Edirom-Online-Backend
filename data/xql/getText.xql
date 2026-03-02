xquery version "3.1";
(:
 : For LICENSE-Details please refer to the LICENSE file in the root directory of this repository.
 :)

(: IMPORTS ================================================================= :)

import module namespace teitext = "http://www.edirom.de/xquery/teitext" at "../xqm/teitext.xqm";

(: NAMESPACE DECLARATIONS ================================================== :)

declare namespace request = "http://exist-db.org/xquery/request";
declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";

(: OPTION DECLARATIONS ===================================================== :)

declare option output:method "xhtml";
declare option output:media-type "text/html";
declare option output:omit-xml-declaration "yes";
declare option output:indent "yes";

(: QUERY BODY ============================================================== :)

let $edition := request:get-parameter('edition', '')
let $uri := request:get-parameter('uri', '')
let $idPrefix := request:get-parameter('idPrefix', '')
let $term := request:get-parameter('term', '')
let $page := request:get-parameter('page', '')
let $contextPath := request:get-scheme()|| "://" || request:get-server-name() || ":" || request:get-server-port() || request:get-context-path()

return 
    teitext:getHtmlAPI("v1", $edition, $uri, $idPrefix, $term, $page, $contextPath)