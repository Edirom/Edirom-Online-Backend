xquery version "3.1";
(:
 : For LICENSE-Details please refer to the LICENSE file in the root directory of this repository.
 :)

(:~
: Returns a JSON representation of all Annotations of a document.
:
: @author <a href="mailto:roewenstrunk@edirom.de">Daniel Röwenstrunk</a>
: @author Benjamin W. Bohl <b.w.bohl@gmail.com>
:)


(: IMPORTS ================================================================= :)

import module namespace annotation = "http://www.edirom.de/xquery/annotation" at "../xqm/annotation.xqm";


(: NAMESPACE DECLARATIONS ================================================== :)

declare namespace mei = "http://www.music-encoding.org/ns/mei";

declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";

declare namespace request = "http://exist-db.org/xquery/request";


(: OPTION DECLARATIONS ===================================================== :)

declare option output:method "json";

declare option output:media-type "application/json";


(: VARIABLE DECLARATIONS =================================================== :)

declare variable $EDITION := request:get-parameter('edition', '');

declare variable $URI := request:get-parameter('uri', '');


(: XQUERY BODY ============================================================= :)

let $uri :=
    if (contains($URI, '#')) then
        (substring-before($URI, '#'))
    else
        ($URI)


let $annotations := annotation:annotationsToJSON($uri, $EDITION)

let $annotationFields := map:keys($annotations[1])

return
    map {
        'success': true(),
        'total': count(doc($uri)//mei:annot[@type = 'editorialComment']),
        'annotations': array {$annotations},
        'fields': $annotationFields,
    }
