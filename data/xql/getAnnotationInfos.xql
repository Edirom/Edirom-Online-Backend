xquery version "3.1";
(:
 : Copyright: For LICENSE-Details please refer to the LICENSE file in the root directory of this repository.
 :)


(: IMPORTS ================================================================= :)

import module namespace annotation = "http://www.edirom.de/xquery/annotation" at "../xqm/annotation.xqm";
import module namespace edition = "http://www.edirom.de/xquery/edition" at "../xqm/edition.xqm";
import module namespace eutil = "http://www.edirom.de/xquery/eutil" at "../xqm/eutil.xqm";
import module namespace taxonomy = "http://www.edirom.de/xquery/taxonomy" at "../xqm/taxonomy.xqm";


(: NAMESPACE DECLARATIONS ================================================== :)

declare namespace mei = "http://www.music-encoding.org/ns/mei";
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace request = "http://exist-db.org/xquery/request";


(: OPTION DECLARATIONS ===================================================== :)

declare option output:method "json";
declare option output:media-type "application/json";


(: VARIABLE DECLARATIONS =================================================== :)

declare variable $uri := request:get-parameter('uri', '');
declare variable $edition := request:get-parameter('edition', '');
declare variable $lang := request:get-parameter('lang', '');


(: FUNCTION DECLARATIONS =================================================== :)

(:~
 : Returns distinct list of catagories used be the submitted annotations
 :
 : @param $annots a sequence of annotation elements (usually mei:annot)
 :
 : @return a sequence of strings
 :
 : @deprecated This function will be deprecated with Edirom-Online-API 2.0.0
 :)
declare function local:getDistinctCategories($annots as element()*) as xs:string* {

    (: older Edirom Online models (pre MEI 4) :)
    let $oldCats := distinct-values($annots/mei:ptr[@type = "categories"]/replace(@target, '#', ''))

    (: MEI 4 and above Edirom Online model using @class and mei:taxonomy :)
    let $newCats :=
        distinct-values(
            for $annot in $annots
            return
                tokenize(replace(normalize-space($annot/@class), '#', ''), ' '))[contains(., 'annotation.category')]

    return
        distinct-values(($oldCats, $newCats)[string-length() gt 0])
};

(:~
 : Returns distinct list of annotation priorities used by the submitted annotations
 :
 : @param $annots a sequence of annotation elements (usually mei:annot)
 :
 : @return a sequence of strings
 :
 : @deprecated This function will be deprecated with Edirom-Online-API 2.0.0
 :)
declare function local:getDistinctPriorities($annots as element()*) as xs:string* {

    distinct-values(
        for $annot in $annots

        (: older Edirom Online models (pre MEI 4) :)
        let $oldLink := $annot/mei:ptr[@type = "priority"]/replace(@target, '#', '')

        (: MEI 4 and above Edirom Online model using @class and mei:taxonomy :)
        let $classes := tokenize(replace(normalize-space($annot/@class), '#', ''), ' ')

        let $newLink := $classes[starts-with(., 'ediromAnnotPrio')]

        return
            distinct-values(($oldLink, $newLink))[string-length(.) gt 0]
    )
};


(: QUERY BODY ============================================================== :)

let $mei := eutil:getDoc($uri)
let $editionCollection := edition:collection($edition)
let $annots :=
    $editionCollection//mei:annot[@type = 'editorialComment'][
        some $p in tokenize(normalize-space(@plist), '\s+')
        satisfies (if (contains($p, '#')) then substring-before($p, '#') else $p) = $uri
    ]
    | $mei//mei:annot[@type = 'editorialComment']

(: NOTE: the deprecated categories/priorities fields below still resolve their label elements
   collection-wide via id() over the whole edition, rather than per-reference via
   eutil:get-referenced-element like every other path. This is left as-is for now because the
   fields are slated for removal with Edirom-Online-API 2.0.0 and are superseded by the
   'taxonomies' array; when migrating or removing them, route resolution through the shared
   resolver for consistency. :)
let $categories :=
    for $category in local:getDistinctCategories($annots)
    let $categoryElement := ($editionCollection/id($category)[mei:label or mei:name])[1]
    let $name := eutil:getLocalizedName($categoryElement, edition:getLanguage($edition))
    order by $name
    return
        map {
            'id': $category,
            'name': $name
        }

let $prios :=
    for $priority in local:getDistinctPriorities($annots)
    let $name := annotation:getPriorityLabel(($editionCollection/id($priority)[mei:label or mei:name])[1])
    order by $name
    return
        map {
            'id': $priority,
            'name': $name
        }

let $taxonomiesArray :=
    annotation:get-referenced-categories-as-taxonomy-array($annots, ($mei, $editionCollection), $lang)

return
    map {
        (: TODO deprecate categories field with Edirom-Online-API 2.0.0 :)
        'categories': $categories,
        (: TODO deprecate priorities field with Edirom-Online-API 2.0.0 :)
        'priorities': $prios,
        'count': count($annots),
        'taxonomies': $taxonomiesArray
    }
