jQuery(function(){
  all = ['wp','tumblr','add-svc']

  $('#add-svc').click(function(){
    for(i=0; i<all.length; i++)
      $('.'+all[i]).hide();
    $('.svc-med').show();
  });

  $('img.svc-med').click(function(e){
    $('#add-svc').hide();
    ee = e;
    kls = $(this).attr('class');
    matches = /svc-med-([a-z]+)/.exec(kls);
    which = matches[1];
    for (i=0; i<all.length; i++){
      hide_this = all[i];
      if (hide_this==which)
        continue;
      $('.'+hide_this).hide();
    }
    $('.'+which).show();
  });
  
  $('.svc-add-cancel').click(function(){
    for(i=0;i<all.length;i++)
      $('.'+all[i]).hide();
    $('#add-svc').show();
  });
  
  $('#wp-upload-btn').click(function(){
    $('#wp-upload-form').submit();
  });


});
