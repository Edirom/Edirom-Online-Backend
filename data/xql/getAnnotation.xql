xquery version "3.1";

(:
 : Copyright: For LICENSE-Details please refer to the LICENSE file in the root directory of this repository.
 :)

(: IMPORTS ================================================================= :)

import module namespace annotation = "http://www.edirom.de/xquery/annotation" at "../xqm/annotation.xqm";
import module namespace edition = "http://www.edirom.de/xquery/edition" at "../xqm/edition.xqm";
import module namespace eutil = "http://www.edirom.de/xquery/eutil" at "../xqm/eutil.xqm";
import module namespace source = "http://www.edirom.de/xquery/source" at "../xqm/source.xqm";

(: NAMESPACE DECLARATIONS ================================================== :)

declare namespace edirom_image = "http://www.edirom.de/ns/image";
declare namespace exist = "http://exist.sourceforge.net/NS/exist";
declare namespace mei = "http://www.music-encoding.org/ns/mei";
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace request = "http://exist-db.org/xquery/request";
declare namespace xmldb = "http://exist-db.org/xquery/xmldb";

(: OPTION DECLARATIONS ===================================================== :)

declare option output:media-type "text/html";
declare option output:method "xhtml";

(: VARIABLE DECLARATIONS =================================================== :)

declare variable $imageWidth := 600;

declare variable $edition := request:get-parameter('edition', '');

declare variable $imageserver := eutil:getPreference('image_server', $edition);

declare variable $imageBasePath := eutil:getPreference('image_prefix', $edition);

declare variable $lang := request:get-parameter('lang', '');

(: FUNCTION DECLARATIONS =================================================== :)

(: TODO: in Modul auslagern :)
(:~
 :  Gets the zone holding the graphical representation of an element
 :
 :  @param $elem The element for which the graphical representation shall be found
 :  @return The zone element
 :)
declare function local:getZone($elem as element()) as element()? {

    if ($elem/@facs) then (
        let $zoneId := replace($elem/@facs, '^#', '')
        return
            $elem/root()/id($zoneId)
    ) else
        ($elem)
};

(:~
 :  This function gets the label of a given Annotation Priority
 :
 :  @param $annot the annot with a priority to look for
 :  @return the label for the Priority, or, if this fails, $uri
 :)
declare function local:getPriority($annot as node()) {

    let $uri := $annot/mei:ptr[@type eq 'priority']/string(@target)

    let $doc := if (starts-with($uri, '#')) then (
        $annot/root()
    ) else (
        doc(substring-before($uri, '#'))
    )

    let $locID := substring-after($uri, '#')

    let $elem := $doc/id($locID)

    return
        if ($elem/mei:name) then
            (normalize-space(eutil:getLocalizedName($elem, $lang)))
        else
            ($locID)
};

(:~
 :  This function gets a string representing all Annotation categories
 :
 :  @param $annot the annot with categories to look for
 :  @return the string of annotation labels, or, if one of them fails, the respecitve $uri
 :)
declare function local:getCategories($annot as node()) {

    let $uris := tokenize($annot/mei:ptr[@type eq 'categories']/string(@target), ' ')

    let $string :=
        for $uri in $uris
        let $doc :=
            if (starts-with($uri, '#')) then (
                $annot/root()
            ) else (
                doc(substring-before($uri, '#'))
            )

    let $locID := substring-after($uri, '#')

    let $elem := $doc/id($locID)

    return
        if ($elem/mei:name) then
            (eutil:getLocalizedName($elem, $lang))
        else
            ($locID)
    return
        $string
};

(: TODO: in Modul auslagern :)
(:~
 :  This function generates an image path for a specific zone on an image.
 :  Based on a path prefix and a width.
 :
 :  @param $basePath The base path prefix for the image databse
 :  @param $zone The zone with coordiantes on the image
 :  @param $width The width the image should be loaded with
 :  @return A URL pointing to an image based as xs:string
 :)
