xquery version "3.1";
(:
 : For LICENSE-Details please refer to the LICENSE file in the root directory of this repository.
 :)

(:~
 : This module provides common functions for the Distributed Text Services API.
 :
 : @author Francesco Maccarini
 :)
module namespace dts-common = "http://www.edirom.de/api/dts-common";

(: VARIABLE DECLARATIONS ================================================== :)

(:~
 : Maps special resource aliases to internal application resources.
 :)
declare variable $dts-common:specialResourcesAliases as map(xs:string, xs:string) := map {
    "help_en": "xmldb:exist:///db/apps/Edirom-Online-Backend/help/help_en.xml",
    "help_de": "xmldb:exist:///db/apps/Edirom-Online-Backend/help/help_de.xml"
}; (: TODO: this is a temporary solution.
    There should be a collection also.
    Make them available to collection and navigation endopoints. :)

(: FUNCTION DECLARATIONS =================================================== :)

(:~
 : Resolves special resource aliases to their backing application resources.
 :
 : @param $resource The requested resource identifier
 : @return The resolved resource URI
 :)
declare function dts-common:resolveSpecialResourceAlias(
    $resource as xs:string?
) as xs:string {
    if (map:contains($dts-common:specialResourcesAliases, $resource)) then
        map:get($dts-common:specialResourcesAliases, $resource)
    else
        $resource
};

(:~
 : Selects nodes from the document only for those references that are actually covered by the supplied citation structure.
 :
 : @param $document The source document
 : @param $ref The reference value to resolve
 : @param $citationTree The citation tree used to locate matching nodes
 : @return A map containing the selected node and its citation structure
 :)
