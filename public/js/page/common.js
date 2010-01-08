jQuery(function(){
  
  Sosy = {
    error: function(msg){
      alert(msg);
    }
  };
  
  $('a.click-hack').click(function(){
    current = $(this)
    while (current[0].nodeName != "FORM" && current.parent().size() > 0){
      current = current.parent()
    }
    if (current[0].nodeName !== "FORM") return Sosy.error("couldn't find parent form for "+$(this).attr('class'))
    var matches = /\baction-([^ ]+)(?: object-id-(\d+))?/.exec($(this).attr('class'))
    current.find('.hidden-command').attr('value', matches[1])
    current.find('.hidden-object-id').attr('value', matches[2]) // might set undefined
    current[0].submit();
  });
 
  $('tr.glow-hack').hover(function(){
    $(this).find('td').each(function(){
      if (md = /\b([-a-z]+)-cold\b/.exec($(this).attr('class'))){
        $(this).removeClass(md[1]+'-cold')
        $(this).addClass(md[1]+'-warm')        
      }
    });
  },
  function(){
    $(this).find('td').each(function(){
      if (md = /\b([-a-z]+)-warm\b/.exec($(this).attr('class'))){
        $(this).removeClass(md[1]+'-warm')
        $(this).addClass(md[1]+'-cold')        
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
    aggregates_name = '.aggregates-'+group
    var num_selected = 0
    $('input[type=checkbox][group='+group+']').each(function(){
      if ('on' != $(this).attr('value')) { // skip the top cb
        if ($(this).attr('checked')) {
          num_selected ++;
        }        
      }
    });    
    $('#num-selected-'+group).html(num_selected)
    if (is_checked){
      $(aggregates_name).show();
    } else {
      if (num_selected == 0) { $(aggregates_name).hide(); }
    }
  }); 
});