xquery version "3.1";
(:
 : For LICENSE-Details please refer to the LICENSE file in the root directory of this repository.
 :)

 (:~
 : This module implements the document endpoint for the Distributed Text Services API.
 :
 : @author Francesco Maccarini
 :)
module namespace dts-document = "http://www.edirom.de/api/dts-document";

(: IMPORTS ================================================================= :)

import module namespace eutil = "http://www.edirom.de/xquery/eutil" at "eutil.xqm";
import module namespace errors = "http://www.edirom.de/xquery/errors" at "errors.xqm";

(: NAMESPACE DECLARATIONS ================================================== :)

declare namespace dts = "https://w3id.org/dts/api#";
declare namespace mei = "http://www.music-encoding.org/ns/mei";
declare namespace tei = "http://www.tei-c.org/ns/1.0";
declare namespace system = "http://exist-db.org/xquery/system";
declare namespace transform = "http://exist-db.org/xquery/transform";
declare namespace xhtml = "http://www.w3.org/1999/xhtml";
declare namespace request = "http://exist-db.org/xquery/request";

(: VARIABLE DECLARATIONS ================================================== :)

(:~
 : Lists MEI elements that must always be preserved for every endpoint request.
 :)
declare variable $dts-document:alwaysPreserveMEIElements as xs:QName* := (
    QName("http://www.music-encoding.org/ns/mei", "meiHead")
);

(:~
 : Lists TEI elements that must always be preserved for every endpoint request.
 :)
declare variable $dts-document:alwaysPreserveTEIElements as xs:QName* := (
    QName("http://www.tei-c.org/ns/1.0", "teiHeader")
);

(:~
 : Lists MEI elements that are preserved when they precede a selected sibling structure.
 :)
declare variable $dts-document:preserveIfPrecedingSiblingsMEIElements as xs:QName* := (
    QName("http://www.music-encoding.org/ns/mei", "scoreDef"),
    QName("http://www.music-encoding.org/ns/mei", "staffGrp"),
    QName("http://www.music-encoding.org/ns/mei", "staffDef"),
    QName("http://www.music-encoding.org/ns/mei", "layerDef"),
    QName("http://www.music-encoding.org/ns/mei", "clef"),
    QName("http://www.music-encoding.org/ns/mei", "clefGrp"),
    QName("http://www.music-encoding.org/ns/mei", "keySig"),
    QName("http://www.music-encoding.org/ns/mei", "keyAccid"),
    QName("http://www.music-encoding.org/ns/mei", "label"),
    QName("http://www.music-encoding.org/ns/mei", "meterSig"),
    QName("http://www.music-encoding.org/ns/mei", "meterSigGrp"),
    QName("http://www.music-encoding.org/ns/mei", "graphic")
);

(:~
 : Lists attributes whose referenced target elements should be followed.
 : In an xml response, the elements referenced by these attributes will be included in the result set of the document endpoint even if outside the selection wrapped by dts:wrapper.
 : In a json response, the references will be resolved and the referenced elements will be included in the result set of the document endpoint in place.
 :)
declare variable $dts-document:followReferenceAttributes as xs:QName* := (
    QName("", "facs")
);

(:~
 : Maps special resource aliases to internal application resources.
 :)
declare variable $dts-document:specialResourcesAliases as map(xs:string, xs:string) := map {
    "help_en": "xmldb:exist:///db/apps/Edirom-Online-Backend/help/help_en.xml",
    "help_de": "xmldb:exist:///db/apps/Edirom-Online-Backend/help/help_de.xml"
}; (: TODO: this is a temporary solution.
    There should be a collection also.
    Make them available to collection and navigation endopoints. :)

(:~
 : Denotes the default HTML profile used when no profile is requested.
 :)
declare variable $dts-document:defaultHTMLProfile as xs:string := "edirom-text";

(:~
 : Maps HTML profile identifiers to the transformation parameters used for them.
 :)
declare variable $dts-document:htmlProfiles as map(xs:string, element(param)*) := map {
    "edirom-text": (
        <param name="footnoteBackLink" value="true"/>,
        <param name="autoHead" value="false"/>,
        <param name="autoToc" value="false"/>,
        <param name="numberHeadings" value="false"/>
    ),
    "edirom-help": (
        <param name="tocDepth" value="1"/>
    ),
    "edirom-header": ()
};

(: FUNCTION DECLARATIONS =================================================== :)

