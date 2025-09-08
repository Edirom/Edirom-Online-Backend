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
            "taxonomy": ($element/ancestor::mei:taxonomy/@xml:id, substring-after($element/@class, '#'))[1] => xs:string()
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
 : Returns labels of a mei:taxonomy or mei:category element.
 : This is the 1-arity version.
 :
 : @param $element a mei:taxonomy or mei:category element
 : @return map(*) with language codes as keys and labels as values.
 :)
declare function taxonomy:get-labels( $element as element( * ) )
as map ( * )
{
    let $element :=  taxonomy:taxonomy-or-category-test( $element )

    return
        taxonomy:get-labels( $element, array{} )

};

(:~
 : Returns labels of a mei:taxonomy or mei:category element for given languages.
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
                    case "und" return map:entry( "und", ( ( $element/mei:label[ not (@xml:lang ) ] )[ 1 ], $element/@label )[ 1 ] )
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
 : Throws err:XPTY004 type error if not.
 :
 : @param $element a XML element
 : @return The input element if it is a mei:taxonomy or mei:category.
 : @error err:XPTY004 if the element is not of the expected type.
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
            return error( xs:QName("err:XPTY004"), "Unexpected element: expected mei:taxonomy or mei:category" )

};
