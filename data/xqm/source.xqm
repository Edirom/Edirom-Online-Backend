xquery version "3.1";
(:
 : For LICENSE-Details please refer to the LICENSE file in the root directory of this repository.
 :)

(:~
 : This module provides library functions for Sources
 :
 : @author <a href="mailto:roewenstrunk@edirom.de">Daniel Röwenstrunk</a>
 : @author <a href="mailto:bohl@edirom.de">Benjamin W. Bohl</a>
 :)
module namespace source = "http://www.edirom.de/xquery/source";

(: IMPORTS ================================================================= :)

import module namespace functx="http://www.functx.com";

import module namespace edition="http://www.edirom.de/xquery/edition" at "edition.xqm";
import module namespace eutil="http://www.edirom.de/xquery/eutil" at "eutil.xqm";

(: NAMESPACE DECLARATIONS ================================================== :)

declare namespace mei="http://www.music-encoding.org/ns/mei";

(: FUNCTION DECLARATIONS =================================================== :)

(:~
: Returns whether a document is a source or not. Generally this should work for MEI versions
: 2011-05 through 5.0
:
: @param $uri The URI of the document
:
: @return xs:boolean indicating whether the document referenced by @param $uri
: is considered a music source or not.
:)
declare function source:isSource($uri as xs:string) as xs:boolean {

    let $doc := eutil:getDoc($uri)
    let $meiVersion4To5Regex := '^[4-5](\.\d){1,2}(-dev)?(\+(anyStart|basic|CMN|Mensural|Neumes))?$'

    return
        (: 2010-05 pre camelCase :)
        (: 2011-05 2012 :)
        (: 2013 +meiversion.num 2.1.1:)
        (: 3.0.0 :)
        (exists($doc//mei:mei) and exists($doc//mei:source))
        or
        (: MEI 4.0.1 and 5.0 with all dev and cutomization variants :)
        (matches($doc//mei:mei/@meiversion, $meiVersion4To5Regex) and exists($doc//mei:manifestation[@singleton='true'])) (:mei4+ for manuscripts:)
        or
        (matches($doc//mei:mei/@meiversion, $meiVersion4To5Regex) and exists($doc//mei:manifestation//mei:item)) (: mei4+ for prints :)
};

(:~
 : Returns a comma separated list of source labels
 :
 : @param $sources The URIs of the Sources' documents to process
 : @return The labels
 :)
declare function source:getLabels($sources as xs:string*, $edition as xs:string) as xs:string {

    string-join(
        for $source in $sources return source:getLabel($source, $edition)
    , ', ')

};

(:~
 : Returns a source's label
 :
 : @param $source The URIs of the Source's document to process
 : @return The label
 :)
declare function source:getLabel($source as xs:string, $edition as xs:string) as xs:string {

    let $sourceDoc := eutil:getDoc($source)
    let $language := edition:getLanguage($edition)

    let $label :=
        (:TODO encoding of source labels may heavily differ in certain encoding contexts, thus introduction of class="http://www.edirom.de/edirom-online/source/label" OR some configuration method, e.g., a user definable function :)
        if($sourceDoc/mei:mei/@meiversion = ("4.0.0", "4.0.1")) then
            $sourceDoc//mei:manifestation[@singleton='true']/mei:titleStmt/mei:title[@class = "http://www.edirom.de/edirom-online/source/label"][not(@xml:lang) or @xml:lang = $language]

        else
            $sourceDoc//mei:source/mei:titleStmt/mei:title[not(@xml:lang) or @xml:lang = $language]

    let $label :=
        if($label) then
            ($label)
        else
            ($sourceDoc//mei:meiHead/mei:fileDesc/mei:titleStmt/mei:title[not(@xml:lang) or @xml:lang = $language])

    let $label :=
        if($label) then
            ($label)
        else
            ('unknown title')
    return
        string($label)

};

(:~
 : Returns a comma separated list of source sigla
 :
 : @param $sources The URIs of the Sources' documents to process
 : @return The sigla
 :)
declare function source:getSigla($sources as xs:string*) as xs:string {

    string-join(
        source:getSiglaAsArray($sources)
    , ', ')

};

(:~
 : Returns a sequence of source sigla
 :
 : @param $sources The URIs of the Sources' documents to process
 : @return The sigla
 :)
declare function source:getSiglaAsArray($sources as xs:string*) as xs:string* {

    for $source in $sources
    return
        source:getSiglum($source)

};

(:~
 : Returns a source's siglum
 :
 : @param $source The URIs of the Source's document to process
 : @return The siglum
 :)
declare function source:getSiglum($source as xs:string) as xs:string? {

    let $doc := eutil:getDoc($source)
    let $elems := $doc//mei:*[@type eq 'siglum']
    return
        if(exists($elems))
        then $elems[1] => normalize-space()
        else ()
};

(:~
 : Returns the designation Edirom Online displays for an element: @label if present,
 : otherwise @n.
 :
 : This is the rule stated in docs/data-creation-workflow.md: "For both elements the
 : Edirom Online prioritizes the value of the label-attribute to be displayed in the
 : edition and uses the n-attribute only, if no label-attribute is provided." It is
 : documented for mei:measure and mei:surface; the implementation is element-agnostic
 : so both can share it.
 :
 : @param $element The element to read the designation from
 : @return The designation, or the empty sequence if the element carries neither attribute
 :)
declare function source:label-or-n($element as element()) as xs:string? {

    if ($element/@label)
    then $element/string(@label)
    else $element/@n ! string(.)
};

(:~
 : Builds the virtual measure ID for a measure.
 :
 : A measure number generally occurs once in every part. Rather than referencing each of
 : those measures individually, Edirom Online refers to them collectively through a single
 : synthetic ID of the form measure_[mdiv ID]_[measure designation].
 :
 : The designation is appended verbatim, so an @label containing '_', whitespace or ';'
 : yields an ID that cannot be parsed back or carried in a URI list. See implication #12
 : in Edirom-Online/.claude/PLAN_data-implications-from-backend.md.
 :
 : @param $measure The measure to build the ID for
 : @return The virtual measure ID
 :)
declare function source:get-virtual-measure-id($measure as element(mei:measure)) as xs:string {

    'measure_'
        || $measure/ancestor::mei:mdiv[1]/string(@xml:id)
        || '_'
        || source:label-or-n($measure)
};

(:~
 : Returns the measure elements a virtual measure ID denotes.
 :
 : Since a measure number generally occurs once in every part, this is a sequence rather
 : than a single element. The ID is split on its LAST underscore, so an mdiv @xml:id that
 : itself contains underscores stays intact.
 :
 : @param $doc The source document to resolve against, may be empty
 : @param $id The virtual measure ID, may be empty
 : @return The measures denoted, or the empty sequence if $id is not a virtual measure ID
 : resolvable in $doc
 :)
declare function source:resolve-virtual-measure-id($doc as document-node()?, $id as xs:string?) as element(mei:measure)* {

    if (starts-with($id, 'measure_'))
    then
        let $reference := substring-after($id, 'measure_')
        let $mdivId := functx:substring-before-last($reference, '_')
        let $designation := functx:substring-after-last($reference, '_')
        return
            if ($mdivId eq '' or $designation eq '')
            then ()
            else $doc/id($mdivId)//mei:measure[source:label-or-n(.) eq $designation]
    else ()
};

(:~
 : Resolves a measure reference of either kind to the measure element(s) it denotes.
 :
 : A real @xml:id always wins. Measure @xml:id values may themselves start with 'measure_'
 : (the cartographer-app generates IDs of the form measure_[UUID]), so a string is treated
 : as a virtual measure ID only once it has failed to resolve to a real element.
 :
 : @param $doc The source document to resolve against, may be empty
 : @param $id A measure @xml:id or a virtual measure ID, may be empty
 : @return The measures denoted, or the empty sequence if $id resolves to neither
 :)
declare function source:resolve-measure-ref($doc as document-node()?, $id as xs:string?) as element(mei:measure)* {

    let $measure := $doc/id($id)[self::mei:measure]
    return
        if (exists($measure))
        then $measure
        else source:resolve-virtual-measure-id($doc, $id)
};
