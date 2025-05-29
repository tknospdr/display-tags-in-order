# name: display-tags-in-order
# about: Preserves the order of tags as they were added to a topic
# version: 0.3
# authors: David Muszynski
# url: https://github.com/tknospdr/display-tags-in-order

enabled_site_setting :display_tags_in_order_enabled

after_initialize do
  Rails.logger.info("[display-tags-in-order] Initializing plugin for Discourse #{Discourse::VERSION::STRING}")

  add_to_serializer(:topic_view, :tags) do
    begin
      if object&.topic && ActiveRecord::Base.connection.table_exists?('topic_tags')
        tags = object.topic.tags.joins('LEFT JOIN topic_tags ON topic_tags.tag_id = tags.id AND topic_tags.topic_id = :topic_id', topic_id: object.topic.id)
                              .order('topic_tags.id ASC')
                              .pluck('tags.name')
        Rails.logger.info("[display-tags-in-order] Topic #{object.topic.id}: Tags ordered by topic_tags.id: #{tags.inspect}")
        tags
      else
        Rails.logger.warn("[display-tags-in-order] Topic #{object&.topic&.id || 'nil'}: No topic or topic_tags table missing, returning empty tags")
        []
      end
    rescue StandardError => e
      Rails.logger.error("[display-tags-in-order] Error in topic_view serializer for topic #{object&.topic&.id || 'nil'}: #{e.message}")
      []
    end
  end

  add_to_serializer(:basic_topic, :tags) do
    begin
      if object && ActiveRecord::Base.connection.table_exists?('topic_tags')
        tags = object.tags.joins('LEFT JOIN topic_tags ON topic_tags.tag_id = tags.id AND topic_tags.topic_id = :topic_id', topic_id: object.id)
                         .order('topic_tags.id ASC')
                         .pluck('tags.name')
        Rails.logger.info("[display-tags-in-order] Basic topic #{object.id}: Tags ordered by topic_tags.id: #{tags.inspect}")
        tags
      else
        Rails.logger.warn("[display-tags-in-order] Basic topic #{object&.id || 'nil'}: No topic or topic_tags table missing, returning empty tags")
        []
      end
    rescue StandardError => e
      Rails.logger.error("[display-tags-in-order] Error in basic_topic serializer for topic #{object&.id || 'nil'}: #{e.message}")
      []
    end
  end
end
