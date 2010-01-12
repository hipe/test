jQuery(function(){
  all = ['wp','tumblr','add-svc']

  $('#add-svc').click(function(){
    for(i=0; i<all.length; i++)
      $('.'+all[i]).hide();
    $('.svc-med').show();
    $('#cancel-add-svc').show();
    $('#add-svc').hide();
  });

  $('#cancel-add-svc').click(function(){
    $('#add-svc').show();
    $('#cancel-add-svc').hide();
    $('.svc-med').hide();
  });

  $('img.svc-med').click(function(e){
    $('#cancel-add-svc').hide();
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

  $('#tumblr-submit').click(function(){
    $('#tumblr-submit-hack').click();
  });

  $('#awful-hack-accomplice').click(function(){
    $('#awful-hack').trigger('click');
  });

});
