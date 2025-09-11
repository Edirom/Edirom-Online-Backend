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
    let $genericTitle := eutil:getLocalizedTitle($anno, $lang)
    
    let $title :=
        if(exists($genericTitle) and string-length($genericTitle) gt 0) then
            ($genericTitle)
        else
            (annotation:generateTitle($anno))
    
    let $doc := $anno/root()
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
        let $pDoc :=
            if(doc-available($p)) then
                (doc($p))
            else
                edition:collection($edition)/id($p)/root()
        return
            if ($pDoc//mei:sourceDesc/mei:source/mei:identifier[@type = 'siglum']) then
                ($pDoc//mei:sourceDesc/mei:source/mei:identifier[@type = 'siglum']/text())
            else if ($pDoc//mei:manifestationList/mei:manifestation/mei:identifier[@type = 'siglum']) then
                ($pDoc//mei:manifestationList/mei:manifestation/mei:identifier[@type = 'siglum']/text())
            else
                ($pDoc//mei:title[@type = 'siglum']/text())
    
    let $classes := tokenize(replace(normalize-space($anno/@class),'#',''),' ')
    let $catURIs := distinct-values((tokenize(replace($anno/mei:ptr[@type = 'categories']/@target,'#',''),' '), $classes[contains(.,'annotation.category.')]))
    
    let $cats :=
        string-join(
            for $u in $catURIs
            return annotation:get-category-label-localized($doc/id($u))
         , ', ')
     
    let $count := count($anno/preceding::mei:annot[@type = 'editorialComment']) + 1
    
    let $baseMap := map {
        'id': $id,
        'title': normalize-space($title),
        'categories': $cats,
        'priority': $prio,
        'pos': string($count),
        'sigla': string-join($sigla,', ')
    }
    return
            $baseMap
};

(:~
 : Generates a title for annotation which have none
 :
 : @param $anno The Annotation to process
 : @return The string result
 :)
declare function annotation:generateTitle($anno as element()) {
    let $mdiv.n := 'Satz ' || string(count($anno/ancestor::mei:mdiv/preceding-sibling::mei:mdiv) + 1)
    let $measure := 'Takt ' || $anno/ancestor::mei:measure/string(@n)
    return $mdiv.n || ', ' || $measure
};

(:~
 : Returns a HTML representation of an Annotation's content
 :
 : @param $anno The Annotation to process
 : @param $idPrefix A prefix for all ids (because of uniqueness in application)
 : @return The HTML representation
 :)
declare function annotation:getContent($anno as element(), $idPrefix as xs:string, $edition as xs:string?) {

    (: TODO: check, whether replace is still necessary, by deploying in eXist-db app with embedded jetty :)
    let $xsltBase := concat(replace(system:get-module-load-path(), 'embedded-eXist-server', ''), '/../xslt/')
    
    let $edition := request:get-parameter('edition', '')
    let $imageserver :=  eutil:getPreference('image_server', $edition)
    let $imageBasePath := eutil:getPreference('image_prefix', $edition)
    
    let $language := eutil:getLanguage($edition)
    
    let $p := $anno/mei:p[not(@xml:lang) or @xml:lang = $language]
    
    let $html :=
        transform:transform($p,concat($xsltBase,'meiP2html.xsl'),
            <parameters>
                <param name="idPrefix" value="{$idPrefix}"/>
                <param name="imagePrefix" value="{$imageBasePath}"/>
            </parameters>
        )
    
    return
        $html
};

(:~
 : Returns a HTML representation of an Annotation's title
 :
 : @param $anno The Annotation to process
 : @param $idPrefix A prefix for all ids (because of uniqueness in application)
 : @return The HTML representation
 :)
declare function annotation:getTitle($anno as element(), $idPrefix as xs:string, $edition as xs:string?) {

    $anno/mei:title[not(@xml:lang) or @xml:lang = eutil:getLanguage($edition)]/text()
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
            ($anno/root())
        else
            (doc(substring-before($uri,'#')))
    
    let $locId := substring-after($uri,'#')
    
    let $elem := $doc/id($locId)
    
    return
        if(local-name($elem) eq 'term') then
            (eutil:getLocalizedName($elem, $lang))
        else
            ($locId)
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
                let $doc :=
                    if(starts-with($uri,'#')) then
                        (: uri is a local reference to an xml:id in the same document :)
                        ($anno/root())
                    else
                        (: uri is a reference to an xml:id in another document :)
                        (doc(substring-before($uri,'#')))
                
                let $prioElem := $doc/id(replace($uri,'#',''))
                let $label := annotation:get-category-label-localized($prioElem)
                return $label
            
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
    
    let $doc := $anno/root()
    
    let $classes := tokenize(replace(normalize-space($anno/@class),'#',''),' ')
    let $catURIs := distinct-values((tokenize(replace($anno/mei:ptr[@type = 'categories']/@target,'#',''),' '), $classes[contains(.,'annotation.category.')]))
    
    let $cats :=
        for $u in $catURIs
        return annotation:get-category-label-localized($doc/id($u))
        
    return $cats
};

(:~
 : Gets the labels for an annotation’s classes
 :
 :@param element() mei:annot element
 :@return sequence of xs:string, might be an empty sequence
 :)
declare function annotation:get-class-labels-as-sequence($anno as element(mei:annot)) as xs:string* {

    (: TODO fix strict binding to definitions in the same file :)
    let $doc := $anno/root()

    for $classIDREF in annotation:get-class-idrefs-as-sequence($anno)
    return annotation:get-category-label-localized($doc/id($classIDREF))

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
