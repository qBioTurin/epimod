$(document).ready(function() {
  
  // --- UNIFIED PALETTE PREVIEW LOGIC ---
  
  // Helper to handle selectize live updates
  function setupSelectizeLive(selectId, shinyInputName) {
    var $select = $('#' + selectId);
    
    $(document).on('mouseenter', '#' + selectId + ' + .selectize-control .selectize-dropdown .option', function() {
      var val = $(this).attr('data-value');
      if (val !== undefined) {
        Shiny.setInputValue(shinyInputName, val, {priority: 'event'});
      }
    });

    $(document).on('keydown', '#' + selectId + ' + .selectize-control .selectize-input', function(e) {
      var keys = [38, 40, 33, 34, 36, 35]; // Up, Down, PageUp, PageDown, Home, End
      if (keys.indexOf(e.which) !== -1) {
        setTimeout(function() {
          var $dropdown = $('#' + selectId + ' + .selectize-control .selectize-dropdown');
          var $active = $dropdown.find('.option.active').first();
          if ($active.length) {
            var v = $active.attr('data-value');
            if (v !== undefined) {
              Shiny.setInputValue(shinyInputName, v, {priority: 'event'});
            }
          }
        }, 0);
      }
    });

    $(document).on('mousedown', function(e) {
      setTimeout(function() {
        var $dropdown = $('#' + selectId + ' + .selectize-control .selectize-dropdown');
        if ($dropdown.length === 0 || !$dropdown.is(':visible')) {
          var control = $select[0].selectize;
          if (control) {
            var selected = control.getValue();
            if (selected !== undefined) {
              Shiny.setInputValue(shinyInputName, selected, {priority: 'event'});
            }
          }
        }
      }, 150);
    });
  }

  // Setup for all 3 tabs
  setupSelectizeLive('color_scheme', 'color_scheme_live');
  setupSelectizeLive('color_scheme_prcc', 'color_scheme_live_prcc');
  setupSelectizeLive('color_scheme_sobol', 'color_scheme_live_sobol');

  // --- MANUAL COLORS LIVE ---
  
  $(document).on('input', '#manual_colors', function() {
    Shiny.setInputValue('manual_colors_live', $(this).val(), {priority:'event'});
  });
  $(document).on('input', '#manual_colors_prcc', function() {
    Shiny.setInputValue('manual_colors_live_prcc', $(this).val(), {priority:'event'});
  });
  $(document).on('input', '#manual_colors_sobol', function() {
    Shiny.setInputValue('manual_colors_live_sobol', $(this).val(), {priority:'event'});
  });

  // --- MESSAGE HANDLERS ---

  Shiny.addCustomMessageHandler('force_palette_update', function(msg) {
    if (msg.scheme !== undefined) {
      Shiny.setInputValue('color_scheme_live', msg.scheme, {priority: 'event'});
    }
    if (msg.scheme === 'manual' && msg.manual !== undefined) {
      Shiny.setInputValue('manual_colors_live', msg.manual, {priority: 'event'});
    }
  });

  Shiny.addCustomMessageHandler('force_palette_update_prcc', function(msg) {
    if (msg.scheme_prcc !== undefined) {
      Shiny.setInputValue('color_scheme_live_prcc', msg.scheme_prcc, {priority: 'event'});
    }
    if (msg.scheme_prcc === 'manual_prcc' && msg.manual_prcc !== undefined) {
      Shiny.setInputValue('manual_colors_live_prcc', msg.manual_prcc, {priority: 'event'});
    }
  });

  Shiny.addCustomMessageHandler('force_palette_update_sobol', function(msg) {
    if (msg.scheme_sobol !== undefined) {
      Shiny.setInputValue('color_scheme_live_sobol', msg.scheme_sobol, {priority: 'event'});
    }
    if (msg.scheme_sobol === 'manual_sobol' && msg.manual_sobol !== undefined) {
      Shiny.setInputValue('manual_colors_live_sobol', msg.manual_sobol, {priority: 'event'});
    }
  });

  Shiny.addCustomMessageHandler('toggleButtonStyle', function(msg) {
    var btn = $('#' + msg.id);
    if (btn.length) {
      if (msg.active) {
        btn.removeClass('btn-outline-primary').addClass('btn-primary');
      } else {
        btn.removeClass('btn-primary').addClass('btn-outline-primary');
      }
    }
  });

  // --- OTHER INTERACTORS ---

  $(document).on('changed.bs.select', '#place_selector', function(e, clickedIndex, isSelected, previousValue) {
    var selected = $(this).val();
    if (!selected || selected.length === 0) {
      Shiny.setInputValue('place_selector_empty', Math.random(), {priority: 'event'});
    }
  });

});
