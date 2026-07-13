xquery version "3.1";
(:
 : For LICENSE-Details please refer to the LICENSE file in the root directory of this repository.
 :)

(:~
 : This module provides library functions for Annotations
 :
 : @author <a href="mailto:roewenstrunk@edirom.de">Daniel Röwenstrunk</a>
 : @author <a href="mailto:bohl@edirom.de">Benjamin W. Bohl</a>
 :)

module namespace annotation = "http://www.edirom.de/xquery/annotation";

(: IMPORTS ================================================================= :)

import module namespace edition="http://www.edirom.de/xquery/edition" at "edition.xqm";
import module namespace eutil="http://www.edirom.de/xquery/eutil" at "eutil.xqm";

import module namespace taxonomy="http://www.edirom.de/xquery/taxonomy" at "taxonomy.xqm";

(: NAMESPACE DECLARATIONS ================================================== :)

declare namespace mei="http://www.music-encoding.org/ns/mei";
declare namespace request="http://exist-db.org/xquery/request";
declare namespace system="http://exist-db.org/xquery/system";
declare namespace transform="http://exist-db.org/xquery/transform";

(: FUNCTION DECLARATIONS =================================================== :)

declare function annotation:get-category-label-localized($node) {

    let $lang := request:get-parameter('lang', '')
    let $nodeName := local-name($node)

     let $label :=
        switch($nodeName)
            case 'category' return
                taxonomy:get-label-localized-as-string($node)
            case 'term' return
                (: legacy way of associating categories and priorities to annotations using mei:ptr :)
                eutil:getLocalizedName($node, $lang)
            default return
                $nodeName

    return $label
};

(:~
 : Returns a JSON representation of all Annotations of a document
 :
 : @param $uri The document to process
 : @return The JSON representation
 :)
declare function annotation:annotationsToJSON($uri as xs:string, $edition as xs:string) as map(*)* {
    
    let $doc := eutil:getDoc($uri)
    let $annos := $doc//mei:annot[@type = 'editorialComment']
    return
        for $anno in $annos
        return annotation:toJSON($anno, $edition)
};

(:~
 : Returns a JSON representation of an Annotation
 :
 : @param $anno The Annotation to process
 : @return The JSON representation
 :)
