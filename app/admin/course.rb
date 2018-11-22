ActiveAdmin.register Course do
  controller do
    include DisableIntercom
  end

  menu parent: 'Targets'

  filter :name

  permit_params :name, :sponsored
end
