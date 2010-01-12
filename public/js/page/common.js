window.jQuery(function($){

  var puts = window.console ? window.console.log : function(msg){/*no*/};

  window.Sosy = {
    error: function(msg){
      alert(msg);
    }
  };

  $('a.click-hack').click(function(){
    var current = $(this);
    while (current[0].nodeName != "FORM" && current.parent().size() > 0){
      current = current.parent();
    };
    if (current[0].nodeName !== "FORM") return window.Sosy.error("couldn't find parent form for "+$(this).attr('class'));
    var matches = /\baction-([^ ]+)(?: object-id-(\d+))?/.exec($(this).attr('class'));
    current.find('.hidden-command').attr('value', matches[1]);
    current.find('.hidden-object-id').attr('value', matches[2]); // might set undefined, hidden might not exist
    current.submit();
    return null;
  });

  $('tr.glow-hack').hover(function(){
    $(this).find('td').each(function(){
      var md, coldName, warmName;
      if ((md = /\b(?:([-a-z]+)-)?cold\b/.exec($(this).attr('class')))){
        coldName = md[1] ? (md[1]+'-cold') : 'cold';
        warmName = md[1] ? (md[1]+'-warm') : 'warm';
        $(this).removeClass(coldName);
        $(this).addClass(warmName);
      };
    });
  },
  function(){
    $(this).find('td').each(function(){
      var md, coldName, warmName;
      if ((md = /\b(?:([-a-z]+)-)?warm\b/.exec($(this).attr('class')))){
        coldName = md[1] ? (md[1]+'-cold') : 'cold';
        warmName = md[1] ? (md[1]+'-warm') : 'warm';
        $(this).removeClass(warmName);
        $(this).addClass(coldName);
      }
    });
  });

  $('input.cb-all-hack').click(function(){
    var group = $(this).attr('group');
    var is_checked = $(this).attr('checked');
    $('input[type=checkbox][group='+group+']').each(function(){
      $(this).attr('checked',is_checked);
    });
  });

  $('input.cb-buttons-hack').click(function(){
    var is_checked = $(this).attr('checked');
    var group = $(this).attr('group');
    var aggregates_name = '.aggregates-'+group;
    var num_selected = 0;
    $('input[type=checkbox][group='+group+']').each(function(){
      if ('on' != $(this).attr('value')) { // skip the top cb
        if ($(this).attr('checked')) {
          num_selected ++;
        }
      }
    });
    $('#num-selected-'+group).html(num_selected);
    if (is_checked){
      $(aggregates_name).show();
    } else {
      if (num_selected == 0) { $(aggregates_name).hide(); }
    }
  });
});