(:~
 : Returns the parameter nodes for the requested HTML profile.
 :
 : @param $htmlProfile The requested HTML profile name
 : @return The parameters associated with the requested profile
 :)
declare function dts-document:htmlProfileParameters(
    $htmlProfile as xs:string?
) as element(param)* {
    let $profile :=
        if ($htmlProfile and map:contains($dts-document:htmlProfiles, $htmlProfile)) then
            $htmlProfile
        else
            error($errors:INVALID_PARAMETERS, "The specified HTML profile is not supported. Supported profiles are: " || string-join(map:keys($dts-document:htmlProfiles), ", ") || ". Specified profile: " || $htmlProfile)
    return
        map:get($dts-document:htmlProfiles, $profile)
};

(:~
 : Wraps the selected nodes in place while preserving any required surrounding or referenced content.
 :
 : @param $selection The selected elements to wrap
 : @param $document The source document containing the selection
 : @return The wrapped document fragment with the selected content kept in its original location and any required context preserved outside the wrapper
 :)
declare function dts-document:wrapSelection(
    $selection as element()*,
    $document as node()
) as node()? {
    let $alwaysPreserved := $document//*[node-name(.) = $dts-document:alwaysPreserveMEIElements or node-name(.) = $dts-document:alwaysPreserveTEIElements]
    let $baseFullCopyNodes := ($selection, $alwaysPreserved)
    let $referencedNodes := dts-document:referenceClosure($document, $baseFullCopyNodes)
    let $referencingMeasures := dts-document:getMeasuresReferencingSelectedZones($document, $selection)
    let $preserveIfPrecedingSiblings := dts-document:preserveIfPrecedingSiblingNodes(($referencedNodes, $referencedNodes/ancestor::*, $referencingMeasures, $referencingMeasures))
    let $fullCopyNodes := dts-document:referenceClosure($document, ($referencedNodes, $referencingMeasures, $preserveIfPrecedingSiblings))
    let $keptNodes := ($fullCopyNodes, $fullCopyNodes/ancestor::*)
    return
        dts-document:copySelection($document/*, $selection, $fullCopyNodes, $keptNodes)
};

(:~
 : Tests whether a node matches one of the supplied candidate nodes by identity or XML id.
 : This is used while copying and wrapping a selection.
 :
 : @param $node The node to test
 : @param $candidates The candidate nodes to compare against
 : @return `true()` when the node matches a candidate, otherwise `false()`
 :)
declare function dts-document:matchesNode(
    $node as element(),
    $candidates as element()*
) as xs:boolean {
    some $candidate in $candidates
        satisfies $node is $candidate
        or (
            $node/@xml:id
            and $candidate/@xml:id
            and string($node/@xml:id) eq string($candidate/@xml:id)
        )
};

(:~
 : Collects sibling elements that must be preserved because they precede the kept nodes.
 :
 : @param $keptNodes The nodes that remain in the wrapped result
 : @return The preceding sibling nodes that need to be preserved
 :)
declare function dts-document:preserveIfPrecedingSiblingNodes(
    $keptNodes as element()*
) as element()* {
    $keptNodes/preceding-sibling::*[node-name(.) = $dts-document:preserveIfPrecedingSiblingsMEIElements]
};

(:~
 : Recursively includes referenced nodes in the result set until no new references remain.
 :
 : @param $document The source document
 : @param $nodes The initial nodes to expand
 : @return The closure of the supplied nodes and their referenced targets
 :)
declare function dts-document:referenceClosure(
    $document as node(),
    $nodes as element()*
) as element()* {
    let $referencedIds := dts-document:localReferenceIds($nodes)
    let $referencedNodes := $document/id($referencedIds)
    let $newNodes := $referencedNodes except $nodes
    return
        if (empty($newNodes)) then
            $nodes
        else
            dts-document:referenceClosure($document, ($nodes, $referencedNodes))
};

(:~
 : Extracts local reference identifiers from the supplied nodes and their attributes.
 :
 : @param $nodes The nodes from which to collect references
 : @return The distinct local reference ids found in the selected attributes
 :)
declare function dts-document:localReferenceIds(
    $nodes as element()*
) as xs:string* {
    distinct-values(
        for $attribute in ($nodes/@*, $nodes//@*)[node-name(.) = $dts-document:followReferenceAttributes]
        return dts-document:localReferenceIdsFromAttributes($attribute)
    )
};

(:~
 : Extracts local reference identifiers from a sequence of attributes.
 :
 : @param $attributes The attributes to inspect for fragment references
 : @return The distinct local reference ids found in those attributes
 :)
declare function dts-document:localReferenceIdsFromAttributes(
    $attributes as attribute()*
) as xs:string* {
    distinct-values(
        for $attribute in $attributes
        for $token in tokenize(normalize-space(string($attribute)), "\s+")
        where starts-with($token, "#") and matches(substring($token, 2), "^[A-Za-z_][A-Za-z0-9_.-]*$")
        return substring($token, 2)
    )
};

(:~
 : Copies a selection tree while retaining the required nodes and wrapping selected children.
 :
 : @param $node The current node in the source tree
 : @param $selection The selected elements to copy
 : @param $fullCopyNodes Nodes that should be reproduced in full
 : @param $keptNodes Nodes that should be retained as context
 : @return The copied node tree for the selection
 :)
declare function dts-document:copySelection(
    $node as node(),
    $selection as element()*,
    $fullCopyNodes as element()*,
    $keptNodes as element()*
) as node()* {
    typeswitch ($node)
        case element() return
            if (dts-document:matchesNode($node, $fullCopyNodes)) then
                $node
            else if (dts-document:matchesNode($node, $keptNodes)) then
                element { node-name($node) } {
                    namespace { "xlink" } { "http://www.w3.org/1999/xlink" },
                    $node/@*,
                    dts-document:copySelectedChildren($node, $selection, $fullCopyNodes, $keptNodes)
                }
            else
                ()
        default return
            $node
};

(:~
 : Copies the children of a node and wraps the first selected child with a DTS wrapper.
 :
 : @param $node The parent element whose children are being processed
 : @param $selection The selected elements to expose
 : @param $fullCopyNodes Nodes that should be reproduced in full
 : @param $keptNodes Nodes that should be retained as context
 : @return The copied child nodes with wrappers where needed
 :)
declare function dts-document:copySelectedChildren(
    $node as element(),
    $selection as element()*,
    $fullCopyNodes as element()*,
    $keptNodes as element()*
) as node()* {
    for $child in $node/node()
    let $selectedChildren := $child/self::element()[dts-document:matchesNode(., $selection)]
    let $isFirstSelectedChild :=
        exists($selectedChildren)
        and empty($child/preceding-sibling::*[dts-document:matchesNode(., $selection)])
    return
        if ($isFirstSelectedChild) then
            <dts:wrapper xmlns:dts="https://w3id.org/dts/api#">{
                $selection
            }</dts:wrapper>
        else if (exists($selectedChildren)) then
            ()
        else
            dts-document:copySelection($child, $selection, $fullCopyNodes, $keptNodes)
};

(:~
 : Finds measures that reference the selected zones and therefore need to be preserved.
 :
 : @param $document The source document
 : @param $selection The selected elements, potentially including zones
 : @return The measures that reference the selected zones
 :)
declare function dts-document:getMeasuresReferencingSelectedZones(
    $document as node(),
    $selection as element()*
) as element()* {
    for $zone in ($selection[self::mei:zone[@type = 'measure']] | $selection//mei:zone[@type = 'measure'])
    let $zoneRef := concat('#', $zone/@xml:id)
    (:
        The first predicate with `contains` is just a rough estimate to narrow down the result set.
        It uses the index and is fast while the second (exact) predicate is generally too slow
    :)
    let $measures := $document//mei:measure[contains(@facs, $zoneRef)][$zoneRef = tokenize(@facs, '\s+')]
    return
        $measures
};

(:~
 : Checks whether the supplied elements match a citation structure in the given citation tree.
 :
 : @param $elements The elements to test
 : @param $citationTree The citation tree to check against
 : @return `true()` when the elements are part of the citation tree, otherwise `false()`
 :)
declare function dts-document:isInCitationTree(
    $elements as element()*,
    $citationTree as element(citeStructure)*
) as xs:boolean {
    some $citeStructure in ($citationTree, $citationTree//citeStructure)
        satisfies dts-document:matchesCitationStructure($elements, $citeStructure)
};

(:~
 : Tests whether a selection consists only of elements that should always be preserved.
 :
 : @param $elements The elements to test
 : @return `true()` if all supplied elements are in the list of always preserved elements, otherwise `false()`
 :)
declare function dts-document:isAlwaysPreservedSelection(
    $elements as element()*
) as xs:boolean {
    every $node in $elements satisfies node-name($node) = $dts-document:alwaysPreserveMEIElements or node-name($node) = $dts-document:alwaysPreserveTEIElements
};

(:~
 : Tests whether the supplied elements match a single citation structure definition.
 :
 : @param $elements The elements to test
 : @param $citeStructure The citation structure definition to compare against
 : @return `true()` when the elements match the citation structure, otherwise `false()`
 :)
declare function dts-document:matchesCitationStructure(
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
 :)declare function dts-document:selectTEIPages(
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
 : Selects nodes from the document only for those references that are actually covered by the supplied citation structure.
 :
 : @param $document The source document
 : @param $ref The reference value to resolve
 : @param $citationTree The citation tree used to locate matching nodes
 : @return The selected nodes matching the supplied citation definition
 :)
declare function dts-document:selectBasedOnCiteStructure(
    $document as node(),
    $ref as xs:string?,
    $citationTree as element(citeStructure)*
) as node()* {
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
 : Resolves a document selection from a reference or a start/end pair, matching a given citation structure.
 :
 : @param $document The source document
 : @param $ref An optional reference to select a single unit
 : @param $start The optional start reference of a range
 : @param $end The optional end reference of a range
 : @param $citationTree The citation tree used to validate the selection
 : @return The selected nodes or range content
 :)
declare function dts-document:selectElementOrRange(
    $document as node(),
    $ref as xs:string?,
    $start as xs:string?,
    $end as xs:string?,
    $citationTree as element(citeStructure)*
) as node()* {
    if ($ref) then
        let $citeStructureSelection := dts-document:selectBasedOnCiteStructure($document, $ref, $citationTree)
        let $candidateSelection :=
            if ($citeStructureSelection) then
                $citeStructureSelection
            else
                $document//*[local-name() = $ref]
        return
            if (
                $candidateSelection and
                (dts-document:isInCitationTree($candidateSelection, $citationTree)
                or dts-document:isAlwaysPreservedSelection($candidateSelection))
                and (node-name($candidateSelection[1]) eq QName("http://www.tei-c.org/ns/1.0", "pb"))
            ) then
                dts-document:selectTEIPages($document, $candidateSelection, ())
            else if (
                $candidateSelection and
                (dts-document:isInCitationTree($candidateSelection, $citationTree)
                or dts-document:isAlwaysPreservedSelection($candidateSelection))
            ) then
                $candidateSelection
            else if ($candidateSelection) then
                error($errors:INVALID_PARAMETERS, "The selected citable units are not part of the citation tree specified for this document and are not part of the always preserved elements." || "Citation tree: " || string-join($citationTree/@xml:id, ", ") || ". Selected element: " || node-name($candidateSelection[1]) || ", Selected element @xml:id: " || $candidateSelection[1]/@xml:id)
            else
                error($errors:NOT_FOUND, "The specified citable units did not match any element in the document for the specified citation tree.")
    else if ($start and $end) then
        let $candidateStartNode := dts-document:selectBasedOnCiteStructure($document, $start, $citationTree)
        let $candidateEndNode := dts-document:selectBasedOnCiteStructure($document, $end, $citationTree)
        let $startNode :=
            if (
                $candidateStartNode and
                dts-document:isInCitationTree($candidateStartNode, $citationTree)
            ) then
                $candidateStartNode
            else if ($candidateStartNode) then
                error($errors:INVALID_PARAMETERS, "The selected start citable unit is not part of the citation tree specified for this document." || "Citation tree: " || string-join($citationTree/@xml:id, ", ") || ". Selected element: " || node-name($candidateStartNode[1]) || ", Selected element @xml:id: " || $candidateStartNode[1]/@xml:id)
            else
                error($errors:NOT_FOUND, "The specified start citable unit did not match any element in the document for the specified citation tree.")
        let $endNode :=
            if (
                $candidateEndNode and
                dts-document:isInCitationTree($candidateEndNode, $citationTree)
            ) then
                $candidateEndNode
            else if ($candidateEndNode) then
                error($errors:INVALID_PARAMETERS, "The selected end citable unit is not part of the citation tree specified for this document." || "Citation tree: " || string-join($citationTree/@xml:id, ", ") || ". Selected element: " || node-name($candidateEndNode[1]) || ", Selected element @xml:id: " || $candidateEndNode[1]/@xml:id)
            else
                error($errors:NOT_FOUND, "The specified end citable unit did not match any element in the document for the specified citation tree.")
        
        return
            if (node-name($startNode[1]) eq QName("http://www.tei-c.org/ns/1.0", "pb")
            and node-name($endNode[1]) eq QName("http://www.tei-c.org/ns/1.0", "pb")) then
                dts-document:selectTEIPages($document, $startNode, $endNode)
            else if ($start eq $end) then
                $startNode
            else if (not($startNode/parent::* is $endNode/parent::*)) then
                error($errors:INVALID_PARAMETERS, "The start and end citable units must have the same parent, or be page break elements." || "Selected start element: " || node-name($startNode[1]) || ", Selected start element @xml:id: " || $startNode[1]/@xml:id || ". Selected end element: " || node-name($endNode[1]) || ", Selected end element @xml:id: " || $endNode[1]/@xml:id)
            else if ($startNode << $endNode) then
                (
                    $startNode,
                    $startNode/following-sibling::*[
                        . << $endNode
                    ],
                    $endNode
                )
            else
                error($errors:INVALID_PARAMETERS, "Invalid start and end citable units. The start node must come before the end node. Start: " || $start || ", End: " || $end)
    else
        ()
};

(:~
 : Selects content according to the supplied parameters and wraps it for DTS output.
 :
 : @param $document The source document
 : @param $ref An optional reference to select a single unit
 : @param $start The optional start reference of a range
 : @param $end The optional end reference of a range
 : @param $citationTree The citation tree used to validate the selection
 : @return The wrapped selection ready for output
 :)
declare function dts-document:selectAndWrap(
    $document as node(),
    $ref as xs:string?,
    $start as xs:string?,
    $end as xs:string?,
    $citationTree as element(citeStructure)*
) as node()* {
    let $selection := dts-document:selectElementOrRange($document, $ref, $start, $end, $citationTree)
    return
        dts-document:wrapSelection($selection, $document)
};

(:~
 : Checks whether the supplied media type can be used with the document namespace.
 :
 : @param $mediaType The requested media type
 : @param $namespace The document namespace identifier
 : @return `true()` when the media type is compatible, otherwise `false()`
 :)
declare function dts-document:isMediaTypeCompatible(
    $mediaType as xs:string?,
    $namespace as xs:string
) as xs:boolean {
    if (not($mediaType)) then
        true()
    else if ($namespace eq "mei") then
        contains($mediaType, "application/xml")
        or contains($mediaType, "text/xml")
        or contains($mediaType, "application/mei+xml")
        or contains($mediaType, "text/html")
        or contains($mediaType, "application/json")
    else if ($namespace eq "tei") then
        contains($mediaType, "application/xml") or contains($mediaType, "text/xml") or contains($mediaType, "application/tei+xml") or contains($mediaType, "text/html")
    else if ($namespace eq "edirom") then
        contains($mediaType, "application/xml") or contains($mediaType, "text/xml")
    else
        false()
};

(:~
 : Resolves special resource aliases to their backing application resources.
 :
 : @param $resource The requested resource identifier
 : @return The resolved resource URI
 :)
declare function dts-document:resolveSpecialResourceAlias(
    $resource as xs:string?
) as xs:string {
    if (map:contains($dts-document:specialResourcesAliases, $resource)) then
        map:get($dts-document:specialResourcesAliases, $resource)
    else
        $resource
};

(:~
 : Transforms a TEI document fragment into HTML using the configured XSLT pipeline.
 :
 : @param $xml The TEI source document fragment
 : @param $resource The resource identifier used for the transformation context
 : @param $xslInstruction An optional stylesheet processing instruction
 : @param $htmlParameters The HTML rendering parameters
 : @return The transformed HTML fragment
 :)
declare function dts-document:transformTEIToHTML(
    $xml as node(),
    $resource as xs:string?,
    $xslInstruction as processing-instruction()?,
    $htmlParameters as map(xs:string, xs:string)
) as element() {
    let $doc := $xml
    let $xslInstruction :=
        for $i in fn:serialize($xslInstruction, ())
        return
            if (matches($i, 'type="text/xsl"')) then
            (substring-before(substring-after($i, 'href="'), '"'))
        else
            ()

    (: Remove DTS wrapper :)
    let $xslUnwrap := eutil:getDoc($eutil:xsltBase || '/removeDtsWrapper.xsl')
    let $doc := transform:transform($doc, $xslUnwrap, <parameters/>)

    (: Unpack html parameters :)
    let $lang := if (map:contains($htmlParameters, "lang")) then map:get($htmlParameters, "lang") else ""
    let $idPrefix := if (map:contains($htmlParameters, "idPrefix")) then map:get($htmlParameters, "idPrefix") else ""
    let $htmlProfile := if (map:contains($htmlParameters, "htmlProfile")) then map:get($htmlParameters, "htmlProfile") else $dts-document:defaultHTMLProfile

    let $contextPath := request:get-scheme()|| "://" || request:get-server-name() || ":" || request:get-server-port() || request:get-context-path()

    (: Apply language replacement stylesheet to replace language-dependent elements :)
    let $xslLang := eutil:getDoc($eutil:xsltBase || '/edirom_langReplacement.xsl')
    let $doc := 
        transform:transform($doc, $xslLang,
            <parameters>
                <param name="base" value="{concat($eutil:xsltBase, '/')}"/>
                <param name="lang" value="{$lang}"/>
            </parameters>
        )

    (: Apply stylesheet to convert TEI to HTML :)
    let $xslConvert :=
        if ($xslInstruction) then
            ($xslInstruction)
        else
            eutil:getDoc($eutil:xsltBase || '/tei/profiles/edirom-body/teiBody2HTML.xsl')

    let $standardParams := (
        (: parameters for teiBody2HTML stylesheet :)
        <param name="lang" value="{$lang}"/>,
        <param name="docUri" value="{$resource}"/>,
        <param name="contextPath" value="{$contextPath}"/>,
        <param name="base" value="{$eutil:xsltBase}"/>,
        (: parameters for the TEI Stylesheets :)
        <param name="documentationLanguage" value="{$lang}"/>,
        <param name="pageLayout" value="CSS"/>
    )
    let $profileParameters := dts-document:htmlProfileParameters($htmlProfile)
    let $params := ($standardParams, $profileParameters)

    let $doc := transform:transform($doc, $xslConvert, <parameters>{$params}</parameters>)

    (: TODO: To be moved to the frontend: Do a second transformation to add edirom online ID prefixes for unique ID values if object is open multiple times :)
    let $xslPrefix := eutil:getDoc($eutil:xsltBase || '/edirom_idPrefix.xsl')

    let $params := (
        <param name="idPrefix" value="{$idPrefix}"/>
    )
    let $doc := transform:transform($doc, $xslPrefix, <parameters>{$params}</parameters>)

    return
        $doc
};

(:~
 : Converts a document header to HTML for display in the application.
 :
 : @param $xml The header XML to transform
 : @param $namespace The document namespace identifier
 : @param $htmlParameters The HTML rendering parameters
 : @return The transformed HTML header fragment
 :)
declare function dts-document:transformHeaderToHTML(
    $xml as node(),
    $namespace as xs:string?,
    $htmlParameters as map(xs:string, xs:string)
) as element() {
    let $doc := $xml

    (: Remove DTS wrapper :)
    let $xslUnwrap := eutil:getDoc($eutil:xsltBase || '/removeDtsWrapper.xsl')
    let $doc := transform:transform($doc, $xslUnwrap, <parameters/>)

    (: Unpack html parameters :)
    let $lang := if (map:contains($htmlParameters, "lang")) then map:get($htmlParameters, "lang") else ""

    (: Convert to HTML :)
    let $xslConvert :=
        if ($namespace eq "mei") then
            eutil:getDoc($eutil:xsltBase || '/meiHead2HTML.xsl')
        (: TODO Verify how to make the stylesheet work again. The stylesheet is importing files that are no longer available.
        else if ($namespace eq "tei") then
            eutil:getDoc($eutil:xsltBase || '/tei/profiles/edirom-header/teiHeader2HTML.xsl')
        :)
        else
            error($errors:UNSUPPORTED_DOCUMENT_FORMAT, "The header cannot be converted to HTML for the requested document format. Namespace: " || $namespace)
    let $parameters := (
        <param name="base" value="{$eutil:xsltBase || '/'}"/>,
        <param name="lang" value="{$lang}"/>
    )
    let $doc := transform:transform($doc, $xslConvert, <parameters>{$parameters}</parameters>)

    return
        $doc

};

(:~
 : Converts an XML element into a map representation for JSON-style output.
 :
 : @param $document The source document used to resolve references
 : @param $element The XML element to convert
 : @return A map representation of the supplied element
 :)
declare function local:to-map(
    $document as element(),
    $element as element()
) as map(*) {

    map:merge((
        (: Attributes :)
        for $attribute in $element/@*
        let $attributeName := node-name($attribute)
        let $key :=
            if (string($attributeName) eq "xml:id") then
                concat(node-name($element), "Id")
            else
                $attributeName
        let $attributeValue := string($attribute)
        let $tokens := tokenize(normalize-space($attributeValue), "\s+")
        let $tokenValues :=
            for $token in $tokens
            return
                if (starts-with($token, "#")) then
                    let $referenceId := substring($token, 2)
                    let $target := $document/id($referenceId)
                    return
                        if ($attributeName = $dts-document:followReferenceAttributes and exists($target)) then
                            local:to-map($document, $target)
                        else if (not($attributeName = $dts-document:followReferenceAttributes)) then
                            $token
                        else
                            error($errors:NOT_FOUND, "The referenced element with @xml:id='" || $referenceId || "' was not found in the document. Referenced by " || node-name($element) || " element with @xml:id='" || $element/@xml:id || "'.")
            
                else
                    $token
        let $value :=
            if (empty($tokens)) then
                ''
            else if (count($tokenValues) = 1) then
                $tokenValues[1]
            else
                array { $tokenValues }
        return
            map:entry(
                string($key),
                $value
            ),

        (: Child elements, grouped by name :)
        for $key in distinct-values($element/*/node-name(.))
        let $children := $element/*[node-name(.) = $key]
        let $values :=
            for $child in $children
            return
                if (exists($child/*) or exists($child/@*)) then
                    local:to-map($document, $child)
                else
                    string($child)

        return
            map:entry(
                string($key),
                if (count($values) = 1) then
                    $values[1]
                else
                    array { $values }
            )
    ))
};

(:~
 : Selects the root-level citation tree elements from the supplied XML document.
 :
 : @param $xml The source document
 : @param $citationTree The citation tree to evaluate
 : @return The selected citation-tree root elements
 :)
declare function dts-document:selectCitationTreeRootElements(
    $xml as node(),
    $citationTree as element(citeStructure)*
) as element()* {
    let $topLevel := $citationTree[1]
    let $match := normalize-space($topLevel/@match)
    let $matchName :=
        if ($match) then
            resolve-QName($match, $topLevel)
        else
            ()
    let $selection :=
        if (exists($matchName)) then
            $xml//*[node-name(.) eq $matchName]
        else
            ()
    let $startNode := $selection[1]
    let $endNode := $selection[last()]
    let $start := $startNode/@xml:id
    let $end := $endNode/@xml:id
    return
        if ($start eq $end) then
            $startNode
        else if (not($startNode/parent::* is $endNode/parent::*)) then
            error($errors:INVALID_PARAMETERS, "The citation tree does not match the document structure.")
        else if ($startNode << $endNode) then
            (
                $startNode,
                $startNode/following-sibling::*[
                    . << $endNode
                ],
                $endNode
            )
        else
            error($errors:INVALID_PARAMETERS, "The citation tree does not match the document structure.")
};

(:~
 : Ensures that the supplied document contains a dts:wrapper element.
 : If no wrapper is present, the whole citation tree is selected and wrapped in a dts:wrapper element.
 :
 : @param $xml The source document
 : @param $citationTree The citation tree used to determine the wrapping
 : @return The document, wrapped if necessary
 :)
declare function dts-document:enforceWrapping(
    $xml as node(),
    $citationTree as element(citeStructure)*
) as node() {
    if (exists($xml//dts:wrapper)) then
        $xml
    else
        let $selection := dts-document:selectCitationTreeRootElements($xml, $citationTree)
        return
            if (exists($selection)) then
                dts-document:wrapSelection($selection, $xml)
            else
                error($errors:INVALID_PARAMETERS, "The citation tree specified for this document does not match any elements in the document. Citation tree: " || string-join($citationTree/@xml:id, ", "))
};

(:~
 : Converts the wrapped subtree of an MEI element into a map representation for JSON output.
 :
 : @param $xml The MEI element
 : @return A map representation of the wrapped subtree
 :)
declare function dts-document:wrappedMEIToMap(
    $xml as node()
) as map(*) {
    let $wrapped := $xml//dts:wrapper
    let $documentMap := local:to-map($xml, $wrapped)
    return $documentMap
};

(:~
 : Prepares MEI content for JSON output by adding any required attributes.
 :
 : @param $xml The source MEI document
 : @param $addMeasuresToZones Whether measure information should be attached to zones in the output
 : @return The processed document suitable for JSON output
 :)
declare function dts-document:processForJSON(
    $xml as node(),
    $addMeasuresToZones as xs:boolean
) as node() {
    let $xslAddAttributes := eutil:getDoc($eutil:xsltBase || '/edirom_processMEIForJSONOutput.xsl')

    let $params := (
        <param name="addMeasuresToZones" value="{$addMeasuresToZones}"/>
    )

    let $doc := transform:transform($xml, $xslAddAttributes, <parameters>{$params}</parameters>)
    return
        $doc
};

(:~
 : Returns the requested document representation for the supplied selection and output format.
 :
 : @param $resource The resource identifier to load
 : @param $ref An optional reference to select a single unit
 : @param $start The optional start reference of a range
 : @param $end The optional end reference of a range
 : @param $tree The optional citation tree identifier to use
 : @param $mediaType The requested output media type
 : @param $htmlParameters HTML rendering parameters for the response
 : @return The document content in the requested representation
 :)
declare function dts-document:document(
    $resource as xs:string?,
    $ref as xs:string?,
    $start as xs:string?,
    $end as xs:string?,
    $tree as xs:string?,
    $mediaType as xs:string?,
    $htmlParameters as map(xs:string, xs:string)
) as item() {
    if ($ref and ($start or $end)) then
        error($errors:INVALID_PARAMETERS, "The 'ref' parameter cannot be used together with 'start' or 'end'.")
    else if (($start and not($end)) or ($end and not($start))) then
        error($errors:INVALID_PARAMETERS, "Both 'start' and 'end' parameters must be provided together.")
    else
        let $resource := dts-document:resolveSpecialResourceAlias($resource)
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
        let $mediaTypeCompatible := dts-document:isMediaTypeCompatible($mediaType, $namespace)


        let $outputXmlRaw := 
            if (not($mediaTypeCompatible)) then
                error($errors:UNSUPPORTED_MEDIA_TYPE, "The requested media type is not compatible with the document format. Media type: " || $mediaType || ", Namespace: " || $namespace)
            else if (not($ref) and not($start) and not($end) and $mediaType eq "application/json") then
                dts-document:enforceWrapping($document, $citationTree)
            else if (not($ref) and not($start) and not($end)) then
                $document/*
            else if ($namespace eq "mei" or $namespace eq "tei") then
                dts-document:selectAndWrap($document, $ref, $start, $end, $citationTree)             
            else
                error($errors:UNSUPPORTED_DOCUMENT_FORMAT, "The format of the requested document is not supported. Namespace: " || $namespace )
        
        (: TODO: transformations should be applied here only when edirom output is requested :)
        let $xslPrepare := eutil:getDoc($eutil:xsltBase || '/edirom_prepareAnnotsForRendering.xsl')
        let $outputXml := transform:transform($outputXmlRaw, $xslPrepare, <parameters/>)

        let $output :=
            if (contains($mediaType, "xml")) then
                document { $outputXml }
            else if (contains($mediaType, "html") and (map:contains($htmlParameters, "htmlProfile")) and map:get($htmlParameters, "htmlProfile") eq "edirom-header") then
                document { dts-document:transformHeaderToHTML($outputXml, $namespace, $htmlParameters) }
            else if ($namespace eq "tei" and contains($mediaType, "html")) then
                let $xslInstruction := $document//processing-instruction(xml-stylesheet)
                return
                    document { dts-document:transformTEIToHTML($outputXml, $resource, $xslInstruction, $htmlParameters) }
            else if ($namespace eq "mei" and contains($mediaType, "json")) then
                let $addMeasuresToZones :=
                    if (dts-document:isInCitationTree(element mei:measure { }, $citationTree)) then
                        false()
                    else
                        true()
                let $processedXML := dts-document:processForJSON($outputXml, $addMeasuresToZones)
                return
                    dts-document:wrappedMEIToMap($processedXML)
            else
                error($errors:UNSUPPORTED_MEDIA_TYPE, "The requested media type is not supported. Media type: " || $mediaType || ", Namespace: " || $namespace || ", Ref: " || $ref)
        return
            $output
};
