xquery version "3.1";

(:
 : Copyright: For LICENSE-Details please refer to the LICENSE file in the root directory of this repository.
 :)

(:~
    Returns the HTML for a specific annotation for an AnnotationView.

    @author <a href="mailto:kepper@edirom.de">Johannes Kepper</a>
    @author <a href="mailto:bohl@edirom.de">Benjamin W. Bohl</a>
:)

(: TODO move a way from returning HTML for Edirom-API 2.0 :)

(: IMPORTS ================================================================= :)

import module namespace annotation = "http://www.edirom.de/xquery/annotation" at "../xqm/annotation.xqm";
import module namespace doc = "http://www.edirom.de/xquery/document" at "../xqm/document.xqm";
import module namespace edition = "http://www.edirom.de/xquery/edition" at "../xqm/edition.xqm";
import module namespace eutil = "http://www.edirom.de/xquery/eutil" at "../xqm/eutil.xqm";
import module namespace source = "http://www.edirom.de/xquery/source" at "../xqm/source.xqm";
import module namespace taxonomy = "http://www.edirom.de/xquery/taxonomy" at "../xqm/taxonomy.xqm";

(: NAMESPACE DECLARATIONS ================================================== :)

declare namespace mei = "http://www.music-encoding.org/ns/mei";
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace request = "http://exist-db.org/xquery/request";

(: OPTION DECLARATIONS ===================================================== :)

declare option output:method "xhtml";
declare option output:media-type "text/html";

let $lang := request:get-parameter('lang', '')
let $edition := request:get-parameter('edition', '')
let $uri := request:get-parameter('uri', '')
let $docUri := substring-before($uri, '#')
let $internalId := substring-after($uri, '#')
let $doc := eutil:getDoc($docUri)
let $annot := $doc/id($internalId)

let $participants := annotation:getParticipants($annot)

(: TODO deprecate below categories and priorities fields with Edirom-Online-API 2.0.0 :)
let $hideLegacyFields := xs:boolean(edition:getPreference('annotation_hide_legacy_fields', $edition))
let $priority := annotation:getPriorityLabel($annot)
let $priorityLabel := switch ($priority)
     case ""
         return
             ()
     default return
         eutil:getLanguageString('ediromPriority', ()) || ' (legacy)'

 let $categories := annotation:get-category-labels-as-sequence($annot)
 let $categoriesLabel :=
    switch (count($categories))
        case 0 return ()
        case 1 return
             eutil:getLanguageString('ediromCategory', ()) || ' (legacy)'
        default return
         eutil:getLanguageString('ediromCategory_multiple', ()) || ' (legacy)'

(: TODO deprecate above categories and priorities fields with Edirom-Online-API 2.0.0 :)

let $taxonomiesArray := annotation:get-referenced-categories-as-taxonomy-array($annot, $doc, $lang)

let $sigla := source:getSiglaAsArray($participants)
let $siglaLabel := switch (count($sigla))
    case 0 return
        ()
    case 1 return
        eutil:getLanguageString('view.window.AnnotationView_Source', ())
    default return
        eutil:getLanguageString('view.window.AnnotationView_Sources', ())

let $annotIDlabel := eutil:getLanguageString('view.window.AnnotationView_AnnotationID', ())

return

    <div class="annotView">
        <div class="metaBox">
            {
                if($hideLegacyFields) then
                    ()
                else (
                    (: TODO deprecate priority field with Edirom-Online-API 2.0.0 :)
                    <div class="property priority">
                        <div class="key">{$priorityLabel}</div>
                        <div class="value">{$priority}</div>
                    </div>,
                    (: TODO deprecate categories field with Edirom-Online-API 2.0.0 :)
                    <div class="property categories">
                        <div class="key">{$categoriesLabel}</div>
                        <div class="value">{string-join($categories, ', ')}</div>
                    </div>
                )
            }
            {
                for $t in $taxonomiesArray?*
                (: TODO process single vs. _multiple for keys :)
                return
                    <div class="property taxonomy-{$t('id')}">
                        <div class="key">{
                            (: mirror the frontend: a real @label is used as-is, otherwise the
                               identifier is looked up in the locale files (id as last resort) :)
                            if ($t('label') != $t('id')) then
                                $t('label')
                            else switch(array:size($t('items')))
                                case 1 return
                                    (eutil:getLanguageString(edition:getLanguageFileURI($edition, $lang), $t('id'), (), $lang), $t('id'))[1]
                                default return
                                    (: for more than one item try to fetch plural label, fallback to singular, then to id :)
                                    (eutil:getLanguageString(edition:getLanguageFileURI($edition, $lang), $t('id') || '_multiple', (), $lang),
                                     eutil:getLanguageString(edition:getLanguageFileURI($edition, $lang), $t('id'))
                                     )[1]
                        }</div>
                        <div class="value">{string-join($t('items')?*?name, ', ')}</div>
                    </div>
            }
            <div class="property sourceSiglums">
                <div class="key">{$siglaLabel}</div>
                <div class="value">{string-join($sigla, ', ')}</div>
            </div>
            <div class="property annotID">
                <div class="key">{$annotIDlabel}</div>
                <div class="value">{$internalId}</div>
            </div>
        </div>
    </div>
