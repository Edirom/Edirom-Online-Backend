xquery version "3.1";
(:
 : For LICENSE-Details please refer to the LICENSE file in the root directory of this repository.
 :)

(:~
 : This module provides common functions for the Distributed Text Services API.
 :
 : @author Francesco Maccarini
 :)
module namespace dts-util = "http://www.edirom.de/api/dts-util";

import module namespace eutil = "http://www.edirom.de/xquery/eutil" at "eutil.xqm";
import module namespace errors = "http://www.edirom.de/xquery/errors" at "errors.xqm";

declare namespace tei = "http://www.tei-c.org/ns/1.0";
declare namespace transform = "http://exist-db.org/xquery/transform";

(: VARIABLE DECLARATIONS ================================================== :)

(:~
 : Maps special resource aliases to internal application resources.
 :)
declare variable $dts-util:specialResourcesAliases as map(xs:string, xs:string) := map {
    "help_en": "xmldb:exist:///db/apps/Edirom-Online-Backend/help/help_en.xml",
    "help_de": "xmldb:exist:///db/apps/Edirom-Online-Backend/help/help_de.xml"
}; (: TODO: this is a temporary solution.
    There should be a collection also.
    Make them available to collection and navigation endopoints. :)

(:~
 : Lists MEI elements that must always be preserved for every endpoint request.
 :)
declare variable $dts-util:alwaysPreserveMEIElements as xs:QName* := (
    QName("http://www.music-encoding.org/ns/mei", "meiHead")
);

(:~
 : Lists TEI elements that must always be preserved for every endpoint request.
 :)
declare variable $dts-util:alwaysPreserveTEIElements as xs:QName* := (
    QName("http://www.tei-c.org/ns/1.0", "teiHeader")
);

(: FUNCTION DECLARATIONS =================================================== :)

(:~
 : Resolves special resource aliases to their backing application resources.
 :
 : @param $resource The requested resource identifier
 : @return The resolved resource URI
 :)
declare function dts-util:resolveSpecialResourceAlias(
    $resource as xs:string?
) as xs:string {
    if (map:contains($dts-util:specialResourcesAliases, $resource)) then
        map:get($dts-util:specialResourcesAliases, $resource)
    else
        $resource
};

(:~
 : Selects nodes from the document only for those references that are actually covered by the supplied citation structure.
 :
 : @param $document The source document
 : @param $ref The reference value to resolve
 : @param $citationTree The citation tree used to locate matching nodes
 : @return The selected elements covered by the supplied citation structure
 :)
declare function dts-util:selectBasedOnCiteStructure(
    $document as node(),
    $ref as xs:string?,
    $citationTree as element(citeStructure)*
) as element()* {
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
        $selected
};

(:~
 : Checks whether the supplied elements match a citation structure in the given citation tree.
 :
 : @param $elements The elements to test
 : @param $citationTree The citation tree to check against
 : @return `true()` when the elements are part of the citation tree, otherwise `false()`
 :)
