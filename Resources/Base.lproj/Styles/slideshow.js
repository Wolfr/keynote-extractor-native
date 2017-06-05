// Keynote Extractor - Advanced output style
// Written in Vanilla Javascript
// @Johan Ronsse / Keynote Extractor 2017
// @1.2.0 Production

var showNotes = true;
var showShortcuts = false;

var slideNumber = 1;

var $shortcutsToggle = document.getElementById('show-shortcuts');
var $shortcuts = document.getElementById('shortcuts');
var $slide = document.querySelectorAll(".slides .slide")
var $slideNotes = document.querySelectorAll(".slides .slide .slide-notes")
var $slidePos = document.getElementById('slide-pos-current');
var $slideTotal = document.getElementById('slides-total');
var $btnPrevSlide = document.getElementById('btn-prev-slide');
var $btnNextSlide = document.getElementById('btn-next-slide');

function changeShowShortcutsState() {
    if (showShortcuts) {
        showShortcuts = false;
    } else {
        showShortcuts = true;
    }
}

function countSlides() {
    return $slide.length
}

function renderShortcutsState() {
    if (showShortcuts) {
        $shortcuts.style.display = 'block';
    } else {
        $shortcuts.style.display = 'none';
    }
}

function renderNotesState() {

    if (showNotes) {
        for (var i = 0; i < $slideNotes.length; i++) {
            $slideNotes[i].style.display = 'block';
        }
        document.body.classList.add('js-notes-active');
    } else {
        for (var i = 0; i < $slideNotes.length; i++) {
            $slideNotes[i].style.display = 'none';
        }
        document.body.classList.remove('js-notes-active');
    }

}

function hideSlides() {
    for (var i = 0; i < $slide.length; i++) {
        $slide[i].style.display = 'none';
    }
}

function renderSlide(slideNumber, withHistory) {

    if (slideNumber) {
        hideSlides();
        whichSlide = slideNumber - 1;
        $slide[whichSlide].style.display = 'flex';
        updateCounter(slideNumber);
        if (withHistory) {
            pushHistoryState(slideNumber);
        }
    } else {
        throw "Please define a slide number to render"
    }

}

function getHash() {
    return parseInt(window.location.hash.substr(1,9999));
}

function setHash(slideNumber) {
    if (slideNumber) {
        window.location.hash = slideNumber;
    } else {
        throw "Please provide an argument to setHash"
    }
}

function renderUIState() {

    renderShortcutsState();
    renderNotesState(); 

}

function updateCounter(slideNumber) {
    $slidePos.innerHTML = slideNumber;
}

function pushHistoryState(slideNumber) {
    currentUrl = window.location.href.substr(0, window.location.href.indexOf('#'))
    history.pushState({ lastSlideNumber: slideNumber },'', currentUrl + '#' + slideNumber);
}

function previousSlide() {

    if (slideNumber != 1) {
        slideNumber = slideNumber - 1;
        renderSlide(slideNumber, true);
    }

}

function nextSlide() {

    if (slideNumber != countSlides()) {
        slideNumber = slideNumber + 1;
        renderSlide(slideNumber, true);
    }

}

function init() {

    renderUIState();

    if (!window.location.hash) {
        setHash("1");
        slideNumber = getHash();
        renderSlide(slideNumber, true);
    } else {
        if (window.location.hash == "#0") {
            alert('this');
            setHash("1");
            slideNumber = getHash();
            renderSlide(slideNumber, true);
        } else {
            slideNumber = getHash();
            renderSlide(slideNumber, true);
        }
    }

    $slideTotal.innerHTML = countSlides();

}

document.addEventListener("DOMContentLoaded", function(event) { 

    $btnPrevSlide.onclick = function() {
        previousSlide();
    }

    $btnNextSlide.onclick = function() {
        nextSlide();
    }

    $shortcutsToggle.onclick = function() {
        changeShowShortcutsState();
        renderShortcutsState();
    };

    document.body.onkeyup =  function(e) {

        if (e.keyCode === 191) {
            changeShowShortcutsState();
            renderShortcutsState();
        }

        if (e.keyCode === 78) {
            if (showNotes) {
                showNotes = false;
            } else {
                showNotes = true;
            }
            renderNotesState()
        }

        if (e.keyCode === 37) {
            previousSlide()
        }

        if (e.keyCode === 39) {
            nextSlide()
        }

    };

    window.addEventListener('popstate', function(e) {
        var histState = e.state;
        console.log(e.state);
        renderSlide(histState.lastSlideNumber);
    });

    init();

});
