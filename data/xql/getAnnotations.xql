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
import module namespace eutil = "http://www.edirom.de/xquery/eutil" at "../xqm/eutil.xqm";


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
declare variable $MODE := request:get-parameter('mode', '');


(: QUERY BODY ============================================================= :)

let $uri :=
    if (contains($URI, '#')) then
        (substring-before($URI, '#'))
    else
        ($URI)

let $doc := eutil:getDoc($uri)

let $annotations := annotation:annotationsToJSON($uri, $EDITION, $MODE)

let $annotationFields := distinct-values(for $a in $annotations return map:keys($a))

let $emptyFields :=
    for $fieldName in $annotationFields
    where every $annotation in $annotations satisfies (
        map:contains($annotation, $fieldName) and eutil:is-empty($annotation($fieldName))
    )
    return array { $fieldName }

let $baseMap := map {
    'success': true(),
    'total': count($doc//mei:annot[@type = 'editorialComment']),
    'annotations': array {$annotations}
}

(: the flattened 'categories'/'priority' fields are omitted by annotation:annotationsToJSON
   whenever the document's classification is fully expressible as taxonomy fields, so their
   presence in 'fields' is the signal for consumers — no separate 'legacyFields' key needed :)
let $taxonomiesMap := map {
    'fields': $annotationFields,
    'emptyFields': $emptyFields
}

(: Return the appropriate result based on the mode :)
return
    if($MODE eq 'taxonomies') then (
        map:merge((
            $baseMap,
            $taxonomiesMap
        ))
    )
    else (
        $baseMap
    )