declare function local:getImageAreaPath($basePath as xs:string, $zone as element()?, $width as xs:integer) as xs:string {

    let $graphic := $zone/../mei:graphic[@type = 'facsimile']

    let $imgX := number($zone/@ulx)
    let $imgY := number($zone/@uly)
    let $w := number($zone/@lrx) - number($zone/@ulx)
    let $h := number($zone/@lry) - number($zone/@uly)

    let $imagePath := $graphic/@target
    let $imgWidth := number($graphic/@width)
    let $imgHeight := number($graphic/@height)

    let $wx := $imgX div $imgWidth
    let $wy := $imgY div $imgHeight
    let $ww := $w div $imgWidth
    let $wh := $h div $imgHeight

    return
        concat($basePath, $imagePath, '?dw=', $width, '&amp;amp;dh=', $width, '&amp;amp;wx=', $wx, '&amp;amp;wy=', $wy, '&amp;amp;ww=', $ww, '&amp;amp;wh=', $wh, '&amp;amp;mo=fit')
};

(: for tips :)
declare function local:getImageAreaPathForTips($basePath as xs:string, $zone as element()?, $width as xs:integer, $height as xs:integer) as xs:string {
    let $graphic := $zone/../mei:graphic[@type = 'facsimile']

    let $imgX := number($zone/@ulx)
    let $imgY := number($zone/@uly)
    let $w := number($zone/@lrx) - number($zone/@ulx)
    let $h := number($zone/@lry) - number($zone/@uly)

    let $imagePath := $graphic/@target
    let $imgWidth := number($graphic/@width)
    let $imgHeight := number($graphic/@height)

    let $wx := $imgX div $imgWidth
    let $wy := $imgY div $imgHeight
    let $ww := $w div $imgWidth
    let $wh := $h div $imgHeight

    let $cut_path := substring-before($imagePath, '.')

    let $im_path := if ($imageserver = 'digilib')
    then
        (concat($basePath, $imagePath, '?dw=', $width, '&amp;amp;dh=', $height, '&amp;amp;wx=', $wx, '&amp;amp;wy=', $wy, '&amp;amp;ww=', $ww, '&amp;amp;wh=', $wh, '&amp;amp;mo=fit'))
    else
        (
        concat($basePath, $cut_path, '/0-0-0.jpg'))
    return
        $im_path

};

(:~
 :  This function recursively determines the lowest number which's square is higher than
 :  a given number.
 :
 :  @param $i The integer that's increased with every recursive call.
 :  @param $num The integer that's tested.
 :  @return Returns $i if it's square is higher or equals $num.
 :)
declare function local:getLowestSquareBase($i as xs:integer, $num as xs:integer) {

    if ($i * $i lt $num) then
        (local:getLowestSquareBase($i + 1, $num))
    else
        ($i)
};

declare function local:getItemLabel($elem as element()) {

    let $name := local-name($elem)
    return (
        if($name = 'measure') then (
            if ($lang = 'de') then
                (concat('Takt ', if ($elem/@label) then ($elem/@label) else ($elem/@n)))
            else
                (concat('Bar ',if ($elem/@label) then ($elem/@label) else ($elem/@n)))
        ) else
            (),

        if ($name = 'staff') then (
            if ($lang = 'de') then
                (concat($elem/preceding::mei:staffDef[@n = $elem/@n][1]/@label.abbr, ', Takt ', $elem/ancestor::mei:measure/@n))
            else
                (concat($elem/preceding::mei:staffDef[@n = $elem/@n][1]/@label.abbr, ', Bar ', $elem/ancestor::mei:measure/@n))
        ) else
            (),

        if ($name = 'zone') then (
            if ($lang = 'de') then
                (concat('Ausschnitt (S. ', $elem/parent::mei:surface/@n, ')'))
            else
                (concat('Detail (p. ', $elem/parent::mei:surface/@n, ')'))
        ) else
            ()
    )
};

(:~
 :   This function…
 :
 :)
