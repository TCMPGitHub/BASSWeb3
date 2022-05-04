$(function () {
    kendo.init($("init"));
    
    $('#SearchString').keydown(function (e) {
        if (e.keyCode == 13) {
            onClick(e);
        }
    });
      
    //    if ($("#hdUnassign").val() == "True") {
    //        var warningText = "You are about to unassign this Offender's benefit worker.";
    //        if (currentUserID.toString() === CaseAssigned) { // $("#unassignButton").data("benefitWorkerId")) {
    //            warningText = "You are about to remove this Offender from your caseload.\n\nIf you proceed, you may no longer be able to edit this Offender's data or retrieve any unsaved changes on this page.";
    //        }
    //        proceed = confirm("WARNING: " + warningText + "\n\nClick 'OK' to confirm; otherwise, click 'Cancel'.");
    //    }
    //    else if (unsavedApplicationChanges()) {
    //        var warningText = "You have unsaved application that will be lost if continue saving offender data.";
    //        proceed = confirm("WARNING: " + warningText + "\n\nClick 'OK' to confirm; otherwise, click 'Cancel'.");
    //    }
});
function is_valid_date(value) {
    // capture all the parts
    var matches = value.match(/^(\d{2})\/(\d{2})\/(\d{4})$/);
    if (matches === null) {
        return true;
    } else {
        // now lets check the date sanity
        var year = parseInt(matches[3], 10);
        var month = parseInt(matches[1], 10) - 1; // months are 0-11
        var day = parseInt(matches[2], 10);

        var date = new Date(year, month, day);
        if (date.getFullYear() !== year
          || date.getMonth() != month
          || date.getDate() !== day

        ) {
            return false;
        } else {
            return true;
        }
    }
}

