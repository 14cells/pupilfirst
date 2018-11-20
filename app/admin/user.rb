ActiveAdmin.register User do
  menu parent: 'Dashboard'
  actions :index, :show

  filter :email
  filter :founders_id_not_null, label: 'Is a founder', as: :boolean
  filter :faculty_id_not_null, label: 'Is a faculty', as: :boolean
  filter :admin_user_id_not_null, label: 'Is an admin', as: :boolean

  controller do
    include DisableIntercom

    def scoped_collection
      super.includes({ founders: { startup: :school } }, :faculty, :admin_user)
    end
  end

  index do
    selectable_column

    column :email

    column :founder do |user|
      render('founders', user: user) if user.founders.exists?
    end

    column :faculty
    column :admin_user

    actions
  end

  show do
    attributes_table do
      row :email

      row :founders do |user|
        render('founders', user: user) if user.founders.exists?
      end

      row :admin_user
      row :faculty

      row :sign_out_at_next_request do |user|
        if user.sign_out_at_next_request?
          span "User will be signed out (once per week) when he visits. #{link_to 'Turn this off.', toggle_sign_out_at_next_request_admin_user_path, method: :patch}".html_safe
        else
          span "Inactive. #{link_to 'Turn this on', toggle_sign_out_at_next_request_admin_user_path, method: :patch, data: { confirm: 'Are you sure?' }} to sign out the user (once per week) when he visits.".html_safe
        end
      end
    end

    panel 'Technical details' do
      attributes_table_for user do
        row :id
        row :login_token
        row :email_bounced_at
        row :email_bounce_type
      end
    end
  end

  member_action :toggle_sign_out_at_next_request, method: :patch do
    user = User.find(params[:id])
    user.toggle :sign_out_at_next_request
    user.save!
    flash[:success] = "Sign out at next request is now #{user.reload.sign_out_at_next_request ? 'active' : 'inactive'}!"

    redirect_to action: :show
  end

  action_item :impersonate, only: :show, if: proc { can? :impersonate, User } do
    link_to 'Impersonate', impersonate_admin_user_path(user), method: :post
  end

  member_action :impersonate, method: :post do
    user = User.find(params[:id])

    # clear any previous impersonations
    stop_impersonating_user

    if can? :impersonate, User
      if user.admin_user.present?
        flash[:error] = 'You may not impersonate another admin user!'
      else
        impersonate_user(user)
        redirect_to params[:referer] || root_url
        return
      end
    else
      flash[:error] = 'You are not allowed to access that!'
    end

    redirect_to admin_user_path(user)
  end
end
