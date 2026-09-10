xquery version "3.1";
(:
 : For LICENSE-Details please refer to the LICENSE file in the root directory of this repository.
 :)

 (:~
 : This module implements the navigation endpoint for the Distributed Text Services API.
 :
 : @author Francesco Maccarini
 :)
module namespace dts-navigation = "http://www.edirom.de/api/dts-navigation";

(: IMPORTS ================================================================= :)

import module namespace eutil = "http://www.edirom.de/xquery/eutil" at "eutil.xqm";
import module namespace errors = "http://www.edirom.de/xquery/errors" at "errors.xqm";
import module namespace dts-util = "http://www.edirom.de/api/dts-util" at "dts-util.xqm";

(: NAMESPACE DECLARATIONS ================================================== :)

declare namespace array = "http://www.w3.org/2005/xpath-functions/array";
declare namespace json = "http://www.json.org";
declare namespace map = "http://www.w3.org/2005/xpath-functions/map";
declare namespace dts = "https://w3id.org/dts/api#";
declare namespace mei = "http://www.music-encoding.org/ns/mei";
declare namespace tei = "http://www.tei-c.org/ns/1.0";
declare namespace system = "http://exist-db.org/xquery/system";
declare namespace transform = "http://exist-db.org/xquery/transform";
declare namespace xhtml = "http://www.w3.org/1999/xhtml";
declare namespace request = "http://exist-db.org/xquery/request";


(: FUNCTION DECLARATIONS =================================================== :)

(:~
 : Returns all standard citation trees for the namespace of a document.
 :
 : @param $document The document for which to retrieve the citation trees.
 : @return The citation tree elements defined for the document namespace.
 :)