declare function dts-util:isInCitationTree(
    $elements as element()*,
    $citationTree as element(citeStructure)*
) as xs:boolean {
    some $citeStructure in ($citationTree, $citationTree//citeStructure)
        satisfies dts-util:matchesCitationStructure($elements, $citeStructure)
};

(:~
 : Tests whether a selection consists only of elements that should always be preserved.
 :
 : @param $elements The elements to test
 : @return `true()` if all supplied elements are in the list of always preserved elements, otherwise `false()`
 :)
declare function dts-util:isAlwaysPreservedSelection(
    $elements as element()*
) as xs:boolean {
    every $node in $elements satisfies node-name($node) = $dts-util:alwaysPreserveMEIElements or node-name($node) = $dts-util:alwaysPreserveTEIElements
};

(:~
 : Tests whether the supplied elements match a single citation structure definition.
 :
 : @param $elements The elements to test
 : @param $citeStructure The citation structure definition to compare against
 : @return `true()` when the elements match the citation structure, otherwise `false()`
 :)
declare function dts-util:matchesCitationStructure(
    $elements as element()*,
    $citeStructure as element(citeStructure)
) as xs:boolean {
    let $match := normalize-space($citeStructure/@match)
    let $matchName :=
        if (not($match)) then
            ()
        else
            resolve-QName($match, $citeStructure)
    return
        exists($matchName)
        and (every $node in $elements satisfies node-name($node) eq $matchName)
};

(:~
 : Selects a TEI page range between the supplied page breaks.
 :
 : @param $document The source document
 : @param $startPb The starting page break element
 : @param $endPb The ending page break element, if present
 : @return The page content selected between the supplied boundaries
 :)
declare function dts-util:selectTEIPages(
    $document as node(),
    $startPb as node()*,
    $endPb as node()*
) as node()* {
    let $nextPb :=
        if ($endPb) then
            ($endPb/following::tei:pb)[1]
        else
            ($startPb/following::tei:pb)[1]
    let $pb1 := $startPb/@xml:id
    let $pb2 :=
        if ($nextPb) then
            $nextPb/@xml:id
        else
            ''
    let $commonAncestorID :=
        if ($nextPb) then
            ($startPb/ancestor-or-self::*[. intersect $nextPb/ancestor-or-self::*])[last()]/@xml:id
        else
            ($startPb/ancestor-or-self::*[. intersect (($document//text())[last()])/ancestor-or-self::*])[last()]/@xml:id
    let $reduced :=
        transform:transform($document, eutil:getDoc($eutil:xsltBase || '/reduceToPageById.xsl'),
            <parameters>
                <param name="pb1_id" value="{$pb1}"/>
                <param name="pb2_id" value="{$pb2}"/>
            </parameters>
        )
    return
        $reduced/descendant-or-self::*[@xml:id = $commonAncestorID]/*
};

(:~
 : Resolves a document selection from a reference or a start/end pair, matching a given citation structure.
 :
 : @param $document The source document
 : @param $ref An optional reference to select a single unit
 : @param $start The optional start reference of a range
 : @param $end The optional end reference of a range
 : @param $citationTree The citation tree used to validate the selection
 : @return The selected nodes or range content
 :)
declare function dts-util:selectElementOrRange(
    $document as node(),
    $ref as xs:string?,
    $start as xs:string?,
    $end as xs:string?,
    $citationTree as element(citeStructure)*
) as node()* {
    if ($ref) then
        let $citeStructureSelection := dts-util:selectBasedOnCiteStructure($document, $ref, $citationTree)
        let $candidateSelection :=
            if ($citeStructureSelection) then
                $citeStructureSelection
            else
                $document//*[local-name() = $ref]
        return
            if (
                $candidateSelection and
                (dts-util:isInCitationTree($candidateSelection, $citationTree)
                or dts-util:isAlwaysPreservedSelection($candidateSelection)) 
                and node-name($candidateSelection[1]) eq QName("http://www.tei-c.org/ns/1.0", "pb")
            ) then
                dts-util:selectTEIPages($document, $candidateSelection, ())
            else if (
                $candidateSelection and
                (dts-util:isInCitationTree($candidateSelection, $citationTree)
                or dts-util:isAlwaysPreservedSelection($candidateSelection))
            ) then
                $candidateSelection
            else if ($candidateSelection) then
                error($errors:INVALID_PARAMETERS, "The selected citable units are not part of the citation tree specified for this document and are not part of the always preserved elements." || "Citation tree: " || string-join($citationTree/@xml:id, ", ") || ". Selected element: " || node-name($candidateSelection[1]) || ", Selected element @xml:id: " || $candidateSelection[1]/@xml:id)
            else
                error($errors:NOT_FOUND, "The specified citable units did not match any element in the document for the specified citation tree.")
    else if ($start and $end) then
        let $candidateStartNode := dts-util:selectBasedOnCiteStructure($document, $start, $citationTree)
        let $candidateEndNode := dts-util:selectBasedOnCiteStructure($document, $end, $citationTree)
        let $startNode :=
            if (
                $candidateStartNode and
                dts-util:isInCitationTree($candidateStartNode, $citationTree)
            ) then
                $candidateStartNode
            else if ($candidateStartNode) then
                error($errors:INVALID_PARAMETERS, "The selected start citable unit is not part of the citation tree specified for this document." || "Citation tree: " || string-join($citationTree/@xml:id, ", ") || ". Selected element: " || node-name($candidateStartNode[1]) || ", Selected element @xml:id: " || $candidateStartNode[1]/@xml:id)
            else
                error($errors:NOT_FOUND, "The specified start citable unit did not match any element in the document for the specified citation tree.")
        let $endNode :=
            if (
                $candidateEndNode and 
                dts-util:isInCitationTree($candidateEndNode, $citationTree)
            ) then
                $candidateEndNode
            else if ($candidateEndNode) then
                error($errors:INVALID_PARAMETERS, "The selected end citable unit is not part of the citation tree specified for this document." || "Citation tree: " || string-join($citationTree/@xml:id, ", ") || ". Selected element: " || node-name($candidateEndNode[1]) || ", Selected element @xml:id: " || $candidateEndNode[1]/@xml:id)
            else
                error($errors:NOT_FOUND, "The specified end citable unit did not match any element in the document for the specified citation tree.")
        return
            if (node-name($startNode[1]) eq QName("http://www.tei-c.org/ns/1.0", "pb")
                and node-name($endNode[1]) eq QName("http://www.tei-c.org/ns/1.0", "pb")
            ) then
                dts-util:selectTEIPages($document, $startNode, $endNode)
            else if ($start eq $end) then
                $startNode
            else if (not($startNode/parent::* is $endNode/parent::*)) then
                error($errors:INVALID_PARAMETERS, "The start and end citable units must have the same parent, or be page break elements." || "Selected start element: " || node-name($startNode[1]) || ", Selected start element @xml:id: " || $startNode[1]/@xml:id || ". Selected end element: " || node-name($endNode[1]) || ", Selected end element @xml:id: " || $endNode[1]/@xml:id)
            else if ($startNode << $endNode) then
                (
                    $startNode, 
                    $startNode/following-sibling::*[. << $endNode], 
                    $endNode
                )
            else
                error($errors:INVALID_PARAMETERS, "Invalid start and end citable units. The start node must come before the end node. Start: " || $start || ", End: " || $end)
    else
        ()
};

(:~
 : Returns citation structures whose match QName matches the supplied node.
 : All matching structures are returned; ambiguous matches are not reduced to the first result.
 : This uses the currently supported QName-based matches, not hierarchical XPath expressions.
 :
 : @param $node The selected element
 : @param $citationTree The citation trees to search, including their descendant structures
 : @return The matching citation structures, or an empty sequence when none match
 :)
declare function dts-util:getCiteStructureForNode(
    $node as element(),
    $citationTree as element(citeStructure)*
) as element(citeStructure)* {
    let $citeStructures := ($citationTree, $citationTree//citeStructure)
    for $citeStructure in $citeStructures
    let $match := normalize-space($citeStructure/@match)
    let $matchName :=
        if ($match) then
            resolve-QName($match, $citeStructure)
        else
            ()
    where node-name($node) eq $matchName
    return
        $citeStructure
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
declare function dts-util:buildCollectionURI(
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
declare function dts-util:buildNavigationURI(
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
declare function dts-util:buildDocumentURI(
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
