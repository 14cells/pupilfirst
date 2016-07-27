ActiveAdmin.register Payment do
  include DisableIntercom

  menu parent: 'Admissions'
  actions :index, :show, :destroy

  filter :batch_application
  filter :amount
  filter :fees

  index do
    column :batch_application
    column :amount
    column :fees
    column(:status) { |payment| t("payment.status.#{payment.status}") }
    actions
  end

  csv do
    column :application do |payment|
      "Application ##{payment.batch_application.id} to batch #{payment.batch_application.batch.batch_number}"
    end

    column :status do |payment|
      t("payment.status.#{payment.status}")
    end

    column :team_lead do |payment|
      team_lead = payment.batch_application.team_lead
      "#{team_lead.name} (#{team_lead.phone})"
    end

    column :amount

    column('Instamojo Fees', &:fees)
    column :paid_at
    column :created_at
  end
end
