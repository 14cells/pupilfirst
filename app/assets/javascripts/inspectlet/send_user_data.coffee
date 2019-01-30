sendUserDataToInspectlet = ->
  analyticsData = $('#analytics-data')
  state = analyticsData.data('state')

  if __insp? and state?
    __insp.push ['identify', state.email]

    startup = state['startup']

    if startup?
      __insp.push ['tagSession', {
        email: state.email,
        name: state.name,
        startupId: startup['id'],
        productName: startup['product_name']
      }]

$(document).on 'turbolinks:load', sendUserDataToInspectlet
