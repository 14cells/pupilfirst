setupGraduationCarousel = ->
  $(".graduation-carousel").slick
    slidesToShow: 3
    arrows: true
    centerMode: true
    adaptiveHeight: true
    responsive: [
      {
        breakpoint: 992,
        settings: {
          centerMode: true
          slidesToShow: 3
        }
      },
      {
        breakpoint: 768,
        settings: {
          centerMode: true
          slidesToShow: 1
        }
      }
    ]
    infinite: true

avoidwidowsTypography = ->
  $('h5').each ->
    wordArray = $(this).text().split(' ')
    if wordArray.length > 1
      wordArray[wordArray.length - 2] += '&nbsp;' + wordArray[wordArray.length - 1]
      wordArray.pop()
      $(this).html wordArray.join(' ')

stopVideosOnModalClose = ->
  $('.graduates-video').on 'hide.bs.modal', (event) ->
    modalIframe = $(event.target).find('iframe')
    modalIframe.attr 'src', modalIframe.attr('src')

readmoreFAQ = ->
  $('.read-more').readmore
    speed: 200
    collapsedHeight: 700
    lessLink: '<a class="read-less-link" href="#">Read Less</a>'
    moreLink: '<a class="read-more-link" href="#">Read More</a>'

$(document).on 'page:change', setupGraduationCarousel
$(document).on 'page:change', avoidwidowsTypography
$(document).on 'page:change', stopVideosOnModalClose
$(document).on 'page:change', readmoreFAQ

# !!! NEW STUFF !!!

setupSelect2Inputs = ->
  $('#batch_application_university_id').select2()

toggleReferenceTextField = ->
  if $('#batch_application_team_lead_attributes_reference').val() == 'Other (Please Specify)'
    $('#batch_application_team_lead_attributes_reference_text').parent().parent().parent().removeClass('hidden-xs-up')
  else
    $('#batch_application_team_lead_attributes_reference_text').val('')
    $('#batch_application_team_lead_attributes_reference_text').parent().parent().parent().addClass('hidden-xs-up')

$(document).on 'page:change', ->
  if $('#batch_application_team_lead_attributes_reference').length
    toggleReferenceTextField()
    $('#batch_application_team_lead_attributes_reference').change toggleReferenceTextField

$(document).on 'page:change', setupSelect2Inputs