declare function annotation:toJSON($anno as element(), $edition as xs:string) as map(*) {

    let $id := $anno/string(@xml:id)
    let $lang := request:get-parameter('lang', '')
    let $title := eutil:getLocalizedName($anno, $lang)

    let $prio := annotation:getPriorityLabel($anno)
    let $pList.raw := distinct-values(tokenize(normalize-space($anno/@plist), ' '))

    let $pList :=
        for $p in $pList.raw
        return
            if ( contains($p, '#')) then
                (substring-before($p, '#'))
            else
                $p

    let $sigla :=
        for $p in distinct-values($pList)
        let $pDoc.valid :=
            if($p)
            then
                try { eutil:getDoc($p) }
                catch * {()}
            else ()
        let $pDoc :=
            if($pDoc.valid) then
                $pDoc.valid
            else
                edition:collection($edition)/id($p)/root()
        return
            if ($pDoc//mei:sourceDesc/mei:source/mei:identifier[@type = 'siglum']) then
                ($pDoc//mei:sourceDesc/mei:source/mei:identifier[@type = 'siglum']/text())
            else if ($pDoc//mei:manifestationList/mei:manifestation/mei:identifier[@type = 'siglum']) then
                ($pDoc//mei:manifestationList/mei:manifestation/mei:identifier[@type = 'siglum']/text())
            else
                ($pDoc//mei:title[@type = 'siglum']/text())

    (: resolve all @class references (cross-file aware) for the taxonomy fields below :)
    let $classes-elements :=
        for $token in tokenize(normalize-space($anno/@class), ' ')[. != '']
        return eutil:get-referenced-element($anno, $token)

    let $cats := string-join(annotation:get-category-labels-as-sequence($anno), ', ')

    let $count := count($anno/preceding::mei:annot[@type = 'editorialComment']) + 1

    (: create a map with all static information about the annotation :)
    let $baseMap := map {
        'id': $id,
        'title': normalize-space($title),
        (: TODO deprecate categories field with Edirom-Online-API 2.0.0 :)
        'categories': $cats,
        (: TODO deprecate priority field with Edirom-Online-API 2.0.0 :)
        'priority': $prio,
        'pos': string($count),
        'sigla': string-join($sigla,', ')
    }

    (: create a map with keys for each taxonomy used for this annotation and the corresponding class labels :)
    let $taxonomiesMap := map:merge(
        for $usedTaxonomy in $classes-elements[ancestor::mei:taxonomy]
        let $taxonomyIdentifier := taxonomy:get-parent-taxonomy-identifying-string( $usedTaxonomy )
        return
            map:entry(
                $taxonomyIdentifier,
                string-join (
                    (
                        for $classElement in $classes-elements[self::mei:category]
                        where taxonomy:get-parent-taxonomy-identifying-string( $classElement ) = $taxonomyIdentifier
                        return taxonomy:get-label-localized-as-string($classElement)
                    ),
                    ', '
                )
            )
    )

    return
        map:merge((
            $baseMap,
            $taxonomiesMap
        ))
};

(:~
 : Returns a HTML representation of an Annotation's content
 :
 : @param $anno The Annotation to process
 : @param $idPrefix A prefix for all ids (because of uniqueness in application)
 : @return The HTML representation
 :)
declare function annotation:getContent($anno as element(), $idPrefix as xs:string, $edition as xs:string?) {
    
    let $edition := request:get-parameter('edition', '')
    let $imageserver :=  edition:getPreference('image_server', $edition)
    let $imageBasePath := edition:getPreference('image_prefix', $edition)

    let $language := edition:getLanguage($edition)

    let $p := $anno/mei:p[not(@xml:lang) or @xml:lang = $language]

    let $html :=
        transform:transform($p,eutil:getDoc($eutil:xsltBase || '/meiP2html.xsl'),
            <parameters>
                <param name="idPrefix" value="{$idPrefix}"/>
                <param name="imagePrefix" value="{$imageBasePath}"/>
            </parameters>
        )

    return
        $html
};

(:~
 : Returns an Annotation's priority
 :
 : @param $anno The Annotation to process
 : @return The priority
 :)
declare function annotation:getPriority($anno as element()) as xs:string* {

    let $uri := $anno/mei:ptr[@type eq 'priority']/string(@target)
    let $lang := request:get-parameter('lang', '')

    let $doc :=
        if(starts-with($uri,'#')) then
            $anno/root()
        else
            eutil:getDoc(substring-before($uri,'#'))
    
    let $locId := substring-after($uri,'#')

    let $elem := $doc/id($locId)

    return
        if(local-name($elem) eq 'term') then
            eutil:getLocalizedName($elem, $lang)
        else
            $locId
};

(:~
 : Gets the label for a Edirom Online annotation priority
 :
 : @param $anno should be a mei:annot, mei:term, or mei:category element
 :
 : @return
 :)
declare function annotation:getPriorityLabel($anno) as xs:string* {

    let $isPrioElemAlready := local-name($anno) = ('term','category')
    let $oldEdiromStyle := local-name($anno) = 'annot' and exists($anno/mei:ptr[@type eq 'priority'])

    return
        if($isPrioElemAlready) then
            (annotation:get-category-label-localized($anno))

        else if($oldEdiromStyle) then
            (annotation:getPriority($anno))

        else (
            let $classes := tokenize(normalize-space($anno/@class),' ')
            let $classBasedUri := $classes[starts-with(.,'#ediromAnnotPrio')]

            let $labels :=
                for $uri in $classBasedUri
                let $prioElem := eutil:get-referenced-element($anno, $uri)
                return annotation:get-category-label-localized($prioElem)

            return string-join($labels,', ')
        )
};

(:~
: Returns Annotation's categories
:
: @param $anno The Annotation to process
: @return The categories (as comma separated string)
:)
(:declare function annotation:getCategories($anno as element()) as xs:string {

    string-join(annotation:get-category-labels-as-sequence($anno), ', ')
};:)

(:~
 : Returns a sequence of names/labels for an annotation's categories
 :
 : @param $anno The Annotation to process
 : @return The categories (as comma separated string)
 :)
declare function annotation:get-category-labels-as-sequence($anno as element()) as xs:string* {

    let $ptrTokens := tokenize(normalize-space($anno/mei:ptr[@type = 'categories']/@target), ' ')
    let $classTokens := tokenize(normalize-space($anno/@class), ' ')[contains(., 'annotation.category.')]
    let $catTokens := distinct-values(($ptrTokens, $classTokens)[. != ''])

    for $token in $catTokens
    return annotation:get-category-label-localized(eutil:get-referenced-element($anno, $token))
};

(:~
 : Gets the labels for an annotation’s classes
 :
 :@param element() mei:annot element
 :@return sequence of xs:string, might be an empty sequence
 :)
declare function annotation:get-class-labels-as-sequence($anno as element(mei:annot)) as xs:string* {

    for $token in tokenize(normalize-space($anno/@class), ' ')[. != '']
    return annotation:get-category-label-localized(eutil:get-referenced-element($anno, $token))

};

(:~
 : Gets the IDREFs for an annotation’s classes
 :
 :@param element() mei:annot element
 :@return sequence of xs:IDREF, might be an empty sequence
 :)
declare function annotation:get-class-idrefs-as-sequence($anno as element(mei:annot)) as xs:IDREF* {

    for $token in $anno/@class => normalize-space() => replace('#','') => tokenize(' ')
    return xs:IDREF($token)

};

(:~
 : Returns the mei:category elements referenced by @class on the given annotations.
 :
 : Each @class token is resolved via eutil:get-referenced-element (cross-file aware) and
 : kept only if it resolves to a mei:category.
 :
 : @param $annots  One or more mei:annot elements to inspect
 : @return         Distinct mei:category elements, deduplicated by @xml:id (first occurrence wins)
 :)
declare function annotation:get-referenced-category-elements(
    $annots as element(mei:annot)*
) as element(mei:category)*
{
    let $raw :=
        for $annot in $annots
        for $token in tokenize(normalize-space($annot/@class), ' ')[contains(., '#')]
        return eutil:get-referenced-element($annot, $token)[self::mei:category]

    for $id in distinct-values($raw/@xml:id)

    return ($raw[@xml:id = $id])[1]
};

(:~
 : Returns a sequence of document URIs addressed by an annotation
 :
 : @param $anno element() The Annotation to process
 : @return sequence of xs:string, might be an empty sequence
 :)
declare function annotation:getParticipants($anno as element()) as xs:string* {

    let $ps := tokenize($anno/@plist, ' ')
    let $uris := distinct-values(for $uri in $ps return substring-before($uri,'#'))

    return $uris
};

(:~
 : Returns a map referenced classes in a map structured by taxonomy
 :
 : @param $annots one or more mei:annot elements
 : @return a map
 :)
declare function annotation:get-referenced-categories-as-taxonomy-array(
    $annots as element(mei:annot)*,
    $scope as node()+,
    $lang as xs:string?
) as array(*)
{
    let $lang := eutil:getSetLanguage($lang)

    return
        try {
            array {
                for $annot in $annots
                for $annotElement in ($scope//mei:annot[@xml:id = $annot/@xml:id])[1]
                for $categoryElement in annotation:get-referenced-category-elements($annotElement)
                let $taxonomyGroupingKey := taxonomy:get-parent-taxonomy-identifying-string($categoryElement)
                group by $taxonomyGroupingKey
                let $taxonomyElement := $categoryElement[1]/ancestor-or-self::mei:taxonomy[1]
                let $taxonomyDisplayLabel := (taxonomy:get-label-localized-as-string($taxonomyElement)[. != ''], $taxonomyGroupingKey)[1]
                return
                    map {
                        'id': $taxonomyGroupingKey,
                        'label': $taxonomyDisplayLabel,
                        'items': array {
                            for $id in distinct-values($categoryElement/@xml:id)
                            let $catElem := ($categoryElement[@xml:id = $id])[1]
                            let $catLabel := taxonomy:get-label-localized-as-string($catElem)
                            order by $catLabel
                            return
                                map {
                                    'id': xs:string($id),
                                    'name': $catLabel
                                }
                        }
                    }
            }
        } catch * {[]}
};