declare function local:calculatePreviewsForTip($participants as xs:string*) {

    let $areaWidth := 204
    let $areaHeight := 254

    let $elems :=
        for $pUri in $participants
        return
            doc(substring-before($pUri, '#'))/id(substring-after($pUri, '#'))

    let $zones :=
        for $elem in $elems
        return
            local:getZone($elem)

    let $tall := some $zone in $zones
        satisfies (number($zone/@lry) - number($zone/@uly) gt 2 * (number($zone/@lrx) - number($zone/@ulx)))

    let $wide := some $zone in $zones
        satisfies (2 * (number($zone/@lry) - number($zone/@uly)) lt number($zone/@lrx) - number($zone/@ulx))

    let $w :=
        if ($tall and not($wide)) then
            (round(10000 div count($zones)) div 100)
        else (
            if ($wide and not($tall)) then
                (100)
            else
                (round(10000 div local:getLowestSquareBase(1, count($zones))) div 100)
        )

    let $h :=
        if ($tall and not($wide)) then
            (100)
        else (
            if ($wide and not($tall)) then
                (round(10000 div count($zones)) div 100)
            else
                (round(10000 div local:getLowestSquareBase(1, count($zones))) div 100)
        )

    let $width := floor($areaWidth * $w div 100)

    let $height := floor($areaHeight * $h div 100)

    for $zone in $zones
    let $e := $elems[substring(@facs, 2) = $zone/@xml:id][1]

    let $e :=
        if ($e) then
            ($e)
        else
            ($zone)

    let $test :=
        if ($imageserver = 'digilib') then (
            <div
                class="previewItem"
                style="width: {$width - (round(100 div $w))}px; height: {$height - round(100 div $h)}px;">
                <div
                    class="imgBox">
                    <img
                        src="{local:getImageAreaPathForTips($imageBasePath, $zone, $width - 4, $height - 4)}"
                        class="previewImg"/>
                </div>
                <div
                    class="label">{local:getItemLabel($e)}</div>
            </div>
        ) else (
            <div
                class="previewItem"
                style="width: {256}px; height: {256}px;">
                <div
                    class="imgBox">
                    <img
                        src="{local:getImageAreaPathForTips($imageBasePath, $zone, $width - 4, $height - 4)}"
                        class="previewImg"/>
                </div>
                <div
                    class="label">{local:getItemLabel($e)}</div>
            </div>
        )

    return
        $test
};

let $uri := request:get-parameter('uri', '')

let $target := request:get-parameter('target', '')

let $docUri := substring-before($uri, '#')

let $internalId := substring-after($uri, '#')

let $doc := doc($docUri)

let $annot := $doc/id($internalId)

let $participants := annotation:getParticipants($annot)

let $priority := local:getPriority($annot)

let $priorityLabel :=
    if ($lang = 'de') then
        ('Priorität')
    else
        ('Priority')

let $categories := local:getCategories($annot)

let $categoriesLabel :=
    if ($lang = 'de') then (
        if (count($categories) gt 1) then
            ('Kategorien')
        else
            ('Kategorie')
    ) else (
        if (count($categories) gt 1) then
            ('Categories')
        else
            ('Category'))

let $sources := eutil:getDocumentsLabelsAsArray($participants, $edition)

let $sourcesLabel :=
    if ($lang = 'de') then (
        if (count($sources) gt 1) then
            ('Quellen')
        else
            ('Quelle')
    ) else (
        if (count($sources) gt 1) then
            ('Sources')
        else
            ('Source')
    )

let $sigla := source:getSiglaAsArray($participants)

let $siglaLabel :=
    if ($lang = 'de') then (
        if (count($sigla) gt 1) then
            ('Siglen')
        else
            ('Siglum')
    ) else (
        if (count($sigla) gt 1) then
            ('Sources')
        else
            ('Source')
    )

let $annotIDlabel :=
    if ($lang = 'de') then
        ('Anm.-ID')
    else
        ('Annot.-ID')