function TextarePopup(e, edit, color) {
    edit = (edit && e.target.className.indexOf("alwayReadonly") < 0);
    var object = "<textarea id='notebox' name='notebox' style='width: 99%; height: 100%; background-color:white; font-size:16px;' onKeyUp = 'TAKeyUp(event)'></textarea>";
    var ttl = (edit) ? (e.target.value.length == 0 ? "Add Note" : "Edit Note") : "View Note";
    var buttons = {
        "1": { id: 'close', text: 'Close(Esc)', click: function () { $(this).dialog("close"); }, "class": "ui-dialog-button" }
    };
    //Add another button to that object if some condition is true
    if (edit) {
        buttons = {
            "1": { id: 'close', text: 'Close(Esc)', click: function () { $(this).dialog("close"); }, "class": "ui-dialog-button" },
            "2": { id: 'save', text: 'Save(Ctrl+q)', click: function () {
                    var val = $("#notebox").val();
                    if (val.length > 0) {
                        if (val.length > e.target.maxLength) {
                            NotifyMessage("The input string exceeds the maximum size: " + e.target.maxLength);
                            return;
                        }
                        val = remove_non_ascii(val);
                    }
                    e.target.value = val;
                    $(this).dialog("close"); }, "class": "ui-dialog-button" }
        };
    }
    
    if (edit == false)
        object = "<textarea id='notebox' name='notebox' style='width: 99%; height: 100%; background-color:white; font-size:16px;' readonly='readonly' ></textarea>";

    $("#pdfdialog").html(object)
        .dialog({
            modal: true,
            width: '80vw',
            height: 400,
            title: ttl,
            resizable: true,
            responsive: true,
            dialogClass: color,
            buttons: buttons,
            closeText: ''
        });
   
    document.getElementById("notebox").value =e.target.value; 
    return;
}
function SetDatePickerPlaceHolder(obj) {
    if (obj !== undefined && obj.length > 0) {
        var picker = obj.kendoDatePicker({ dateInput: true }).data('kendoDatePicker');
        picker._dateInput.setOptions({
            messages: {
                year: "____",
                month: "__",
                day: "__",
            }
        });
    }
}
function serialiseForm(form) {
    var elems = [].filter.call(form[0].getElementsByTagName("input"), function (input) {
         return input.value === "something";
    });
    var input = form[0].getElementsByTagName("input");
    var formData = {};
    for (var i = 0; i < input.length; i++) {
        formData[input[i].name] = input[i].value;
    }
    return formData = JSON.stringify(formData);
}
function serialize(form) {
    var result = [];
    if (typeof form === 'object' && form.nodeName === 'FORM')
        Array.prototype.slice.call(form.elements).forEach(function (control) {
            if (control.name && !control.disabled && ['file', 'reset', 'submit', 'button'].indexOf(control.type) === -1) {
                if (control.type === 'select-multiple')
                    Array.prototype.slice.call(control.options).forEach(function (option) {
                        if (option.selected)
                            result.push(encodeURIComponent(control.name) + '=' + encodeURIComponent(option.value));
                    });
                else if (['checkbox', 'radio'].indexOf(control.type) === -1 || control.checked)
                {
                    result.push(encodeURIComponent(control.name) + '=' +
                        encodeURIComponent((control.name == "Inmate.DOB" || control.name == "Inmate.ReleaseDate" ||
                          control.name == "Inmate.CIDServiceRefusalDate" || control.name == "Inmate.ScreeningDate" ||
                          control.name == "App.PhoneInterviewDate" || control.name == "App.OutcomeDate" ||
                          control.name == "App.AppliedOrRefusedOnDate" || control.name == "App.IssuedOnDate") ? ReplaceDateDefaultString(control.value) : control.value));
                }
            }
        });
    return result.join('&').replace(/%20/g, '+');
}
function ReplaceDateDefaultString(str)
{
    var value = str.replace("month/day/year", "");
    value = value.replace("__/__/____", "");
    return value;
}
function ReplaceAll(string, search, replace) {
    return string.split(search).join(replace);
}
function ConvertDateTime(obj){
    var value = new Date( parseInt(obj.replace(/(^.*\()|([+-].*$)/g, '')));
    var dat = value.getMonth() + 1 + "/" + value.getDate() + "/" + value.getFullYear();
    return dat;
}
function DateDiff(date1, date2) {
    //var datediff = date1.getTime() - date2.getTime();
    return (((new Date(date1)) - (new Date(date2))) / 1000 / 60 / 60 / 24);
}
function postFormAndReplaceDivHtml(formObj, successCallback) {
    var form = formObj;
    var url = "";
    var submission = "";
    if (formObj[0].className == "flex-item-b") {
        form = document.getElementById('offenderDataForm');
    }
    else if (formObj[0].id.indexOf('App') > 0) {
        if (document.getElementById('appForm' + formObj[0].id.substring(0, formObj[0].id.length - 3)).children[0].id !== "")
            form = document.getElementById('appForm' + formObj[0].id.substring(0, formObj[0].id.length - 3)).children[0];
        else
            form = document.getElementById('appForm' + formObj[0].id.substring(0, formObj[0].id.length - 3));
    }
    else {
        form = document.getElementById(formObj[0].id);
    }
    url = form.action;
    submission = serialize(form);
    
    $.ajax({
        type: 'POST',
        url: url,
        data: submission,
        cache: false,
        dataType: "Html",
        success: function (data, status, xhr) {
            formObj.html(data);
            if (successCallback !== undefined) successCallback();
        }.bind(this),
        error: function (data, textStatus, xhr) {
            return false;
        }
    });
    return false;
}
function EditableEpisode(obj) {
    var editable = false;
    var ddp = $("#RefEpisode").data("kendoDropDownList");
    if (ddp === undefined)
        return editable;

    if (ddp.text().indexOf("*") > 0 && obj === "True") {
        editable = true;
    }
    return editable;
}
function UnsavedChanges(formID) {
    var unsavedMsg = "";
    if ($("#offenderDataForm :submit:enabled").length > 0 ) {
        if (formID !== "offenderDataForm")
            unsavedMsg = "Offender";
    }
    if ($("#appFormMediCal :submit:enabled").length > 0) {
        if (formID !== "appFormMediCal") {
            if (unsavedMsg.length > 0) unsavedMsg += ";";
            unsavedMsg += "Medi-Cal Application";
        }
    }
    if ($("#appFormSSI :submit:enabled").length > 0) {
        if (formID !== "appFormSSI") {
            if (unsavedMsg.length > 0) unsavedMsg += ";";
            unsavedMsg += "SSI Application";
        }          
    }
    if ($("#appFormVA :submit:enabled").length > 0) {
        if (formID !== "appFormVA") {
            if (unsavedMsg.length > 0) unsavedMsg += ";";
            unsavedMsg += "VA Application";
        }          
    }
    return unsavedMsg;
}
function DisableInputFields(formString, edit) {
    $(formString).each(function () {
        if (this.type === "textarea") {
            $(this).prop('readonly', (edit ? '' : 'readonly'));
        }
        else if (this.type === "submit" || this.type === "button")
            $(this).prop("disabled", !edit)
        else if (this.className.indexOf("k-textbox") > -1) {
            if (edit) {
                if ($(this).hasClass("k-state-disabled"))
                    $(this).prop("disabled", false).removeClass("k-state-disabled");
            }
            else {
                if (!$(this).hasClass("k-state-disabled"))
                    $(this).prop("disabled", false).addClass("k-state-disabled");
            }
        }
        else if (this.type === "checkbox") {
           $(this).prop("disabled", !edit);
        }
        $(".k-list-container").each(function () {
            var elementId = this.id.substring(0, this.id.length - 5)
            var tempDL = $("#" + elementId).data("kendoDropDownList");
            if (tempDL != undefined) {
                if (!tempDL._arrow.children()[0].hasAttribute("unselectable"))
                    tempDL._arrow.children().attr("unselectable", "on");
            }
        });
    });
    
    $(".k-calendar-container").each(function () {
        var elementId = this.id.split("_")[0];
        var tempDP = $("#" + elementId).data("kendoDatePicker");
        if (tempDP != undefined && formString.indexOf(tempDP.element[0].form.id) >= 0) {
            tempDP.enable(edit);
        }
    });
}
function CompareDates(DateA, DateB) {
    var a = new Date(DateA);
    var b = new Date(DateB);

    var msDateA = Date.UTC(a.getFullYear(), a.getMonth() + 1, a.getDate());
    var msDateB = Date.UTC(b.getFullYear(), b.getMonth() + 1, b.getDate());

    if (parseFloat(msDateA) < parseFloat(msDateB))
        return -1;  // less than
    else if (parseFloat(msDateA) == parseFloat(msDateB))
        return 0;  // eq
    else if (parseFloat(msDateA) > parseFloat(msDateB))
        return 1;  // great than
    else
        return null;  // error

}
function IgnoreEnterKey(e) {
    if (e.keyCode === 13) {
        e.preventDefault();
    }
    else if ( e.keyCode === 34) {
        e.preventDefault();
    }
    else if(e.keyCode ===  8){
        e.preventDefault();
    }
}
function monthDiff(startdate, enddate) {
    //var startdate = Date.parseExact($("#startingDate").val(), "dd/MM/yyyy");
    //var enddate = Date.parseExact($("#endingDate").val(), "dd/MM/yyyy");
    var months = 0;
    while (startdate < enddate) {
        if (startdate.getMonth() === 1 && startdate.getDate() === 28) {
            months++;
            startdate.addMonths(1);
            startdate.addDays(2);
        } else {
            months++;
            startdate.addMonths(1);
        }
    }
    return months;
}