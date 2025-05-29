# frozen_string_literal: true

Discourse::Application.routes.append do
  scope '/admin/plugins/force-tag-group-order', constraints: AdminConstraint.new do
    get '' => 'admin/force_tag_group_order#index'
    put '' => 'admin/force_tag_group_order#update'
  end
end
