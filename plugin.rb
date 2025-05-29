# name: display-tags-in-order
# about: Preserves the order of tags as they were added to a topic
# version: 0.1
# authors: David Muszynski
# url: https://github.com/tknospdr/display-tags-in-order

enabled_site_setting :display_tags_in_order_enabled

after_initialize do
  add_to_serializer(:topic_view, :tags) do
    if object&.topic&.tags&.exists?
      object.topic.tags.joins(:topic_tags).order('topic_tags.id').pluck('tags.name')
    else
      []
    end
  end

  add_to_serializer(:basic_topic, :tags) do
    if object&.tags&.exists?
      object.tags.joins(:topic_tags).order('topic_tags.id').pluck('tags.name')
    else
      []
    end
  end
end
