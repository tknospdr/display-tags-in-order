# name: force_tag_group_order
# about: Preserves the order of tags as they were added to a topic
# version: 0.3
# authors: David Muszynski
# url: https://github.com/tknospdr/force_tag_group_order

enabled_site_setting :force_tag_group_order_enabled

after_initialize do
  Rails.logger.info("[force-tag-group-order] Initializing plugin for Discourse #{Discourse::VERSION::STRING}")

  # Define site setting as a string
  SiteSetting.define :force_tag_group_order, default: '', type: :string, description: "Comma-separated list of tag group names in display order (e.g., Genus,Species)"

  # Helper to get prioritized tag groups
  module TagGroupOrderHelper
    def ordered_tag_groups
      return [] unless SiteSetting.force_tag_group_order_enabled
      tag_group_names = SiteSetting.force_tag_group_order.split(',').map(&:strip).reject(&:empty?)
      TagGroup.where(name: tag_group_names).sort_by { |tg| tag_group_names.index(tg.name) || Float::INFINITY }
    end
  end

  # Extend serializers
  add_to_serializer(:topic_view, :tags, false) do
    begin
      return [] unless object&.topic && ActiveRecord::Base.connection.table_exists?('topic_tags')

      # Get all tags for the topic
      all_tags = object.topic.tags.joins('LEFT JOIN topic_tags ON topic_tags.tag_id = tags.id AND topic_tags.topic_id = :topic_id', topic_id: object.topic.id)
                                 .order('topic_tags.id ASC')
                                 .pluck('tags.name', 'topic_tags.id')

      # Map tags to their names and topic_tags.id
      tag_map = all_tags.map { |name, tag_id| [name, tag_id] }.to_h

      # Get tag group memberships
      tag_groups = TagGroup.joins(:tags)
                           .where(tags: { name: tag_map.keys })
                           .pluck('tags.name', 'tag_groups.name')
                           .group_by { |tag_name, _| tag_name }
                           .transform_values { |v| v.map { |_, group_name| group_name } }

      # Get prioritized tag groups
      ordered_groups = TagGroupOrderHelper.ordered_tag_groups.map(&:name)

      # Separate tags by priority
      prioritized_tags = []
      other_tags = []

      tag_map.each do |tag_name, tag_id|
        tag_group_names = tag_groups[tag_name] || []
        prioritized_group = ordered_groups.find { |group| tag_group_names.include?(group) }
        if prioritized_group
          prioritized_tags << [tag_name, tag_id, ordered_groups.index(prioritized_group)]
        else
          other_tags << [tag_name, tag_id]
        end
      end

      # Sort prioritized tags by group order, then topic_tags.id
      prioritized_tags.sort_by! { |_, tag_id, group_index| [group_index, tag_id] }
      # Sort other tags alphabetically
      other_tags.sort_by! { |tag_name, _| tag_name.downcase }

      # Combine and return tag names
      result = (prioritized_tags + other_tags).map { |tag_name, _, _| tag_name }
      Rails.logger.info("[force-tag-group-order] Topic #{object.topic.id}: Ordered tags: #{result.inspect}")
      result
    rescue StandardError => e
      Rails.logger.error("[force-tag-group-order] Error in topic_view serializer for topic #{object&.topic&.id || 'nil'}: #{e.message}")
      []
    end
  end

  add_to_serializer(:basic_topic, :tags, false) do
    begin
      return [] unless object && ActiveRecord::Base.connection.table_exists?('topic_tags')

      # Get all tags for the topic
      all_tags = object.tags.joins('LEFT JOIN topic_tags ON topic_tags.tag_id = tags.id AND topic_tags.topic_id = :topic_id', topic_id: object.id)
                           .order('topic_tags.id ASC')
                           .pluck('tags.name', 'topic_tags.id')

      # Map tags to their names and topic_tags.id
      tag_map = all_tags.map { |name, tag_id| [name, tag_id] }.to_h

      # Get tag group memberships
      tag_groups = TagGroup.joins(:tags)
                           .where(tags: { name: tag_map.keys })
                           .pluck('tags.name', 'tag_groups.name')
                           .group_by { |tag_name, _| tag_name }
                           .transform_values { |v| v.map { |_, group_name| group_name } }

      # Get prioritized tag groups
      ordered_groups = TagGroupOrderHelper.ordered_tag_groups.map(&:name)

      # Separate tags by priority
      prioritized_tags = []
      other_tags = []

      tag_map.each do |tag_name, tag_id|
        tag_group_names = tag_groups[tag_name] || []
        prioritized_group = ordered_groups.find { |group| tag_group_names.include?(group) }
        if prioritized_group
          prioritized_tags << [tag_name, tag_id, ordered_groups.index(prioritized_group)]
        else
          other_tags << [tag_name, tag_id]
        end
      end

      # Sort prioritized tags by group order, then topic_tags.id
      prioritized_tags.sort_by! { |_, tag_id, group_index| [group_index, tag_id] }
      # Sort other tags alphabetically
      other_tags.sort_by! { |tag_name, _| tag_name.downcase }

      # Combine and return tag names
      result = (prioritized_tags + other_tags).map { |tag_name, _, _| tag_name }
      Rails.logger.info("[force-tag-group-order] Basic topic #{object.id}: Ordered tags: #{result.inspect}")
      result
    rescue StandardError => e
      Rails.logger.error("[force-tag-group-order] Error in basic_topic serializer for topic #{object&.id || 'nil'}: #{e.message}")
      []
    end
  end
end
