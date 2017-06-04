// Keynote Extractor - Advanced output style
// Written in Vanilla Javascript
// @Johan Ronsse / Keynote Extractor 2017
// @1.0.0

/* Initial view setup
   ========================================================================== */

// bool for states
var showNotes = true;
var showShortcuts = false;

// int
var slidePosition = 0;

// selectors for different UI elements
var $shortcutsToggle = document.getElementById('show-shortcuts');
var $shortcuts = document.getElementById('shortcuts');
var $slide = document.querySelectorAll(".slides .slide")
var $slideNotes = document.querySelectorAll(".slides .slide .slide-notes")
var $slidePos = document.getElementById('slide-pos-current');
var $slideTotal = document.getElementById('slides-total');
var $btnPrevSlide = document.getElementById('btn-prev-slide');
var $btnNextSlide = document.getElementById('btn-next-slide');

/* State functions
   ========================================================================== */

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
        // Hide all notes
        for (var i = 0; i < $slideNotes.length; i++) {
            $slideNotes[i].style.display = 'block';
        }
        document.body.classList.add('js-notes-active');
    } else {
        // Show all notes
        for (var i = 0; i < $slideNotes.length; i++) {
            $slideNotes[i].style.display = 'none';
        }
        document.body.classList.remove('js-notes-active');
    }
}

function renderSlide(slideNumber) {
    slidePosition = slideNumber;
    $slidePos.innerHTML = slideNumber;
    updateHash(slideNumber);
    for (var i = 0; i < $slide.length; i++) {
        $slide[i].style.display = 'none';
    }
    var whichSlide = slideNumber - 1;
    $slide[whichSlide].style.display = 'flex';
    updateCounter();
}

function updateHash(slideNumber) {
    window.location.hash = slideNumber;
}

function renderUIState() {
    renderShortcutsState();
    renderNotesState();
}

function init() {
    renderUIState();
    for (var i = 0; i < $slide.length; i++) {
        $slide[i].style.display = 'none';
    }
    var currentHash = parseInt(window.location.hash.substr(1,99));
    if (currentHash <= countSlides()) {
        renderSlide(currentHash);
    } else {
        renderSlide(1);
    }
}

function updateCounter() {
    $slidePos.innerHTML = slidePosition;
    $slideTotal.innerHTML = countSlides();
}

function nextSlide() {
    if (slidePosition == countSlides()) {
        return
    }
    slidePosition = slidePosition + 1;
    renderSlide(slidePosition);

}

function previousSlide() {
    if (slidePosition == 1) {
        return
    }
    slidePosition = slidePosition - 1;
    renderSlide(slidePosition);
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
    init();
});