declare function dts-navigation:getCitationTrees($document as document-node()) as element()* {
    let $namespace := eutil:getNamespace($document/*)
    let $allTrees := eutil:getDoc($eutil:app-root || '/data/trees/citationTrees' || upper-case($namespace) || '.xml')/refsDecl/citeStructure
    return $allTrees
};

(:~
 : Builds an XML-based JSON representation of a DTS CiteStructure object.
 :
 : @param $citeStructure The citation structure to convert.
 : @return The CiteStructure object, including recursively converted child structures.
 :)
declare function dts-navigation:buildCiteStructureObject(
    $citeStructure as element(citeStructure)
) as element(citeStructure) {
    <citeStructure json:array="true">
        <type json:name="@type">CiteStructure</type>
        <citeType>{string($citeStructure/@unit)}</citeType>
        {
            for $childCiteStructure in $citeStructure/citeStructure
            return dts-navigation:buildCiteStructureObject($childCiteStructure)
        }
    </citeStructure>
};

(:
TODO: According to DTS specifications,
the behaiour of the identifier must be changed here
and in the document endpoint.

If a Resource has a single CitationTree,
that CitationTree object cannot have an identifier.
If a Resource has multiple CitationTrees,
then the first listed in citationTrees
is the default CitationTree and cannot have an identifier.
:)
(:~
 : Builds XML-based JSON representations of DTS CitationTree objects.
 :
 : @param $citationTrees The citation tree elements to convert.
 : @return The CitationTree objects, or an empty JSON array representation.
 :)
declare function dts-navigation:buildCitationTreesObjects(
    $citationTrees as element(citeStructure)*
) as element(citationTrees)* {
    if ($citationTrees) then
        for $citationTree in $citationTrees
        return
            <citationTrees json:array="true">
                <type json:name="@type">CitationTree</type>
                {
                    if ($citationTree/@xml:id) then
                        <identifier>{string($citationTree/@xml:id)}</identifier>
                    else
                        ()
                }
                {dts-navigation:buildCiteStructureObject($citationTree)}
            </citationTrees>
    else
        <citationTrees json:array="true"/>
};

(:~
 : Builds the XML-based JSON representation of a DTS Resource object.
 :
 : @param $document The document represented by the resource.
 : @param $resource The resource identifier.
 : @return The Resource object with endpoint URIs and citation trees.
 :)
declare function dts-navigation:buildResourceObject(
    $document as document-node(),
    $resource as xs:string
) as element(resource) {
    let $base-url := substring-before(request:get-url(), "/api")
    let $citationTreesXML := dts-navigation:getCitationTrees($document)
    let $resourceObject :=
        <resource>
            <id json:name="@id">{$resource}</id>
            <type json:name="@type">Resource</type>
            <collection>{dts-util:buildCollectionURI($base-url, $resource, (), ())}</collection>
            <navigation>{dts-util:buildNavigationURI($base-url, $resource, (), (), (), (), (), ())}</navigation>
            <document>{dts-util:buildDocumentURI($base-url, $resource, (), (), (), (), (), (), (), ())}</document>
            {dts-navigation:buildCitationTreesObjects($citationTreesXML)}
        </resource>
    return $resourceObject
};

(:~
 : Builds the child elements for the XML-based JSON representation of a DTS CitableUnit object.
 :
 : The supplied selection is the resolved node. The matched
 : citation structure determines the unit level and cite type. If the unit is
 : nested in the citation tree, its parent is resolved from the corresponding
 : ancestor element in the document.
 :
 : @param $selection The resolved node
 : @param $citationTree The citation structure for the resolved node
 : @param $ref The reference identifying the citable unit
 : @return The citable unit child elements containing its identifier, type, level, parent, and cite type
 :)
declare function dts-navigation:buildCitableUnitObject(
    $selection as node(),
    $citationTree as element(citeStructure),
    $ref as xs:string
) as element()* {
    let $level := count($citationTree/ancestor::citeStructure) + 1
    let $parentCiteStructure := $citationTree/parent::citeStructure
    let $parentId :=
        if ($level eq 1) then
            ()
        else
            let $parentMatch := normalize-space($parentCiteStructure/@match)
            let $parentElementName := resolve-QName($parentMatch, $parentCiteStructure)
            return
                string($selection/ancestor::*[node-name(.) eq $parentElementName][1]/@xml:id)
    return (
        <identifier>{string($ref)}</identifier>,
        <type json:name="@type">CitableUnit</type>,
        <level json:literal="true">{$level}</level>,
        <parent>{$parentId}</parent>,
        <citeType>{string($citationTree/@unit)}</citeType>
    )
};

(:~
 : Builds a flat sequence of CitableUnit members by traversing citation levels.
 : Selected elements are starting units; a document supplies all matching starting units.
 : Members are emitted parent-first, with units at each traversal step in document order.
 : Descendants belonging to a nested unit of the same parent type are excluded.
 :
 : @param $selection The document or already-selected citable elements
 : @param $citeStructure The starting citation structures, retaining their tree ancestors
 : @param $down The number of included levels: 1 includes only the starting level,
 :              -1 includes all levels, and 0 or an empty value includes none
 : @return Individual member elements, each containing one CitableUnit
 :)
declare function dts-navigation:buildMemberArray(
    $selection as node()*,
    $citeStructure as element(citeStructure)*,
    $down as xs:integer?
) as element()* {
    if (empty($down) or $down eq 0) then
        ()
    else
        for $node in $selection/self::node()
        return
            typeswitch ($node)
                case document-node() return
                    dts-navigation:buildMemberArray($node/descendant::*, $citeStructure, $down)
                case element() return
                    for $currentCiteStructure in $citeStructure
                    let $match := normalize-space($currentCiteStructure/@match)
                    let $elementName :=
                        if ($match) then resolve-QName($match, $currentCiteStructure) else ()
                    where node-name($node) eq $elementName
                    return (
                        <member json:array="true">
                            {dts-navigation:buildCitableUnitObject($node, $currentCiteStructure, string($node/@xml:id))}
                        </member>,
                        if (($down eq -1 or $down gt 1) and exists($currentCiteStructure/citeStructure)) then
                            let $children := $node/descendant::*[
                                ancestor::*[node-name(.) eq $elementName][1] is $node
                            ]
                            let $nextDown := if ($down eq -1) then -1 else $down - 1
                            return
                                dts-navigation:buildMemberArray($children, $currentCiteStructure/citeStructure, $nextDown)
                        else
                            ()
                    )
                default return
                    ()
};

(:~
 : Builds member objects for the ref and down=0 special case.
 :
 : If $down = 0 and $ref is present, information about the CitableUnit
 : identified by ref along with a member property that is an array
 : of CitableUnits that are siblings (sharing the same parent),
 : including the current CitableUnit identified by ref.
 :
 : @param $selection The referenced node
 : @param $citeStructure The citation structure for the referenced node
 : @return Matching XML siblings, including the referenced unit, in document order
 :)
declare function dts-navigation:buildMemberArrayRefDownZero(
    $selection as node(),
    $citeStructure as element(citeStructure)
) as element()* {
    let $elementName := resolve-QName(normalize-space($citeStructure/@match), $citeStructure)
    let $siblings := $selection/parent::node()/*[
        node-name(.) eq $elementName
    ]
    for $sibling in $siblings
    return
        <member json:array="true">
            {dts-navigation:buildCitableUnitObject($sibling, $citeStructure, string($sibling/@xml:id))}
        </member>
};

(:~
 : Returns the navigation structure for a given resource.
 :
 : @param $resource The resource for which to retrieve the navigation structure.
 : @param $ref The reference point within the resource (optional).
 : @param $start The starting point of the navigation (optional).
 : @param $end The ending point of the navigation (optional).
 : @param $down The depth of the navigation tree (optional).
 : @param $tree The citation tree identifier to use (optional).
 : @param $page The number of identifying a page in paginated query results (optional).
 :)
declare function dts-navigation:navigation(
    $resource as xs:string,
    $ref as xs:string?,
    $start as xs:string?,
    $end as xs:string?,
    $down as xs:integer?,
    $tree as xs:string?,
    $page as xs:integer?
) as element(json:value) {
    if ($ref and ($start or $end)) then
        error($errors:INVALID_PARAMETERS, "The 'ref' parameter cannot be used together with 'start' or 'end'.")
    else if (($start and not($end)) or ($end and not($start))) then
        error($errors:INVALID_PARAMETERS, "Both 'start' and 'end' parameters must be provided together.")
    else if (not($down) and not($ref) and not($start) and not($end)) then
        error($errors:INVALID_PARAMETERS, "At least one of 'ref', 'start/end', or 'down' parameters must be provided.")
    else if ($down eq 0 and not($ref)) then
        error($errors:INVALID_PARAMETERS, "The 'down' parameter cannot be 0 when no 'ref' parameter is provided.")
    else if ($down lt -1) then
        error($errors:INVALID_PARAMETERS, "The 'down' parameter must be -1 or greater.")  
    else
        let $resource := dts-util:resolveSpecialResourceAlias($resource)
        let $document := eutil:getDoc($resource)/root()
        let $document :=
            if ($document) then
                eutil:add-xml-ids($document)
            else
                error($errors:NOT_FOUND, "The requested resource was not found.")
        let $namespace := eutil:getNamespace($document/*)
        let $citationTree := eutil:getDoc($eutil:app-root || '/data/trees/citationTrees' || upper-case($namespace) || '.xml')/refsDecl/citeStructure[
            not($tree) or @xml:id = $tree
        ]
        let $boundaryUnits :=
            if ($ref) then
                let $selection := dts-util:selectBasedOnCiteStructure($document, $ref, $citationTree)
                let $citeStructure := dts-util:getCiteStructureForNode($selection, $citationTree)
                return
                    <ref>
                        {dts-navigation:buildCitableUnitObject($selection, $citeStructure, $ref)}
                    </ref>
            else if ($start and $end) then
                let $startSelection := dts-util:selectBasedOnCiteStructure($document, $start, $citationTree)
                let $endSelection := dts-util:selectBasedOnCiteStructure($document, $end, $citationTree)
                let $startCiteStructure := dts-util:getCiteStructureForNode($startSelection, $citationTree)
                let $endCiteStructure := dts-util:getCiteStructureForNode($endSelection, $citationTree)
                return (
                    <start>
                        {dts-navigation:buildCitableUnitObject($startSelection, $startCiteStructure, $start)}
                    </start>,
                    <end>
                        {dts-navigation:buildCitableUnitObject($endSelection, $endCiteStructure, $end)}
                    </end>
                )
            else
                ()

        let $member :=
            if (not(exists($down))) then
                ()
            (: If $down = 0 and $ref is present -> special case :)
            else if ($down eq 0 and $ref) then
                let $selection := dts-util:selectBasedOnCiteStructure($document, $ref, $citationTree)
                let $citeStructure := dts-util:getCiteStructureForNode($selection, $citationTree)
                return
                    dts-navigation:buildMemberArrayRefDownZero($selection, $citeStructure)
            else if (not($ref) and not($start) and not($end)) then
                dts-navigation:buildMemberArray($document, $citationTree, $down)
            else
                let $selection := dts-util:selectElementOrRange($document, $ref, $start, $end, $citationTree)
                let $citeStructure := dts-util:getCiteStructureForNode($selection, $citationTree)
                return
                    dts-navigation:buildMemberArray($selection, $citeStructure, $down)

        let $resourceObject := dts-navigation:buildResourceObject($document, $resource)
        let $output :=
            <json:value>
                <context json:name="@context">https://dtsapi.org/context/v1.0.json</context>
                <dtsVersion>1.0</dtsVersion>
                <id json:name="@id">{request:get-url()}</id>
                <type json:name="@type">Navigation</type>
                {$resourceObject}
                {$boundaryUnits}
                {$member}
            </json:value>

        return $output
};