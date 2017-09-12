counter = (textBox, helpBlock, maxCharacters) ->
  value = textBox.val()
  characterCount = if value then value.trim().length else 0
  helpBlock.html "#{characterCount}/#{maxCharacters} characters"

updateProductDescription = ->
  helpBlock = $(".startup_product_description p.help-block")
  textBox = $("#startup_product_description")

  # The value of max_chars should match the one in Startup::MAX_PRODUCT_DESCRIPTION_CHARACTERS
  counter(textBox, helpBlock, 150)

$(document).on 'page:change', ->
  $("#startup_product_description").click(updateProductDescription).on('input', updateProductDescription)

  # TODO: v4 of Select2 will replace maximumSelectionSize with maximumSelectionLength, so specifying both for the moment.
  # Remove maximumSelectionSize after confirming upgrade to Select2 > v4.
  $('#startup_startup_categories').select2({ placeholder : 'Select Industries', maximumSelectionLength: 3, maximumSelectionSize: 3 })
