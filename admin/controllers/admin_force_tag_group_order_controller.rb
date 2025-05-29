# frozen_string_literal: true

module Admin
  class ForceTagGroupOrderController < Admin::AdminController
    requires_plugin 'force-tag-group-order'

    def index
      tag_groups = TagGroup.all.pluck(:name, :id).map { |name, id| { name: name, id: id } }
      render_json_dump(tag_groups: tag_groups, selected_order: SiteSetting.force_tag_group_order)
    end

    def update
      new_order = params[:order]
      if new_order.is_a?(Array) && new_order.all? { |name| name.is_a?(String) }
        SiteSetting.force_tag_group_order = new_order
        render json: success_json
      else
        render json: failed_json, status: 400
      end
    end
  end
end
