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
declare namespace util="http://exist-db.org/xquery/util";

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

    source:get-virtual-measure-id($measure, source:label-or-n($measure))
};

(:~
 : Builds the virtual measure ID for a measure under an explicit designation.
 :
 : A measure standing for several of them - a range label, or a multiRest - has no single
 : designation of its own, so callers grouping by designation supply the one they mean. This
 : is the only place the ID format is written out.
 :
 : @param $measure The measure to build the ID for
 : @param $designation The designation to build it under
 : @return The virtual measure ID
 :)
declare function source:get-virtual-measure-id($measure as element(mei:measure), $designation as xs:string?) as xs:string {

    'measure_'
        || $measure/ancestor::mei:mdiv[1]/string(@xml:id)
        || '_'
        || $designation
};

(:~
 : Reports a measure whose abbreviation could not be expanded, and yields its own designation.
 :
 : An edition using an abbreviation strategy this module does not cover would otherwise be
 : silently short a measure in the spinner, which is how that class of defect goes unnoticed.
 :
 : @param $measure The measure concerned
 : @param $designation Its own designation, returned unchanged
 : @param $reason What could not be done
 : @return $designation
 :)
declare %private function source:report-unexpanded($measure as element(mei:measure), $designation as xs:string?, $reason as xs:string) as xs:string* {

    util:log('warn',
        'source:measure-designations: ' || $reason
            || ' (measure ' || (($measure/@xml:id, '[no @xml:id]')[1] => string())
            || ', designation ' || (($designation, '[none]')[1] => string()) || ')'),
    $designation
};

(:~
 : Returns every designation a measure accounts for.
 :
 : Usually one, but a measure can stand for a run of them, and each number then has to be
 : addressable in its own right while still resolving to the one measure - and therefore the
 : one zone - that represents it. Two encodings are recognised:
 :
 :   - an explicit range label, '38-46' written with an en dash;
 :   - a mei:multiRest, where @num measures are represented by the one carrying the rest.
 :
 : A measure may carry both - the label stating the span, the multiRest being the music that
 : fills it. Only one is applied, and the range label wins: it states outright which numbers
 : the measure covers, whereas @num has to be counted forward from the designation.
 :
 : Where an edition writes both an abbreviated and an expanded form, the expansion is the one
 : that counts and the abbreviated measures are not in play at all - see
 : source:effective-measures. This function is therefore only reached for the expanded form,
 : or for an abbreviation standing alone.
 :
 : Expansion needs numeric bounds. A designation such as '2b' is returned unchanged, and
 : reported if it carries an abbreviation that was expected to expand.
 :
 : @param $measure The measure to read
 : @return The designations, in ascending order
 :)
declare function source:measure-designations($measure as element(mei:measure)) as xs:string* {

    let $designation := source:label-or-n($measure)

    (: A measure spanning several staves carries one multiRest per staff, all stating the same
       span, so the first is representative. Absent or unparseable, this is NaN, and every
       comparison against NaN is false - so the branch below simply does not fire. :)
    let $multiRestNum := number(($measure//mei:multiRest/@num)[1])

    return

        (: an explicit range label :)
        if (contains($designation, '–'))
        then
            let $first := number(substring-before($designation, '–'))
            let $last := number(substring-after($designation, '–'))
            return
                if (string($first) ne 'NaN' and string($last) ne 'NaN' and $last ge $first)
                then for $i in 0 to xs:integer($last - $first) return string($first + $i)
                else source:report-unexpanded($measure, $designation,
                        'range label does not give a usable pair of bounds')

        (: a multiRest standing for @num measures :)
        else if ($multiRestNum gt 1)
        then
            if (string(number($designation)) ne 'NaN')
            then for $i in 0 to xs:integer($multiRestNum) - 1
                 return string(number($designation) + $i)
            else source:report-unexpanded($measure, $designation,
                    'multiRest on a designation that is not a number')

        (: an abbreviation this module does not recognise :)
        else if (exists($measure/ancestor::mei:abbr))
        then source:report-unexpanded($measure, $designation,
                'measure is abbreviated by a strategy that cannot be expanded')

        else $designation
};

(:~
 : Returns the measures of a context that are in play.
 :
 : An edition may carry both an abbreviated and an expanded form of the same music, the
 : abbreviation under mei:abbr and the individual measures under mei:expan. Both are present
 : in the document, so a plain //mei:measure would count each of those measures twice: once
 : written out, once by expanding the abbreviation. The expansion is the authoritative form,
 : so measures under an mei:abbr that has an mei:expan beside it are excluded.
 :
 : An mei:abbr standing on its own is kept: dropping it would lose the measure altogether,
 : which is worse than expanding it from @num.
 :
 : @param $context The element to scan, typically an mdiv
 : @return The measures to work with, in document order
 :)
declare function source:effective-measures($context as node()?) as element(mei:measure)* {

    $context//mei:measure[not(ancestor::mei:abbr[../mei:expan])]
};

(:~
 : Returns the reference Edirom Online uses to address a designation.
 :
 : Where a single measure carries the designation its own @xml:id identifies it; where several
 : do - one per part - the virtual measure ID stands for them collectively. A measure with no
 : @xml:id, which a multiRest measure typically has none of since nothing on the facsimile
 : corresponds to it, also falls back to the virtual ID rather than yielding an empty
 : reference.
 :
 : @param $measures The measures carrying the designation
 : @param $designation The designation they are addressed under
 : @return The reference, or the empty sequence if there are no measures
 :)
declare function source:measure-reference($measures as element(mei:measure)*, $designation as xs:string?) as xs:string? {

    if (empty($measures))
    then ()
    else if (count($measures) eq 1 and $measures[1]/string(@xml:id) ne '')
    then $measures[1]/string(@xml:id)
    else source:get-virtual-measure-id($measures[1], $designation)
};

(:~
 : Returns the measures of an mdiv that carry a given designation.
 :
 : A designation generally occurs once in every part, so this is a sequence rather than a
 : single element. Callers needing exactly one measure take [1] themselves: that constraint
 : belongs to the caller, not to the lookup.
 :
 : @param $doc The source document to resolve against, may be empty
 : @param $mdivId The @xml:id of the mdiv to look in, may be empty
 : @param $designation The measure designation, cf. source:label-or-n, may be empty
 : @return The measures carrying that designation, in document order
 :)
declare function source:resolve-measure-in-mdiv($doc as document-node()?, $mdivId as xs:string?, $designation as xs:string?) as element(mei:measure)* {

    (: Matched against every designation a measure accounts for, not just its own: a range
       label or a multiRest stands for a run of them, and each has to resolve back to the
       measure - and therefore the zone - representing it. :)
    if (string($mdivId) ne '' and string($designation) ne '')
    then source:effective-measures($doc/id($mdivId))[source:measure-designations(.) = $designation]
    else ()
};

(:~
 : Returns the measure elements a virtual measure ID denotes.
 :
 : The ID is split on its LAST underscore, so an mdiv @xml:id that itself contains
 : underscores stays intact; the two halves are then handed to
 : source:resolve-measure-in-mdiv, which is the same lookup the goto-by-name path performs
 : with the mdiv and designation supplied separately rather than encoded in a string.
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
        return
            source:resolve-measure-in-mdiv(
                $doc,
                functx:substring-before-last($reference, '_'),
                functx:substring-after-last($reference, '_'))
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
