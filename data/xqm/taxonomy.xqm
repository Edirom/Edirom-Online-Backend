xquery version "3.1";

(:
 : For LICENSE-Details please refer to the LICENSE file in the root directory of this repository.
 :)

(:~
 : This module provides library functions for handling MEI taxonomies.
 :
 : @author Benjamin W. Bohl <b.w.bohl@gmail.com>
 :)

module namespace taxonomy = "http://www.edirom.de/xquery/taxonomy";


(: IMPORTS ================================================================= :)

import module namespace eutil="http://www.edirom.de/xquery/eutil" at "eutil.xqm";


(: NAMESPACE DECLARATIONS ================================================== :)

declare namespace mei="http://www.music-encoding.org/ns/mei";

declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";

declare namespace request = "http://exist-db.org/xquery/request";


(: FUNCTION DECLARATIONS =================================================== :)

(:~
 : Returns metadata about an mei:taxonomy or mei:category element.
 :
 : @param $element An mei:taxonomy or mei:category element.
 : @return map(*) containing metadata such as categories, descriptions, heads, id, label, and languages.
 :)
declare function taxonomy:get-metadata( $element as element( * ) )
as map( * )
{
    let $element :=  taxonomy:taxonomy-or-category-test( $element )

    let $idString := $element/@xml:id => xs:string()

    let $languages := taxonomy:get-languages( $element )

    return
        map {
            "categories": taxonomy:get-categories( $element ),
            "descs": taxonomy:get-descs( $element, $languages ),
            "heads": taxonomy:get-heads( $element, $languages ),
(:            "i18n": eutil:getLanguageString($EDITION, $idString, (), $eutil:lang),:)
            "id": $idString,
            "label":taxonomy:get-labels( $element ),
            "languages": taxonomy:get-languages( $element )
        }

};

(:~
 : Returns an array of metadata maps for all mei:category children of the given element.
 :
 : @param $element An mei:taxonomy or mei:category element.
 : @return array(*)* Array of metadata maps for each child category.
 :)
declare function taxonomy:get-categories( $element as element( * ) )
as array( * )*
{
    let $element :=  taxonomy:taxonomy-or-category-test( $element )
    return
        array {
            for $category in $element/mei:category
            return
                taxonomy:get-metadata( $category )
        }

};

(:~
 : Returns metadata about a single mei:category element.
 :
 : @param $element An mei:category element.
 : @return map(*) containing descriptions, id, label, languages, and taxonomy reference.
 :)
declare function taxonomy:get-category( $element as element( mei:category ) )
as map( * )
{
    let $idString := $element/@xml:id => xs:string()

    let $languages := taxonomy:get-languages( $element )

    return
        map {
            "descs": taxonomy:get-descs( $element, $languages ),
(:          "i18n": eutil:getLanguageString($EDITION, $idString, (), $eutil:lang), :)
            "id": $idString,
            "label":taxonomy:get-labels( $element ),
            "languages": taxonomy:get-languages( $element ),
            "taxonomy": taxonomy:get-root-identifying-string( $element )
        }

};

(:~
 : Returns the string content of mei:desc elements in mei:taxonomy or mei:category
 : as map, with the language codes as keys.
 :
 : @param $element a mei:taxonomy or mei:category element
 : @param $languages array(*) Array of language codes.
 : @return map(*) with language codes as keys and description strings as values.
 :)
declare function taxonomy:get-descs( $element as element( * ), $languages as array( * ) )
as map( * )
{
    let $element :=  taxonomy:taxonomy-or-category-test( $element )
    return
        map:merge(
            for $lang in array:flatten( $languages )
            return
                map:entry( $lang, eutil:joinAndNormalize( $element/mei:desc[ @xml:lang = $lang ] ) )
        )

};

(:~
 : Returns the string content of mei:head elements in mei:taxonomy or mei:category
 : as map, with the language codes as keys.
 :
 : @param $element a mei:taxonomy or mei:category element
 : @param $languages array(*) Array of language codes.
 : @return map(*) with language codes as keys and head strings as values.
 :)
declare function taxonomy:get-heads( $element as element( * ), $languages as array( * ) )
as map( * )
{
    let $element :=  taxonomy:taxonomy-or-category-test( $element )
    return
        map:merge(
            for $lang in array:flatten( $languages )
            return
                map:entry( $lang, eutil:joinAndNormalize( $element/mei:head[ @xml:lang = $lang ] ) )
        )

};

(:~
: Returns a string identifier for grouping a category with its siblings.
 :
 : Resolution order:
 : 1. @class fragment — but only when it references an actual element in the document
 :    (e.g. edirom-style container categories <category xml:id="ediromPriority"/>).
 :    A @class value that has no corresponding element (e.g. bazga.annotation.class)
 :    is skipped so it does not collapse all sub-groups into one.
 : 2. The xml:id of the top-level ancestor mei:category that is a direct child of
 :    the nearest ancestor mei:taxonomy.  This splits flat single-taxonomy structures
 :    (e.g. BAZ-GA) into per-top-level-category groups.
 : 3. The xml:id of the nearest ancestor mei:taxonomy itself as a last fallback.
 :
 : @return xs:string of the retrieved identifier
 :)