declare function dts-common:selectBasedOnCiteStructure(
    $document as node(),
    $ref as xs:string?,
    $citationTree as element(citeStructure)*
) as map(*)* {
    let $citeStructures := ($citationTree, $citationTree//citeStructure)
    for $citeStructure in $citeStructures
    let $match := normalize-space($citeStructure/@match)
    let $use := normalize-space($citeStructure/@use)
    let $matchName :=
        if (not($match)) then
            ()
        else
            resolve-QName($match, $citeStructure)
    let $selected :=
        if (not($match) or not($use) or not($ref)) then
            ()
        else
            let $attributeName :=
                if (starts-with($use, "@")) then
                    substring($use, 2)
                else
                    ()
            return
                if ($attributeName) then
                    $document//*[node-name(.) eq $matchName and string(@*[string(node-name(.)) eq $attributeName]) = $ref][1]
                else
                    ()
    return
        if ($selected) then
            map {
                "node": $selected,
                "citeStructure": $citeStructure
            }
        else
            ()
};

(:~
 : Builds a URI template for the collection endpoint, explicitly assigning
 : parameters whose values are supplied.
 :
 : @param $baseURL The base URL of the application
 : @param $id The collection or resource identifier
 : @param $page The requested result page
 : @param $nav The requested navigation direction
 : @return The collection endpoint URI template
 :)
declare function dts-common:buildCollectionURI(
    $baseURL as xs:string,
    $id as xs:string?,
    $page as xs:integer?,
    $nav as xs:string?
) as xs:string {
    let $parameters := map {
        "id": $id,
        "page": $page,
        "nav": $nav
    }
    let $parameterNames := ("id", "page", "nav")
    let $assignedParameters :=
        for $parameterName in $parameterNames
        let $value := map:get($parameters, $parameterName)
        where exists($value) and string($value) ne ""
        return $parameterName || "=" || string($value)
    let $templateParameters :=
        for $parameterName in $parameterNames
        let $value := map:get($parameters, $parameterName)
        where empty($value) or string($value) eq ""
        return $parameterName
    return
        $baseURL || "/api/collection/"
        || (if (exists($assignedParameters)) then "?" || string-join($assignedParameters, "&amp;") else "")
        || (if (exists($templateParameters)) then "{" || (if (exists($assignedParameters)) then "&amp;" else "?") || string-join($templateParameters, ",") || "}" else "")
};

(:~
 : Builds a URI template for the navigation endpoint, explicitly assigning
 : parameters whose values are supplied.
 :
 : @param $baseURL The base URL of the application
 : @param $resource The resource identifier
 : @param $ref The reference identifying a single citable unit
 : @param $start The start reference of a range
 : @param $end The end reference of a range
 : @param $down The requested traversal depth
 : @param $tree The citation tree identifier
 : @param $page The requested result page
 : @return The navigation endpoint URI template
 :)
declare function dts-common:buildNavigationURI(
    $baseURL as xs:string,
    $resource as xs:string?,
    $ref as xs:string?,
    $start as xs:string?,
    $end as xs:string?,
    $down as xs:integer?,
    $tree as xs:string?,
    $page as xs:integer?
) as xs:string {
    let $parameters := map {
        "resource": $resource,
        "ref": $ref,
        "start": $start,
        "end": $end,
        "down": $down,
        "tree": $tree,
        "page": $page
    }
    let $parameterNames := ("resource", "ref", "start", "end", "down", "tree", "page")
    let $assignedParameters :=
        for $parameterName in $parameterNames
        let $value := map:get($parameters, $parameterName)
        where exists($value) and string($value) ne ""
        return $parameterName || "=" || string($value)
    let $templateParameters :=
        for $parameterName in $parameterNames
        let $value := map:get($parameters, $parameterName)
        where empty($value) or string($value) eq ""
        return $parameterName
    return
        $baseURL || "/api/navigation/"
        || (if (exists($assignedParameters)) then "?" || string-join($assignedParameters, "&amp;") else "")
        || (if (exists($templateParameters)) then "{" || (if (exists($assignedParameters)) then "&amp;" else "?") || string-join($templateParameters, ",") || "}" else "")
};

(:~
 : Builds a URI template for the document endpoint, explicitly assigning
 : parameters whose values are supplied.
 :
 : @param $baseURL The base URL of the application
 : @param $resource The resource identifier
 : @param $ref The reference identifying a single citable unit
 : @param $start The start reference of a range
 : @param $end The end reference of a range
 : @param $tree The citation tree identifier
 : @param $mediaType The requested response media type
 : @param $lang The requested language
 : @param $idPrefix The prefix to add to output identifiers
 : @param $htmlProfile The requested HTML profile
 : @return The document endpoint URI template
 :)
declare function dts-common:buildDocumentURI(
    $baseURL as xs:string,
    $resource as xs:string?,
    $ref as xs:string?,
    $start as xs:string?,
    $end as xs:string?,
    $tree as xs:string?,
    $mediaType as xs:string?,
    $lang as xs:string?,
    $idPrefix as xs:string?,
    $htmlProfile as xs:string?
) as xs:string {
    let $parameters := map {
        "resource": $resource,
        "ref": $ref,
        "start": $start,
        "end": $end,
        "tree": $tree,
        "mediaType": $mediaType,
        "lang": $lang,
        "idPrefix": $idPrefix,
        "htmlProfile": $htmlProfile
    }
    let $parameterNames := ("resource", "ref", "start", "end", "tree", "mediaType", "lang", "idPrefix", "htmlProfile")
    let $assignedParameters :=
        for $parameterName in $parameterNames
        let $value := map:get($parameters, $parameterName)
        where exists($value) and string($value) ne ""
        return $parameterName || "=" || string($value)
    let $templateParameters :=
        for $parameterName in $parameterNames
        let $value := map:get($parameters, $parameterName)
        where empty($value) or string($value) eq ""
        return $parameterName
    return
        $baseURL || "/api/document/"
        || (if (exists($assignedParameters)) then "?" || string-join($assignedParameters, "&amp;") else "")
        || (if (exists($templateParameters)) then "{" || (if (exists($assignedParameters)) then "&amp;" else "?") || string-join($templateParameters, ",") || "}" else "")
};
