//=require jquery.tagsinput.min

var updateRemainingCharacters = function (event) {
    var charLimit = event.target.maxLength;
    var presentCount = event.target.value.length;
    var totalChars = charLimit - presentCount;
    $('#app-total-chars').html(totalChars);
};

var disableSubmission = function () {
    $(".app-response-submission").attr("disabled", "disabled");
    $(".app-response-submission").css("display", "none");
    $(".back-btn").removeClass("hidden")
    $("#timeout_alert").html('<div class="alert alert-danger"> <strong>Oops..!</strong> Your submission time has been expired..</div>')
    setTimeout(function () {
        $(".alert").alert('close')
    }, 5000);

};

var showRemainingTime = function () {
    var date = new Date();
    var remainingTimeElement = $("#app-remaining-time");
    var time = remainingTimeElement.html();
    date.setSeconds(time);
    remainingTimeElement
        .countdown(date.toLocaleString(), function (event) {
            $(this).text(
                event.strftime('%H:%M:%S')
            );
            var remaining_time = remainingTimeElement.html();
            if (remaining_time == "00:00:00")
                disableSubmission();
        });
};

var showRemainingCharacters = function () {
    $('#text').on('input', updateRemainingCharacters);
};

var remove_flash_messages = function () {
    $(".alert").ready(function () {
        setTimeout(function () {
            $(".alert").alert('close')
        }, 4000);
    })
};

document.addEventListener("turbolinks:load", function () {
    showRemainingCharacters();
    showRemainingTime();
    remove_flash_messages();
    initializeTaggings();
    initializeReviewButtions();
});

var initializeTagsInput = function () {
    var tags = new Bloodhound({
        datumTokenizer: Bloodhound.tokenizers.obj.whitespace('name'),
        queryTokenizer: Bloodhound.tokenizers.whitespace,
        prefetch: {
            url: '/tags.json',
            cache: false
        }
    });
    tags.initialize();

    var elt = $('.app-input-tag');
    elt.tagsinput({
        tagClass: function (item) {
            return 'app-tag-input-' + item.id;
        },
        itemValue: 'id',
        itemText: 'name',
        typeaheadjs: [
            {
                hint: true,
                highlight: true,
                minLength: 2
            },
            {
                name: 'tags',
                displayKey: 'name',
                source: tags.ttAdapter()
            }
        ]
    });

    elt.on('itemAdded', function (event) {
        var tag_id = event.item.id;
        var tag_color = event.item.color;
        var ele = $('.app-tag-input-' + tag_id);
        ele.css('background-color', tag_color);
    });

    elt.on('beforeItemAdd', function (event) {
        if (event.options && event.options.preventBackendCall)
            return;
        var tagName = event.item.name;
        var responseId = $(event.target).attr('data-response-id');
        onTagAddition(tagName, responseId);
    });

    elt.on('beforeItemRemove', function (event) {
        if (event.options && event.options.preventBackendCall)
            return;
        var responseId = $(event.target).attr('data-response-id');
        var tagName = event.item.name;
        onTagRemoval(tagName, responseId);
    });

    $(".twitter-typeahead").css('display', 'inline');
};

var initializePreviousTags = function () {
    $('.app-input-tag').each(function (index, inputTag) {
        var ele = $(inputTag);
        var tags = JSON.parse(ele.attr('data-tags'));
        tags.forEach(function (tag) {
            ele.tagsinput('add', tag, {preventBackendCall: true});
        })
    })
};

var initializeTaggings = function () {
    initializeTagsInput();
    initializePreviousTags();
};

var requester = function (url, method, data) {
    return $.ajax({
        url: url,
        type: method,
        data: data
    });
};

var onTagAddition = function (tagName, responseId) {
    var uri = 'create_tagging_by_tag_name';
    var method = 'POST';
    var url = '/responses/' + responseId + '/taggings/' + uri;
    var data = {tag_name: tagName};
    requester(url, method, data)
};

var onTagRemoval = function (tagName, responseId) {
    var uri = 'delete_tagging_by_tag_name';
    var method = 'DELETE';
    var self = $(this);
    var url = '/responses/' + responseId + '/taggings/' + uri;
    var data = {tag_name: tagName};
    requester(url, method, data);
};

var initializeReviewButtions = function () {
    $('.app-tag-review-btn').on('click', function () {
        var uri = 'review_taggings';
        var method = 'PUT';
        var self = $(this);
        var response_id = self.attr('data-response-id');
        var url = '/responses/' + response_id + '/taggings/' + uri;
        var data = {};
        requester(url, method, data, onSuccess);
    });
};