declare function taxonomy:get-root-identifying-string( $element as element ( * ) )
as xs:string
{
    let $classId       := substring-after($element/@class, '#')
    let $nearestTaxonomy := $element/ancestor-or-self::mei:taxonomy[1]
    let $topCategory   := ($element/ancestor-or-self::mei:category[parent::mei:taxonomy is $nearestTaxonomy])[1]
    return (
        $classId[. != '' and exists($element/root()/id($classId))],
        $topCategory/@xml:id,
        $nearestTaxonomy/@xml:id
    )[. != ''][1] => xs:string()
};

(:~
 : Returns a string identifier for grouping a category with its siblings.
 :
 : Resolution order:
 : 1. @class fragment — the leaf category’s explicit declaration of its parent group
 : 2. @xml:id of the nearest ancestor mei:taxonomy — fallback for elements without @class
 :
 : @return xs:string of the retrieved identifier
 :)
declare function taxonomy:get-parent-taxonomy-identifying-string( $element as element( * ) )
as xs:string
{
    (substring-after($element/@class, '#'), $element/ancestor-or-self::mei:taxonomy[1]/@xml:id)[. != ''][1] => xs:string()

};

(:~
 : Returns a localized label string for a mei:taxonomy or mei:category element.
 :
 : Resolution order:
 : 1. mei:label matching the current language
 : 2. mei:label without @xml:lang (language-neutral)
 : 3. @xml:id of the element as last resort
 :
 : @param $element a mei:taxonomy or mei:category element, or empty sequence
 : @return xs:string? — empty if $element is absent or has no @xml:id and no labels
 :)
declare function taxonomy:get-label-localized-as-string( $element as element( * )? )
as xs:string?
{
    if (empty($element)) then ()
    else
        let $lang := eutil:getSetLanguage(())
        let $labels := taxonomy:get-labels( $element )
        return
            ($labels($lang)[. != ''], $labels('und')[. != ''], xs:string($element/@xml:id)[. != ''])[1]

};

(:~
 : Returns labels of a mei:taxonomy or mei:category element.
 : This is the 1-arity version.
 :
 : @param $element a mei:taxonomy or mei:category element
 : @return map(*) with language codes as keys and labels as values.
 :)
declare function taxonomy:get-labels( $element as element( * ) )
as map ( * )
{
    let $element := taxonomy:taxonomy-or-category-test( $element )

    return
        taxonomy:get-labels( $element, array{} )

};

(:~
 : Returns labels of a mei:taxonomy or mei:category element for given languages. If the
 : submitted $languages array is empty an array for all available localizations will be
 : returnd with an additional label for the 'und' (undefined) localization. The value for this
 : will be determined in the following order:
 :     1. child mei:label without @xml:lang (only possible on mei:category)
 :     2. @label
 :     3. first of all mei:label child elements (only possible on mei:category)
 :     4. the element's own @xml:id
 :     5. the parent taxonomy's identifying string
 :
 : Note: a mei:category that is referenced from mei:annot/@class is always resolvable by id()
 : and therefore always carries an @xml:id, so step 5 is only ever reached for a mei:taxonomy
 : that lacks its own @xml:id.
 :
 : @param $element a mei:taxonomy or mei:category element
 : @param $languages array(*) an array with language codes
 : @return map(*) with language codes as keys and labels as values.
 :)
declare function taxonomy:get-labels( $element as element( * ), $languages as array( * )? )
as map ( * )
{

    let $element := taxonomy:taxonomy-or-category-test( $element )

    let $languages :=
        if ( array:size( $languages ) = 0 ) then
            array:append(
                taxonomy:get-languages( $element ),
                "und"
            )
        else $languages

    return
        map:merge(
            for $lang at $i in array:flatten( $languages )
            return
                switch ( $lang )
                    case "und" return
                        map:entry(
                            "und",
                            ( (: pick the first of the following :)
                                (: the first mei:label without @xml:lang – only available in mei:catgory :)
                                ( $element/mei:label[ not (@xml:lang ) ] )[ 1 ],
                                (: the @label :)
                                $element/@label,
                                (: the first mei:label – only available in mei :category :)
                                ( $element/mei:label )[ 1 ],
                                (: the element’s xml:id :)
                                $element/@xml:id,
                                (: the parent taxonomy’s identifying string :)
                                taxonomy:get-parent-taxonomy-identifying-string( $element ) )[ 1 ] => normalize-space() )
                    default return
                      map:entry( $lang, $element/mei:label[ @xml:lang = $lang ] => normalize-space() )
        )

};

(:~
 : Recurses the descendant tree of a mei:taxonomy or mei:category element
 : and returns distinct values of @xml:lang as array.
 :
 : @param $element a mei:taxonomy or mei:category element
 : @return array(*) Array of distinct language codes.
 :)
declare function taxonomy:get-languages( $element as element( * ) )
as array( * )
{
    (: TODO what if there is no @xml:lang :)
    let $element :=  taxonomy:taxonomy-or-category-test( $element )
    return
        array { distinct-values( $element/ancestor-or-self::mei:taxonomy//@xml:lang ) }

};

(:~
 : Tests whether a submitted element is a mei:taxonomy or mei:category element.
 : Throws err:XPTY0004 type error if not.
 :
 : @param $element a XML element
 : @return The input element if it is a mei:taxonomy or mei:category.
 : @error err:XPTY0004 if the element is not of the expected type.
 :)
declare function taxonomy:taxonomy-or-category-test( $element as element() )
as element()
{
    typeswitch( $element )
        case $a as element( mei:taxonomy )
                 | element( mei:category )
            return
                $element
        default
            return error( xs:QName("err:XPTY0004"), "Unexpected element: expected mei:taxonomy or mei:category" )

};
