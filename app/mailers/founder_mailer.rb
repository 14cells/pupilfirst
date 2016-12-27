class FounderMailer < ApplicationMailer
  def cofounder_addition(cofounder_mail, current_founder)
    @current_founder = current_founder
    mail(to: cofounder_mail, subject: 'SVApp: You have been added as startup cofounder!')
  end

  def incubation_request_submitted(current_founder)
    @current_founder = current_founder
    mail(to: current_founder.email, subject: 'You have successfully submitted your request for incubation at Startup Village.')
  end

  # Mail sent a little while after the a confirmed connect request meeting occured.
  #
  # @param connect_request [ConnectRequest] Request for a meeting which recently occurred.
  def connect_request_feedback(connect_request)
    @connect_request = connect_request
    @faculty = connect_request.faculty
    @founder = connect_request.startup.admin
    mail(to: @founder.email, subject: "Feedback for your recent faculty connect session with faculty member #{@faculty.name}")
  end
end
