// --
// ITSM.Agent.CABMemberSearch.js - provides the special module functions for the user search
// Copyright (C) 2001-2010 OTRS AG, http://otrs.org/\n";
// --
// This software comes with ABSOLUTELY NO WARRANTY. For details, see
// the enclosed file COPYING for license information (AGPL). If you
// did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
// --

"use strict";

var ITSM = ITSM || {};
ITSM.Agent = ITSM.Agent || {};

/**
 * @namespace
 * @exports TargetNS as ITSM.Agent.CABMemberSearch
 * @description
 *      This namespace contains the special module functions for the CAB search.
 */
ITSM.Agent.CABMemberSearch = (function (TargetNS) {

    /**
     * @function
     * @param {jQueryObject} $Element The jQuery object of the input field with autocomplete
     * @return nothing
     *      This function initializes the special module functions
     */
    TargetNS.Init = function ($Element) {

        if (isJQueryObject($Element)) {

            Core.UI.Autocomplete.Init(
                $Element,
                function (Request, Response) {
                    var URL = Core.Config.Get('Baselink'), Data = {
                        Action: 'AgentITSMCABMemberSearch',
                        Term: Request.term + '*',
                        Groups : Core.Config.Get('CABAutocomplete.Groups') || '',
                        MaxResults: Core.UI.Autocomplete.GetConfig('MaxResultsDisplayed')
                    };

                    $Element.data('AutoCompleteXHR', Core.AJAX.FunctionCall(URL, Data, function (Result) {
                        var Data = [];
                        $.each(Result, function () {
                            Data.push({
                                label: this.UserValue + " (" + this.UserKey + ")",
                                value: this.UserValue,
                                type: this.UserType
                            });
                        });
                        Response(Data);
                    }));
                },
                function (Event, UI) {

                    var UserKey = UI.item.label.replace(/.*\((.*)\)$/, '$1');
                    $Element.val(UI.item.value);

                    // set hidden field UserSelected
                    $('#' + Core.App.EscapeSelector($Element.attr('id')) + 'Selected').val(UserKey);
                    $('#' + Core.App.EscapeSelector($Element.attr('id')) + 'Type').val(UI.item.type);

                    return false;
                },
                'CustomerSearch'
            );
        }
        // On unload remove old selected data. If the page is reloaded (with F5) this data stays in the field and invokes an ajax request otherwise
        $(window).bind('unload', function () {
            // escape possible colons (:) in element id because jQuery can not handle it in id attribute selectors
            $('#' + Core.App.EscapeSelector($Element.attr('id')) + 'Selected').val('');
        });
    };

    return TargetNS;
}(ITSM.Agent.CABMemberSearch || {}));