return
    if ($target eq 'view') then (
        <div class="annotView">
            <div class="metaBox">
                <div class="property priority">
                    <div class="key">{$priorityLabel}</div>
                    <div class="value">{$priority}</div>
                </div>
                <div class="property categories">
                    <div class="key">{$categoriesLabel}</div>
                    <div class="value">{string-join($categories, ', ')}</div>
                </div>
                <!--<div class="property sourceLabel">
                    <div class="key">{$sourcesLabel}</div>
                    <div class="value">{string-join($sources, ', ')}</div>
                </div>-->
                <div class="property sourceSiglums">
                    <div class="key">{$siglaLabel}</div>
                    <div class="value">{string-join($sigla, ', ')}</div>
                </div>
                <div class="property annotID">
                    <div class="key">{$annotIDlabel}</div>
                    <div class="value">{$internalId}</div>
                </div>
            </div>
            <div class="contentBox">
                <h1>{eutil:getLocalizedName($annot, $lang)}</h1>
                {annotation:getContent($annot, '', $edition)}
            </div>

            <!-- <div class="previewArea">
                {

                 if($imageserver = 'digilib') then (
                    for $pUri in tokenize($annot/string(@plist), ' ')
                    let $elem := doc(substring-before($pUri, '#'))/id(substring-after($pUri, '#'))
                    let $zone := local:getZone($elem)
        				return
                        <div class="previewItem">
                            <div class="imgBox">
                                <img src="{local:getImageAreaPath($imageBasePath, $zone, $imageWidth)}" class="previewImg" onclick="loadLink('{$pUri}')" />
                                <input type="hidden" class="previewImgData" value="{concat('{width:', number($zone/@lrx) - number($zone/@ulx), ', height:', number($zone/@lry) - number($zone/@uly), '}')}"/>
                            </div>
                            <div class="label">{if ($lang = 'de') then (concat('Takt ', $elem/@n)) else (concat('Bar ', $elem/@n))}</div>
                        </div>

                  )
            	else(
                	for $pUri in tokenize($annot/string(@plist), ' ')
                    let $elem := doc(substring-before($pUri, '#'))/id(substring-after($pUri, '#'))
                    let $zone := local:getZone($elem)
                	return
    				<div class="previewItem">
                            <div class="imgBox">
                                <img src="{local:getImageAreaPath($imageBasePath, $zone, $imageWidth)}" class="previewImg" onclick="loadLink('{$pUri}')" />
                                <input type="hidden" class="previewImgData" value="{concat('{width:', number($zone/@lrx) - number($zone/@ulx), ', height:', number($zone/@lry) - number($zone/@uly), '}')}"/>
                            </div>
                            <div class="label">{concat('Takt ', $elem/@n)}</div>
                        </div>
    				)

                }
            </div>-->

        </div>
    ) else (
        <div class="annotTip">
            <div class="metaBox">
                <div class="property priority">
                    <div class="key">{$priorityLabel}</div>
                    <div class="value">{$priority}</div>
                </div>
                <div class="property categories">
                    <div class="key">{$categoriesLabel}</div>
                    <div class="value">{string-join($categories, ', ')}</div>
                </div>
                <!--<div class="property sourceLabel">
                    <div class="key">{$sourcesLabel}</div>
                    <div class="value">{string-join($sources, ', ')}</div>
                </div>-->
                <div class="property sourceSiglums">
                    <div class="key">{$siglaLabel}</div>
                    <div class="value">{string-join($sigla, ', ')}</div>
                </div>
                <div class="property annotID">
                    <div class="key">{$annotIDlabel}</div>
                    <div class="value">{$internalId}</div>
                </div>
            </div>
            <div class="contentBox">
                {
                    for $a in (if($annot/mei:annot) then ($annot/mei:annot) else ($annot))
                        
                        let $title := eutil:getLocalizedTitle($annot, $lang, '')

                        return (
                            if ($title!='') then (
                                <h1>{$title}</h1>,
                                annotation:getContent($a, '', $edition)
                            ) else (
                                annotation:getContent($a, '', $edition)
                            )
                        )
                }
            </div>
            <!-- <div class="previewArea">
                {
                    local:calculatePreviewsForTip(tokenize($annot/string(@plist),' '))

                }
            </div>-->
        </div>

        )
